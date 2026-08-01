# Cluster Kubernetes de Homologação

Cluster k8s rodando em Proxmox (1 host físico), gerenciado 100% via código (Terraform + Ansible + GitOps).

## Arquitetura

```
                    ┌─────────────────────────────────────┐
                    │  Proxmox 177.91.64.37 (64GB RAM)    │
                    │  vmbr0 (bridge única, sem VLAN)     │
                    └────────────────┬────────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
   ┌────▼─────┐               ┌──────▼──────┐              ┌──────▼──────┐
   │  nat-gw  │               │  k8s-cp1/2/3│              │   k8s-w1    │
   │ 10.0.0.1 │◄──────────────┤ 10.0.0.201..3│              │ 10.0.0.211  │
   │.66.34    │               │  control     │              │  worker     │
   └────┬─────┘               │  planes      │              └──────┬──────┘
        │                     └──────────────┘                     │
        │ Internet (NAT)                                          │
        ▼                                                         ▼
   Zabbix Server, Postgres, Grafana, Prometheus, etc.
```

**Topologia**: 5 VMs (1 NAT Gateway + 3 Control Planes + 1 Worker)
**Recursos totais**: 20 vCPU, 48 GB RAM, 340 GB disco
**Stack**: Cilium (CNI) + MetalLB (LB) + ArgoCD (GitOps) + ExternalDNS + cert-manager (TLS)

## Estrutura do repositório

```
k8s-homolog/
├── docs/adr/                Architecture Decision Records
├── terraform/proxmox/       IaC das VMs no Proxmox
├── ansible/                 Bootstrap do cluster k8s
└── .github/workflows/       CI para Terraform e Ansible
```

## Como subir o ambiente

### Pré-requisitos
- Proxmox 8.x acessível via API
- Terraform >= 1.6
- Ansible >= 8.0
- 5 IPs públicos disponíveis (1 para nat-gw, demais para LoadBalancer)

### Passo a passo

```bash
# 1. Provisionar VMs
cd terraform/proxmox/environments/homolog
cp terraform.tfvars.example terraform.tfvars
# editar com seus dados
terraform init
terraform apply

# 2. Configurar NAT gateway
cd ../../../../
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/02-nat-gateway.yml

# 3. Bootstrap do cluster k8s
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/01-bootstrap.yml
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/03-cp-init.yml
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/04-cp-join.yml
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/05-worker-join.yml
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/06-cilium.yml

# 4. Validar
kubectl get nodes
```

## Redes

| Tipo         | Faixa                  | Gateway         | Uso                                    |
|--------------|------------------------|-----------------|----------------------------------------|
| Privada      | 10.0.0.0/24            | 10.0.0.1        | VMs do cluster                         |
| Pública 1    | 177.91.66.32/29        | 177.91.66.33    | nat-gw + LoadBalancer (MetalLB)        |
| Pública 2    | 177.91.65.32/29        | 177.91.65.33    | Standby (LoadBalancer备用)            |
| Pod (Cilium) | 10.244.0.0/16          | n/a             | Comunicação entre Pods                 |
| Service      | 10.96.0.0/12           | n/a             | ClusterIPs internos                    |

## Decisões arquiteturais

Ver [docs/adr/](docs/adr/) para detalhes completos.

- [ADR 0001](docs/adr/0001-stack-escolhida.md) - Stack escolhida
- [ADR 0002](docs/adr/0002-topologia-rede-nat.md) - Topologia de rede e NAT
- [ADR 0003](docs/adr/0003-elasticidade-metallb.md) - Elasticidade via MetalLB

## Status atual

- [x] Sprint 0 - Estrutura do repositório
- [ ] Sprint 1 - Terraform provisiona 5 VMs
- [ ] Sprint 2 - NAT gateway funcional
- [ ] Sprint 3 - Cluster k8s com 3 CPs + 1 worker
- [ ] Sprint 4 - Stack base (ArgoCD, Ingress, MetalLB, cert-manager, ExternalDNS)
- [ ] Sprint 5 - Zabbix + Postgres
- [ ] Sprint 6 - Grafana + Prometheus
- [ ] Sprint 7 - GitOps completo

## Contribuindo

Este é um ambiente de homologação/lab. Toda mudança passa por:
1. Branch feature
2. Commit com mensagem descritiva
3. Push + Pull Request
4. Self-review (mesmo sendo solo)
5. Merge na main
