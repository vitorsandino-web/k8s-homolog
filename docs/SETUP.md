# SETUP — Deploy Completo do Cluster k8s-homolog

Este documento é o passo-a-passo único pra colocar o cluster inteiro de pé,
do zero, em qualquer Proxmox. Foi feito pra ser:

- **Repetível**: rodar de novo dá o mesmo resultado
- **Auditável**: cada passo deixa rastro no Git
- **Didático**: explica o "porquê" de cada escolha

## Topologia Final

```
                    Proxmox — vmbr0 (bridge única, sem VLAN, sem tag)
                                      │
        ┌─────────────────────────────┴─────────────────────────────┐
        │                                                            │
   net0 (privada)                                              net1 (pública)
   10.0.0.1/24                                                 177.91.66.34/29
   sem gateway                                                 gateway 177.91.66.33
        │                                                            │
        └──────────────────────  VM nat-gw  ─────────────────────────┘
                          (VM 200, manual, 1 GB RAM, 8 GB disco)
                          (bastion SSH + NAT/MASQUERADE)
                                      │
                   ┌──────────────────┼──────────────────┐
                   │                  │                   │
             k8s-cp1 .201       k8s-cp2 .202        k8s-cp3 .203
             (8 GB RAM, 50 GB disco, Terraform)
                   │                  │                   │
                   └──────────┬───────┴───────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
            k8s-w1 .211                k8s-w2 .212
            (12 GB RAM, 80 GB disco,    (12 GB RAM, 80 GB disco,
             Terraform)                  Terraform, redundância)
```

**Recursos totais**: 17 vCPU, 49 GB RAM, 360 GB disco (5 VMs cluster + 1 nat-gw).

**VMIDs reservados** (não usar pra teste):
- `200` — nat-gw
- `201-203` — control planes
- `211-212` — workers
- `900-909` — exclusivos pra testes/VMs descartáveis
- `9000` — template cloud-init Ubuntu 22.04

## 1. Pré-requisitos

### No Proxmox

- Proxmox VE 8.x acessível via API (porta 8006)
- Token de API com permissão totais (criar/destruir VM)
- Storage `local-lvm` (LVM thin) com ~400 GB livres
- Bridge `vmbr0` (sem VLAN) — único requisito
- Imagem cloud Ubuntu 22.04 disponível em `/var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img`

### No seu desktop/WSL (onde vai rodar Terraform/Ansible)

```bash
sudo apt update
sudo apt install -y terraform ansible git sshpass
# Ou via snap:
sudo snap install terraform --classic

terraform version    # >= 1.6
ansible --version    # >= 2.10
```

## 2. Setup Inicial (uma vez só)

### 2.1 Chave SSH do agente

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_k8s -N "" -C "k8s-homolog-agent"
cat ~/.ssh/id_ed25519_k8s.pub
# saída: ssh-ed25519 AAAA... k8s-homolog-agent
```

### 2.2 Template VM 9000 no Proxmox (uma vez, via SSH no Proxmox)

```bash
ssh root@IP_DO_PROXMOX << 'EOF'
set -e
# Cria VM a partir da imagem cloud
qm create 9000 --name ubuntu-2204-cloudinit --memory 2048 --cores 2 \
  --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-single --ostype l26

# Importa a imagem cloud como disco
qm importdisk 9000 /var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img local-lvm -format qcow2

# Configura disco, boot, cloud-init
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0,discard=on,iothread=1
qm set 9000 --boot order=scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent 1

# Marca como template
qm template 9000
EOF

# Verifica
qm list | grep 9000
# Esperado: VM 9000 como template, 2 GB disco
```

### 2.3 Clonar o repositório

```bash
git clone https://github.com/vitorsandino-web/k8s-homolog.git
cd k8s-homolog
```

### 2.4 Configurar variáveis sensíveis (sem commitar)

```bash
# Token de API do Proxmox (formato: root@pam!terraform-token=...)
export TF_VAR_proxmox_api_token="SEU_TOKEN_AQUI"

# Senha padronizada para todas as VMs (user homolog)
export TF_VAR_default_password="Homolog@2026!"
```

Dica: coloque num arquivo `.env` local (não commitar) e rode `source .env` antes de cada sessão.

### 2.5 Configurar SSH config pra ProxyJump via bastion

```bash
cat >> ~/.ssh/config << 'EOF'

