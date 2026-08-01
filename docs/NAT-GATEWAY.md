# NAT Gateway — Topologia e Bring-up

Documento de referência canônica para o `nat-gw` do cluster k8s-homolog.

Este arquivo substitui suposições de tentativas anteriores. Foi criado após
identificar dois problemas concretos que travavam a execução:

1. `terraform apply` ficava preso esperando `qemu-guest-agent` responder
   (template não tinha o agente instalado, então timeout de até 30 min).

2. Terraform só configurava a interface privada via cloud-init; a interface
   pública ficava sem IP até "o Ansible configurar depois". O provider
   `bpg/proxmox` aceita múltiplos blocos `ip_config`, então configuramos
   as duas interfaces direto no Terraform.

## Topologia (bridge única, sem VLAN)

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
                          (2 interfaces, mesma bridge)
                                      │
                   ┌──────────────────┼──────────────────┐
                   │                  │                   │
             k8s-cp1 .201       k8s-cp2 .202        k8s-w1 .211
             1 interface só,    (idem)               (idem)
             gw = 10.0.0.1
```

Ponto-chave: as duas interfaces do `nat-gw` estão na mesma bridge física
(`vmbr0`). Não há VLAN, não há segunda bridge, não há roteador intermediário —
o IP público `177.91.66.34/29` já chega diretamente nessa bridge.

## Regra de gateway

- **Interface privada (net0)**: `10.0.0.1/24`, **sem gateway**. Ela é o
  gateway da rede privada — não deve ter uma rota default apontando pra
  fora por ela.

- **Interface pública (net1)**: `177.91.66.34/29`, gateway `177.91.66.33`.
  É por aqui que sai a rota default (`0.0.0.0/0`) para a internet.

Se as duas interfaces tiverem gateway configurado, o sistema fica com duas
rotas default concorrentes e o comportamento de saída fica imprevisível.

## Bring-up (Fase 1 do AGENT.md)

1. Terraform cria o `nat-gw` JÁ com as duas interfaces configuradas.
   Ver módulo em `terraform/proxmox/modules/nat-gateway/main.tf`.
2. `agent.enabled = false` enquanto o template não tiver `qemu-guest-agent`
   pré-instalado — evita o apply travar esperando o agente responder.
3. Ansible só cuida de NAT/iptables (rede já veio pronta do Terraform).

### Validação com polling (não `sleep` fixo)

```bash
timeout=180; interval=5; elapsed=0
until ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
    ubuntu@177.91.66.34 'echo ok' 2>/dev/null; do
  sleep "$interval"; elapsed=$((elapsed+interval))
  [ "$elapsed" -ge "$timeout" ] && { echo "Timeout SSH"; exit 1; }
done
echo "nat-gw acessível via SSH público"
```

Depois validar rede dentro da VM:

```bash
ssh ubuntu@177.91.66.34 'ip -4 addr show'
# esperado: ens18 = 10.0.0.1/24 (sem rota default associada)
#           ens19 = 177.91.66.34/29

ssh ubuntu@177.91.66.34 'ip route'
# esperado: default via 177.91.66.33 dev ens19  <- ÚNICA rota default

ssh ubuntu@177.91.66.34 'ping -c2 1.1.1.1'
# precisa responder
```

## Checklist de diagnóstico

| Sintoma | Causa provável | Solução |
|---------|----------------|---------|
| `terraform apply` nunca termina, VM já `running` | `agent.enabled = true` esperando guest agent | Usar `agent.enabled = false` |
| SSH no IP público não conecta, VM `running` | Interface pública sem IP | Verificar 2 blocos `ip_config` |
| SSH conecta, mas `ping 1.1.1.1` falha | Rota default errada/ausente | `ip route` deve ter só `default via 177.91.66.33` |
| SSH conecta, internet sai, mas VMs privadas não saem | Ansible (MASQUERADE) não rodou, ou interfaces trocadas | Verificar `private_iface`/`public_iface` |
| Clone trava com erro de lock de storage | Lock órfão de tentativa anterior | Ver AGENT.md §7.3 |
