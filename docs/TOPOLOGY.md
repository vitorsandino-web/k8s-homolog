# Topologia do Cluster k8s-homolog

## Diagrama lógico

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Proxmox (177.91.64.37)                          │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                     bridge vmbr0 (10.0.0.0/24 + 177.91.66.32/29)        │ │
│  └──┬──────────────────────────────────────────────────────────────────┬──┘ │
│     │                                                                │     │
│  ┌──┴────────────────────┐                              ┌───────────┴──┐  │
│  │  NAT-Gateway (VM 200) │                              │ Cluster VMs  │  │
│  │  ─────────────────────│                              │ (10.0.0.x)  │  │
│  │  eth0: 10.0.0.1/24    │                              │              │  │
│  │  eth1: 177.91.66.34/29│ ← IP público homolog        │   201 cp1    │  │
│  │                       │                              │   202 cp2    │  │
│  │  IP Forward & MASQ    │                              │   203 cp3    │  │
│  │  DNAT 80/443 → 10.0.0.201:80/443                    │   211 w1     │  │
│  └───────────────────────┘                              │   212 w2     │  │
│                                                          └──────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Rede

| Faixa | Gateway | Dispositivos |
|---|---|---|
| `10.0.0.0/24` | nat-gw (10.0.0.1) | nat-gw, k8s-cp1/2/3, k8s-w1/2 |
| `177.91.66.32/29` | provedor (177.91.66.33) | nat-gw (177.91.66.34) |
| `177.91.64.0/24` | provedor | Proxmox (177.91.64.37) |

## VMs

| VMID | Hostname | IP interno | IP externo | vCPU | RAM | Disco |
|---|---|---|---|---|---|---|
| 100 | Origin | — | — | 16 | 16 GB | 100 GB |
| 101 | Edge | — | — | 12 | 12 GB | 100 GB |
| 102 | VOD | — | — | 4 | 4 GB | 100 GB |
| 103 | NUV | — | — | 32 | 32 GB | 272 GB |
| 200 | nat-gw | 10.0.0.1 | 177.91.66.34 | 4 | 1 GB | 8 GB |
| 201 | k8s-cp1 | 10.0.0.201 | — | 4 | 8 GB | 158 GB |
| 202 | k8s-cp2 | 10.0.0.202 | — | 4 | 8 GB | 158 GB |
| 203 | k8s-cp3 | 10.0.0.203 | — | 4 | 8 GB | 158 GB |
| 211 | k8s-w1 | 10.0.0.211 | — | 4 | 12 GB | 158 GB |
| 212 | k8s-w2 | 10.0.0.212 | — | 4 | 12 GB | 158 GB |
| 9000 | template | — | — | 2 | 2 GB | 2 GB |

## Kubernetes

- **Versão**: v1.29.15
- **CNI**: Flannel (substituiu Cilium)
- **Service Mesh**: — (não instalado)
- **DNS**: CoreDNS (3 replicas)
- **Storage Class**: local-path (default)
- **MetalLB**: 0.14.8 (L2 Advertisement, só funciona para CPs)
- **Ingress**: nginx-ingress 4.15.1 (Deployment + hostNetwork em k8s-cp1)

## Acesso SSH

```bash
# Bastion (nat-gw) — homolog/Homolog@2026!
ssh homolog@177.91.66.34

# Host VMs (via bastion via ProxyCommand)
ssh homolog@10.0.0.201  # usa ~/.ssh/config automaticamente
```

## Acesso Web (via nat-gw)

| Serviço | URL | Host Header |
|---|---|---|
| Grafana | http://177.91.66.34 | `grafana.k8s.homolog` |
| Zabbix | http://177.91.66.34 | `zabbix.k8s.homolog` |

**Nota**: hosts `grafana.k8s.homolog` e `zabbix.k8s.homolog` **não são DNS públicos** — você precisa adicionar manualmente no `/etc/hosts` para o seu navegador:

```
177.91.66.34  grafana.k8s.homolog
177.91.66.34  zabbix.k8s.homolog
```
