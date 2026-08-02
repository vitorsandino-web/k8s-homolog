# Cluster Kubernetes de Homologação

Cluster k8s rodando em Proxmox (1 host físico), gerenciado via Terraform + Ansible + Git.

## Stack

- **Proxmox VE 8.x** (1 host, 128 GB RAM, ~390 GB local-lvm livres)
- **kubeadm + Cilium CNI** (próxima sprint)
- **3 control planes + 2 workers** (HA + redundância de workloads)
- **nat-gateway** provisionado uma vez via Proxmox (não-virtualization Terraform drift)
- **Autenticação**: user `homolog` + senha `Homolog@2026!` (lab/padrão)
- **GitOps**: Terraform + Ansible versionados, deploy reproduzível

## Topologia

| VM    | IP            | Recursos        | Função         | Provisionamento    |
|-------|--------------|-----------------|----------------|-------------------|
| 200   | 10.0.0.1 + 177.91.66.34 | 1 GB, 8 GB disco | NAT + bastion  | Ansible (manual)  |
| 201-203 | 10.0.0.201-203/24 | 8 GB, 50 GB disco | control plane  | Terraform         |
| 211-212 | 10.0.0.211-212/24 | 12 GB, 80 GB disco | worker         | Terraform         |

Recursos totais: 49 GB RAM, ~360 GB disco.

## Repositório

- **Terraform**: `terraform/proxmox/environments/homolog/` (5 VMs cluster)
- **Ansible**: `ansible/playbooks/` (nat-gw, expand-disks)
- **Docs**: `docs/SETUP.md` (quick start), `docs/adr/` (decisões)

## Como subir do zero

Ver [`docs/SETUP.md`](docs/SETUP.md) — guia completo.

TL;DR:
1. Recriar template VM 9000 com user `homolog` + senha `Homolog@2026!`
2. `export TF_VAR_proxmox_api_token="..." TF_VAR_default_password="..."`
3. Provisionar nat-gw: `ansible-playbook provision-nat-gw.yml`
4. Criar cluster: `cd terraform/.../homolog && terraform apply`
5. Expandir discos: `ansible-playbook expand-disks.yml`

## Status

- [x] Proxmox template com user + senha
- [x] NAT-gateway funcional (SSH via senha)
- [ ] Cluster k8s (próxima sprint)
- [ ] Zabbix + Grafana
