# ADR 0002: Topologia de Rede e NAT

## Status
Aceito (2026-08-01, revisado 2026-08-02)

## Contexto
Cluster k8s precisa de saída pra internet (apt, pull de imagens, APIs externas)
e os agentes de fora precisam acessar o cluster via SSH (bastion).
A infraestrutura é 1 host Proxmox com VMs em rede privada 10.0.0.0/24.
Apenas o IP público 177.91.66.34 (range 177.91.66.32/29) é roteado pra dentro.

## Decisão

### Topologia

- **Bridge única**: `vmbr0`, sem VLAN. IPs públicos chegam roteados direto
  nessa bridge (regra do firewall externo).
- **Rede privada**: 10.0.0.0/24, gateway 10.0.0.1 (a própria nat-gw).
- **Rede pública**: 177.91.66.32/29, gateway 177.91.66.33 (firewall externo).
- **nat-gw** (VM 200): 2 interfaces, IP privado 10.0.0.1, IP público 177.91.66.34.
  Faz MASQUERADE/SNAT e serve de bastion SSH via ProxyJump.

### Regra de gateway (importante!)

- Interface privada (net0): **sem gateway** — ela É o gateway da rede privada.
- Interface pública (net1): **com gateway 177.91.66.33** — única rota default.

Se as duas tiverem gateway, o sistema fica com duas rotas default
concorrentes e o comportamento de saída fica imprevisível.

### nat-gw provisionado via Ansible (não Terraform)

Por que não está no state do Terraform:
1. O disco de 2.2 GB do template é insuficiente — precisa de +6 GB.
2. Terraform detecta essa expansão como "drift" e tenta recriar a VM.
3. Recriar a nat-gw = perder conectividade de todo o cluster.

Solução: nat-gw é provisionada uma vez via `ansible/playbooks/provision-nat-gw.yml`
e gerenciada manualmente depois (expansão de disco, NAT/iptables).

### Acesso SSH via bastion

Todas as VMs do cluster (privadas) são acessadas via ProxyJump pela nat-gw.
Configuração em `~/.ssh/config`:
```
Host 10.0.0.*
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519_k8s
    StrictHostKeyChecking accept-new
    ProxyCommand ssh -i ~/.ssh/id_ed25519_k8s -o StrictHostKeyChecking=accept-new -W %h:%p ubuntu@177.91.66.34
```

## Consequências

### Positivas
- Acesso único (bastion) com chave SSH (sem senha em comandos).
- Cluster isolado em rede privada, só expõe o necessário.
- Path claro pra HA do nat-gw (2 VMs + Keepalived no futuro).

### Negativas
- nat-gw é SPOF (se cair, perde conectividade).
- Disco do nat-gw precisa ser expandido manualmente após provisionar.

### Riscos
- Drift do Terraform no nat-gw: resolvido removendo-o do Terraform.
- Lock órfão no Proxmox: resolvido com procedimento em AGENT.md §7.3.
