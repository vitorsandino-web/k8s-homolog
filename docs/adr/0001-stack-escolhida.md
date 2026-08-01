# ADR 0001: Stack do Cluster Kubernetes

## Status
Aceito (2026-08-01)

## Contexto
Necessidade de cluster Kubernetes para homologação em ambiente single-host Proxmox, com gestão 100% versionada em Git e foco em aprendizado de GitOps + IaC.

## Decisão

### Hipervisor
- **Proxmox VE 8.x** (já existente no ambiente)
- 1 host físico com 64 GB RAM
- Sem vLAN (bridge vmbr0 única)

### Infraestrutura como Código
- **Terraform 1.6+** com provider `bpg/proxmox` para provisionamento das VMs
- **Ansible 8+** para bootstrap do cluster (kubeadm, packages, sysctl)
- State local por enquanto (evoluir para S3/MinIO depois)

### Bootstrap Kubernetes
- **kubeadm** (padrão upstream, didático)
- 3 control planes (HA de etcd) + 1 worker
- Versão: 1.30.x

### CNI (Container Network Interface)
- **Cilium** com eBPF (substitui kube-proxy)
- Dataplane moderno, observabilidade nativa

### Storage
- **local-path-provisioner** da Rancher
- StorageClass padrão para PVCs dinâmicos
- Sem Ceph (não faz sentido com 1 host Proxmox)

### Load Balancer
- **MetalLB em modo L2** (sem necessidade de roteador BGP)
- 2 pools: interno (10.0.0.230-240) e público (177.91.66.34-38)

### GitOps
- **ArgoCD** para sincronização de aplicações
- App-of-apps pattern
- Repo: este repositório

### Ingress
- **Nginx Ingress Controller** (2 réplicas via HPA)
- cert-manager com Let's Encrypt (DNS-01 via Cloudflare)

### DNS Automático
- **ExternalDNS** com provider Cloudflare
- Domínio: *.k8s.version2.com.br

## Consequências

### Positivas
- Tudo versionado, reproduzível e auditável
- Path claro para evolução (multi-host, Ceph, etc.)
- Aprendizado real de GitOps, Terraform, Ansible
- HA de control plane mesmo em 1 host físico (etcd tolera 1 CP down)

### Negativas
- Sem HA de infraestrutura (host Proxmox é SPOF)
- Sem replicação de storage (perda do host = perda de dados)
- Aceitável para homologação, não para produção

### Riscos
- Recursos limitados: 1 worker com 12 GB RAM precisa hospedar Zabbix + Postgres + Grafana + Prometheus
- Mitigação: monitorar uso de recursos, ajustar réplicas se necessário

## Alternativas Consideradas

### k3s em vez de kubeadm
- Prós: mais simples, binário único
- Contras: menos didático, abstrai conceitos importantes
- Decisão: kubeadm para aprender conceitos fundamentais

### Calico em vez de Cilium
- Prós: mais maduro, documentação ampla
- Contras: não usa eBPF, sem observabilidade nativa
- Decisão: Cilium para aprender tecnologia moderna

### Traefik em vez de Nginx
- Prós: configuração via CRDs
- Contras: curva de aprendizado diferente
- Decisão: Nginx (mais tradicional, mais recursos na internet)
