# ADR 0002: Topologia de Rede e NAT Gateway

## Status
Aceito (2026-08-01)

## Contexto
VMs do cluster precisam acessar internet (apt update, pull de imagens Docker, Git clone, API Cloudflare), mas rede privada 10.0.0.0/24 está isolada. Adicionalmente, serviços expostos ao público precisam de IPs públicos roteáveis.

## Decisão

### Topologia de Rede

| Tipo         | Faixa                  | Gateway         | Uso                                    |
|--------------|------------------------|-----------------|----------------------------------------|
| Privada      | 10.0.0.0/24            | 10.0.0.1        | VMs do cluster (nat-gw faz gateway)   |
| Pública 1    | 177.91.66.32/29        | 177.91.66.33    | nat-gw + LoadBalancer principal        |
| Pública 2    | 177.91.65.32/29        | 177.91.65.33    | Standby                                |
| Pod (Cilium) | 10.244.0.0/16          | n/a             | Comunicação entre Pods                 |
| Service      | 10.96.0.0/12           | n/a             | ClusterIPs internos                    |

### NAT Gateway (VM dedicada)

VM `nat-gw` com 2 interfaces:
- **Interface privada (ens18)**: 10.0.0.1/24
- **Interface pública (ens19)**: 177.91.66.34/29, gateway 177.91.66.33

#### Regras
```
# Habilita IP forwarding
sysctl -w net.ipv4.ip_forward=1

# MASQUERADE (SNAT) para saída
iptables -t nat -A POSTROUTING -o ens19 -j MASQUERADE

# FORWARD chain
iptables -A FORWARD -i ens18 -o ens19 -j ACCEPT
iptables -A FORWARD -i ens19 -o ens18 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

#### Recursos da VM
- 4 vCPU, 1 GB RAM, 20 GB disco
- Ubuntu 22.04 LTS
- Pacotes: iptables-persistent, dnsmasq (opcional como DNS cache)

### Roteamento

Todas as VMs do cluster (CPs + worker) configuradas via cloud-init:
```
# /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  ethernets:
    ens18:
      addresses:
        - 10.0.0.201/24
      routes:
        - to: default
          via: 10.0.0.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```

### Fluxo de Tráfego

#### Saída (VM → Internet)
```
Pod (10.244.x.x)
  → Cilium MASQUERADE (SNAT para IP do host)
  → VM k8s-cp1 (10.0.0.201)
  → Default route via 10.0.0.1
  → nat-gw (10.0.0.1) faz MASQUERADE → 177.91.66.34
  → Switch → Roteador externo → Internet
```

#### Entrada (Internet → Serviço)
```
Usuário → https://grafana.k8s.version2.com.br
  → DNS resolve para 177.91.66.35 (MetalLB)
  → Roteador externo → switch → Proxmox vmbr0
  → IP 177.91.66.35 chega direto no node que tem o Pod ingress
  → Nginx Ingress → Service → Pod Grafana
```

## Consequências

### Positivas
- VMs internas isoladas, sem exposição direta à internet
- Controle granular de saída via nat-gw
- Logs centralizados de tráfego no nat-gw
- nat-gw pode evoluir para firewall completo (nftables, fail2ban, etc.)

### Negativas
- nat-gw é SPOF (se cair, VMs perdem internet)
- Para homologação: aceitável
- Para produção: HA com 2 nat-gw + VRRP

### Considerações
- IPs públicos do LoadBalancer (177.91.66.35-38) precisam estar roteados diretamente para a rede interna
- nat-gw só cuida de tráfego originado DE DENTRO para FORA
- nat-gw NÃO faz NAT para IPs do LoadBalancer (eles são acessados diretamente)

## Evolução Futura

### HA do NAT Gateway
- Adicionar segunda VM nat-gw2
- Keepalived/VRRP entre elas
- VIP compartilhado (mesma função do HAProxy para API server)

### DNS Cache Local
- Instalar unbound ou dnsmasq no nat-gw
- VMs usam 10.0.0.1 como nameserver
- Reduz latência e dependência externa

### Firewall Stateful
- Migrar iptables para nftables
- Adicionar rate limiting
- Logs estruturados (enviar para Loki)