Host 10.0.0.*
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519_k8s
    StrictHostKeyChecking accept-new
    ProxyCommand ssh -i ~/.ssh/id_ed25519_k8s -o StrictHostKeyChecking=accept-new -W %h:%p ubuntu@177.91.66.34
EOF
```

## 3. Provisionar o nat-gateway (VM 200)

**Por que não está no Terraform?** O Terraform detecta "drift" (mudança no disco expandido manualmente) e recria a VM, o que destrói a conectividade das demais VMs. Por isso o nat-gw é provisionado uma vez via Ansible.

```bash
# Provisionar nat-gw (cria a VM 200, configura rede, expande disco)
ansible-playbook ansible/playbooks/provision-nat-gw.yml
```

Aguardar SSH ficar disponível:

```bash
timeout=180; elapsed=0
until ssh -i ~/.ssh/id_ed25519_k8s -o StrictHostKeyChecking=accept-new ubuntu@177.91.66.34 'echo ok' 2>/dev/null; do
  sleep 5; elapsed=$((elapsed+5))
  [ $elapsed -ge $timeout ] && { echo "Timeout"; exit 1; }
done
echo "nat-gw OK em ${elapsed}s"
```

Expandir o filesystem (o disco foi expandido, partição ainda é pequena):

```bash
ssh ubuntu@177.91.66.34 'printf "d\n1\nn\n1\n\n\nw\ny\n" | sudo fdisk /dev/sda && sudo resize2fs /dev/sda1 && df -h /'
```

Configurar NAT/MASQUERADE (iptables):

```bash
ANSIBLE_STDOUT_CALLBACK=default ansible-playbook \
  -i ansible/inventory/hosts.ini.real -l nat_gw \
  ansible/playbooks/02-nat-gateway.yml
```

Validar:

```bash
ssh ubuntu@177.91.66.34 'sysctl net.ipv4.ip_forward; sudo iptables -t nat -L POSTROUTING -n; ping -c1 1.1.1.1'
```

## 4. Provisionar cluster Kubernetes (5 VMs)

```bash
cd terraform/proxmox/environments/homolog

terraform init
terraform validate
terraform plan -out=tfplan-cluster
terraform apply -parallelism=1 tfplan-cluster
```

**Atenção**: linked clone puro = disco de 2.2 GB (template). Após apply, expandir via playbook.

## 5. Expandir discos do cluster

```bash
ANSIBLE_STDOUT_CALLBACK=default ansible-playbook \
  -i ansible/inventory/hosts.ini.real \
  ansible/playbooks/expand-disks.yml
```

Este playbook:
1. Detecta tamanho atual do disco em cada VM
2. Compara com alvo (50 GB CP, 80 GB workers)
3. **Pausa** e instrui você a rodar `qm disk resize` no Proxmox
4. Após expansão, expande partição + filesystem via fdisk/resize2fs

**Workflow manual do passo 3**:
```bash
# No Proxmox, pra cada VM:
qm shutdown 201 --timeout 30
qm disk resize 201 scsi0 +48G  # 50 - 2 = +48G
qm start 201
# Repetir pra 202, 203 (alvo 50G) e 211, 212 (alvo 80G, +78G)
```

Depois rode o playbook de novo — ele detecta os tamanhos e finaliza expansão de partição/filesystem.

## 6. Validar acesso ao cluster via bastion

```bash
ANSIBLE_STDOUT_CALLBACK=default ansible all -i ansible/inventory/hosts.ini.real -m ping
# Esperado: 6 hosts respondem "pong" (nat-gw + 3 CPs + 2 workers)
```

## 7. Bootstrap do cluster Kubernetes

Os playbooks 03-cp-init, 04-cp-join, 05-worker-join e 06-cilium ainda são
placeholders. A próxima sprint implementa o bootstrap completo via `kubeadm`.

## 8. Limpeza (HUMAN GATE)

```bash
# Destrói apenas as VMs do Terraform (5 cluster VMs)
cd terraform/proxmox/environments/homolog
terraform destroy

# nat-gw é manual — destruir via Proxmox UI ou:
qm shutdown 200
qm destroy 200 --purge
```

⚠️ VMs de produção (100-103) **não são tocadas**.

## Próximas sprints

Ver `README.md` (seção "Status atual") para o roadmap completo.

Documentos de referência:
- `docs/AGENT.md` — comportamento do agente de IA
- `docs/NAT-GATEWAY.md` — topologia e bring-up do nat-gw
- `docs/security.md` — política de secrets
