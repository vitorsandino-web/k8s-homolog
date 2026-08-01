# AGENT.md — Runbook de Execução Autônoma (Proxmox → K8s Homolog)

Este documento define como um agente de IA deve operar para provisionar e
configurar o cluster descrito neste repositório, de ponta a ponta.

## 1. Objetivo

Levar o ambiente do estado zero (Proxmox vazio) até o cluster funcional
descrito nos ADRs (`docs/adr/`), executando os Sprints 1–7 do README de
forma sequencial, idempotente e auditável.

## 2. Escopo de autonomia

### 2.1 O agente PODE sozinho:
- Leitura de estado (terraform plan, kubectl get, ansible --check, ping, curl)
- `terraform plan`, `terraform validate`, `ansible-playbook --check --diff`
- Criação/edição de arquivos no repositório
- Criar e destruir VMs de teste efêmeras na faixa 900–909

### 2.2 O agente NÃO PODE sem HUMAN GATE:
- `terraform destroy` ou `terraform apply` que remova/recrie recursos
  existentes fora da faixa de teste
- Qualquer comando que apague dados
- Alterações em firewall/NAT do `nat-gw` (risco de lockout)
- Rotação/revogação de credenciais
- Mudança de `main` sem PR

## 3. Credenciais e segredos

- **Nunca** escrever tokens, senhas, chaves privadas em texto plano
- **Nunca** digitar senha em comando de shell
- VMs do cluster: cloud-init injeta chave SSH, senha desabilitada
- Fonte de segredos: variáveis de ambiente ou Ansible Vault
- `.gitignore` cobre `*.tfvars`, `*.pem`, `id_rsa*`, `kubeconfig*`, `.env`

## 4. Pré-condições

- API Proxmox acessível
- Terraform >= 1.6
- Ansible >= 8.0
- Provider `bpg/proxmox` configurado
- Conectividade SSH às VMs (quando existirem)
- Template VM 9000 é template (`template: 1`)
- Sem locks de storage pendentes

## 5. Modelo de acesso

O agente roda de fora. Único ponto alcançável é o IP público do `nat-gw`
(`177.91.66.34`). Todas as demais VMs são acessadas via ProxyJump.

## 6. Ordem de execução (Fases 0–7)

Cada fase: plan → check → apply → validar → registrar.

- **Fase 0**: Sanidade
- **Fase 1**: `nat-gw` (PRIMEIRO) — ver `docs/NAT-GATEWAY.md`
- **Fase 2**: CPs + worker (via bastion)
- **Fase 3**: Bootstrap cluster (kubeadm, Cilium)
- **Fase 4**: Stack base (MetalLB, ArgoCD, Ingress, cert-manager, ExternalDNS)
- **Fase 5–6**: Zabbix + Grafana
- **Fase 7**: GitOps completo

## 7. Operação segura Proxmox

### 7.1 Template (VM 9000) pronto
- `template: 1`
- `qemu-guest-agent` pré-instalado (idealmente)
- Sem `package_upgrade: true` no cloud-init (atrasa boot)

### 7.2 VMIDs — faixa 900–909 exclusiva para teste
- Nunca reusar IDs do cluster (200-203, 211) para teste
- VMs de teste destruídas antes do fim da fase

### 7.3 Locks de storage
Procedimento seguro:
```bash
qm status <id>
ps aux | grep "kvm -id <id>"
qm unlock <id>
pkill -9 -f "kvm -id <id>"
rm -f /var/lock/qemu-server/lock-<id>.conf
qm destroy <id> --purge
```

### 7.4 Polling, não `sleep` fixo
```bash
timeout=180; interval=5; elapsed=0
until ssh -o ConnectTimeout=3 -o BatchMode=yes ubuntu@<ip> 'echo ok' 2>/dev/null; do
  sleep "$interval"; elapsed=$((elapsed+interval))
  [ "$elapsed" -ge "$timeout" ] && exit 1
done
```

## 8. Validação contínua

```bash
kubectl get nodes -o wide
kubectl get pods -A --field-selector=status.phase!=Running
```

## 9. Rastreabilidade

Toda mudança = commit próprio, mensagem descritiva, referência à sprint.

## 10. Erros

- Parar a fase atual, capturar output
- Rollback = HUMAN GATE (exceto VMs de teste 900–909)
- Documentar incidente em `docs/adr/` se mudar decisão arquitetural

## 11. Fora de escopo

- DNS fora de `k8s.version2.com.br`
- Rede do Proxmox host
- Remover ProxyJump sem alternativa
