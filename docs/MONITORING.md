# Monitoramento (Zabbix + Grafana) - k8s-homolog

## Acesso externo (IPs publicos dedicados)

| Servico | URL | Login |
|---|---|---|
| **Grafana** | `http://177.91.66.37/` | admin / admin |
| **Zabbix** | `http://177.91.66.38/` | Admin / zabbix |

## Topologia

```
Internet
   |
   | (NAT 1:1 provedor)
   v
Proxmox 177.91.64.37
   |
   v
nat-gw (VM 200)
   |-- eth0: 10.0.0.1/24 (rede privada)
   |-- eth1: 177.91.66.34/29 + aliases 177.91.66.37, 177.91.66.38
   |       |
   |       | nginx listen:
   |       |  - 177.91.66.37:80 -> Grafana (cluster)
   |       |  - 177.91.66.38:80 -> Zabbix (cluster)
   |       |  - 177.91.66.34: SEM LISTENER (SSH only)
   |       |
   |       v
   |   k8s-cp1 (10.0.0.201:80 ingress-nginx)
   |       |-- Host: grafana.k8s.homolog -> Grafana svc
   |       |-- Host: zabbix.k8s.homolog -> Zabbix svc
   |
   v
cluster K8s (5 nodes)
```

## Padrao de roteamento

Cada IP publico dedicado tem um **server block** nginx especifico no nat-gw que:

1. Faz `rewrite ^(/.*)$ /grafana$1 break` (ou `/zabbix`) injecionando o prefixo
2. `proxy_pass http://10.0.0.201:80` no upstream ingress-nginx
3. `Host: grafana.k8s.homolog` (ou `zabbix.k8s.homolog`) - upstream faz Host-based routing

## Zabbix assets rewrite (sub_filter)

O Zabbix upstream devolve HTML com **paths relativos** (ex: `href="favicon.ico"`, `href="assets/styles/blue-theme.css"`).

Sem rewrite, o navegador resolve esses paths **sem /zabbix/** e o nginx upstream retorna 404.

O nat-gw aplica `sub_filter` para adicionar `/zabbix/` antes dos paths relativos:

```nginx
sub_filter 'href="/' 'href="/zabbix/';
sub_filter 'src="/' 'src="/zabbix/';
sub_filter 'href="assets/' 'href="/zabbix/assets/';
sub_filter 'src="js/' 'src="/zabbix/js/';
sub_filter 'href="favicon.ico' 'href="/zabbix/favicon.ico';
# etc...
```

## Status validado

- Grafana 177.91.66.37 HTTP 200 (login page, dashboards)
- Zabbix 177.91.66.38 HTTP 200 (login page, assets CSS/JS)
- 177.91.66.34 SEM listener (SSH only na porta 22)
- 5 nodes K8s Ready
- Zabbix 3/3 pods Running
- Grafana 1/1 pod Running
