# Cluster Kubernetes de Homologação

Cluster k8s rodando em Proxmox (1 host físico), gerenciado via Terraform + Ansible + GitOps.

## Topologia Final

| VM | IP | Recursos | Função | Provisionamento |
|----|----|---------| -------| -----------------|
| `nat-gw` (200) | 10.0.0.1 / 177.91.66.34 | 1 GB RAM, 8 GB disco | Bastion SSH + NAT/MASQUERADE | Ansible (manual) |
| `k8s-cp1` (201) | 10.0.0.201 | 8 GB RAM, 50 GB disco | Control plane | Terraform |
| `k8s-cp2` (202) | 10.0.0.202 | 8 GB RAM, 50 GB disco | Control plane | Terraform |
| `k8s-cp3` (203) | 10.0.0.203 | 8 GB RAM, 50 GB disco | Control plane | Terraform |
| `k8s-w1` (211) | 10.0.0.211 | 12 GB RAM, 80 GB disco | Worker (workloads) | Terraform |
| `k8s-w2` (212) | 10.0.0.212 | 12 GB RAM, 80 GB disco | Worker (redundância) | Terraform |

**Total**: 17 vCPU, 49 GB RAM, 360 GB disco.

**Por que nat-gw é provisionado via Ansible e não Terraform?**
O Terraform detecta "drift" no disco quando você expande manualmente (nat-gw precisa de +6 GB depois do template), recria a VM e quebra a conectividade do cluster. Por isso nat-gw é gerenciado via Ansible/playbooks provision-nat-gw.yml + 02-nat-gateway.yml, fora do state do Terraform.

## Quick Start

```bash
# Setup (uma vez)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_k8s -N ""
export TF_VAR_proxmox_api_token="..."
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519_k8s.pub)"
export TF_VAR_default_password="Homolog@2026!"

# Provisionar nat-gateway
ansible-playbook ansible/playbooks/provision-nat-gw.yml

# Provisionar cluster
cd terraform/proxmox/environments/homolog
terraform init && terraform apply

# Expandir discos
ansible-playbook ansible/playbooks/expand-disks.yml
```

Ver `docs/SETUP.md` para o passo-a-passo completo.

## Estrutura do repositório

```
k8s-homolog/
├── README.md                    # Este arquivo
├── docs/
│   ├── SETUP.md                 # Quick start + topologia
│   ├── AGENT.md                 # Runbook do agente IA
│   ├── NAT-GATEWAY.md           # Detalhes do nat-gw
│   ├── security.md              # Política de secrets
│   └── adr/                     # Architecture Decision Records
├── terraform/
│   └── proxmox/
│       ├── modules/k8s-node/    # Módulo VM do cluster
│       └── environments/homolog/
│           ├── instances.tf     # 5 VMs (CPs + workers)
│           ├── variables.tf
│           ├── outputs.tf
│           └── terraform.tfvars.example
├── ansible/
│   ├── inventory/
│   ├── playbooks/
│   │   ├── provision-nat-gw.yml # Cria nat-gw via API Proxmox
│   │   ├── 02-nat-gateway.yml   # Configura NAT/iptables
│   │   ├── expand-disks.yml     # Expande discos do cluster
│   │   └── 03-cp-init.yml ...   # Bootstrap k8s (próxima sprint)
│   └── roles/
└── .github/workflows/           # CI para Terraform e Ansible
```

## Status atual

- [x] Sprint 0 - Estrutura do repositório
- [x] Sprint 1 - Terraform provisiona 5 VMs (cluster)
- [x] Sprint 2 - nat-gw provisionado manualmente + NAT funcional
- [ ] Sprint 3 - Bootstrap cluster Kubernetes (kubeadm, Cilium)
- [ ] Sprint 4 - Stack base (ArgoCD, Ingress, MetalLB, cert-manager)
- [ ] Sprint 5-7 - Zabbix + Grafana + GitOps completo

## Contribuindo

1. Crie branch: `git checkout -b feat/minha-mudanca`
2. Commit: `git commit -m "feat: ..."`
3. Push: `git push origin feat/minha-mudanca`
4. Abra PR no GitHub
5. Auto-review (mesmo em projeto solo): revise o diff antes de merge
6. Merge pra `main`
