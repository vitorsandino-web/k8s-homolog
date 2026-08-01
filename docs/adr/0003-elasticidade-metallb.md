# ADR 0003: Elasticidade via MetalLB em Modo L2

## Status
Aceito (2026-08-01)

## Contexto
Serviços do cluster (Zabbix, Grafana, ingress) precisam ser acessíveis tanto internamente quanto externamente. Soluções tradicionais de LoadBalancer (HAProxy + Keepalived com VIP) adicionam complexidade e são SPOF. Necessidade de redundância nativa sem dependência de BGP.

## Decisão

### MetalLB em Modo L2

MetalLB é instalado como DaemonSet em todos os nodes. Quando um Service tipo `LoadBalancer` é criado, MetalLB atribui um IP do pool configurado e responde ARP/NDP por esse IP em todos os nodes.

#### Configuração de Pools

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool-interno
  namespace: metallb-system
spec:
  addresses:
    - 10.0.0.230-10.0.0.240
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool-publico
  namespace: metallb-system
spec:
  addresses:
    - 177.91.66.35-177.91.66.38
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
    - pool-interno
    - pool-publico
```

### Como Funciona a Redundância

1. Service `grafana` tipo LoadBalancer criado com annotation `metallb.universe.tf/loadBalancerIPs=10.0.0.235`
2. MetalLB atribui 10.0.0.235 ao Service
3. Todos os nodes respondem ARP por 10.0.0.235
4. Switch aprende o MAC do node que respondeu primeiro
5. Se esse node cair:
   - ARP cache expira (5-15 min dependendo do switch)
   - Outro node assume
   - Failover completo (limitação do L2)

### Limitações do Modo L2

- **Failover lento**: depende do ARP cache dos switches (5-15 min)
- Para failover sub-segundo, seria necessário BGP (não temos roteador BGP)

### Vantagens

- **Sem SPOF**: qualquer node pode receber tráfego
- **Sem VIP flutuante**: não precisa de Keepalived
- **Sem BGP**: funciona com switches L2 simples
- **Integrado**: MetalLB roda DENTRO do cluster

## Consequências

### Positivas
- Redundância nativa sem componentes extras
- Funciona com 1 host Proxmox (não precisa de 2 LBs)
- Evolui facilmente para BGP quando houver roteador compatível

### Negativas
- Failover mais lento que BGP (5-15 min vs 1-3 seg)
- Limitação aceitável para homologação

## Alternativas Consideradas

### HAProxy + Keepalived dedicado
- Prós: failover rápido (1-3 seg)
- Contras: VM extra, SPOF do LB, complexidade
- Decisão: MetalLB para começar, evoluir se necessário

### BGP Mode
- Prós: failover sub-segundo
- Contras: precisa de roteador BGP, configuração complexa
- Decisão: L2 por simplicidade

### cloud-provider LoadBalancer
- Não aplicável: estamos em bare-metal (Proxmox)
