# Monitoramento (Zabbix + Grafana) — k8s-homolog

## Status atual (validado em produção)

| Serviço | URL | Login | Status |
|---|---|---|---|
| **Grafana** | `http://177.91.66.34/grafana/` | admin / admin | ✅ HTTP 200 |
| **Dashboard "K8s Cluster - Homolog"** | `http://177.91.66.34/grafana/d/k8s-homolog-main/k8s-cluster-homolog` | admin / admin | ✅ HTTP 200 |
| **Dashboard "K8s Homolog - Full"** | `http://177.91.66.34/grafana/d/k8s-homolog-full/k8s-homolog-full` | admin / admin | ✅ HTTP 200 |
| **Zabbix** | `http://177.91.66.34/zabbix/` | Admin / zabbix | ✅ HTTP 200 |

## Topologia de acesso

```
                    Internet
                       │
                       ▼
              177.91.66.34:80 (IP público da nat-gw)
                       │
                       ▼
        ┌─────────────────────────────┐
        │  nat-gw (VM 200)             │
        │  eth1: 177.91.66.34/29      │
        │  eth0: 10.0.0.1/24          │
        │                              │
        │  nginx: proxy_pass by path  │
        │    /grafana → Host: grafana  │
        │    /zabbix  → Host: zabbix   │
        └──────────┬───────────────────┘
                   │
                   ▼ (forward via MASQUERADE)
        10.0.0.201:80 (k8s-cp1)
                   │
                   ▼
        ┌─────────────────────────────┐
        │  ingress-nginx (hostNetwork)│
        │  Routes by Host header:     │
        │    grafana.k8s.homolog       │
        │    zabbix.k8s.homolog        │
        └──────────┬───────────────────┘
                   │
       ┌───────────┴───────────┐
       ▼                       ▼
  Grafana pod            Zabbix pod
  (k8s-cp1)              (k8s-cp1)
```

## Componentes

### Grafana (`grafana` namespace)
- **Image**: grafana/grafana:12.3.1 (Helm chart 10.5.15)
- **Acesso**: `http://177.91.66.34/grafana/`
- **Login**: admin / admin
- **Dashboards importados**:
  - `k8s-homolog-main` (K8s Cluster - Homolog)
  - `k8s-homolog-full` (K8s Homolog - Full)
- **Datasource**: Prometheus (`http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`)
- **Limitações**: sem plugin store (sem internet para download), sem persistence

### Zabbix (`zabbix` namespace)
| Componente | Image | Porta | Status |
|---|---|---|---|
| `zabbix-postgres` | postgres:15-alpine | 5432 | ✅ k8s-cp1 |
| `zabbix-server` | zabbix/zabbix-server-pgsql:6.4.21-alpine | 10051 | ✅ k8s-cp1 |
| `zabbix-web` | zabbix/zabbix-web-nginx-pgsql:6.4.21-alpine | 8080 | ✅ k8s-cp1 |
- **Acesso**: `http://177.91.66.34/zabbix/`
- **Login default**: Admin / zabbix
- **DB**: zabbix/zabbixpass
- **Tolerations + nodeName=k8s-cp1** (pinning para evitar reschedule problemático)
- **Limitações**: sem PVC (dados perdidos em restart), sem HA

### Prometheus (`monitoring` namespace)
- **kube-prometheus-stack** (chart 38.1.0)
- **Prometheus server**: 2/2 Running
- **kube-state-metrics**: Running
- **node-exporter**: 4/5 Running (1 CrashLoopBackOff em w2)
- **Service**: ClusterIP 10.110.68.71:9090 (interno)
- **Grafana datasource** aponta para `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`

### Ingress (nginx-ingress)
- **Tipo**: Deployment + hostNetwork=true
- **Node**: k8s-cp1 (com tolerations)
- **Versão**: 4.15.1
- **Service**: ClusterIP (LoadBalancer IP não usado — via nat-gw nginx)

### nat-gw nginx (reverse proxy)
- **Path-based routing** (sem Host header necessário):
  - `/grafana/` → set Host: `grafana.k8s.homolog` → 10.0.0.201:80
  - `/zabbix/` → set Host: `zabbix.k8s.homolog` → 10.0.0.201:80
- **Config**: `/etc/nginx/sites-available/monitor`

## Comandos Essenciais

```bash
# Status geral
sshpass -p 'Homolog@2026!' ssh ...@10.0.0.201 'sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -A'

# Teste acesso externo
sshpass -p 'DPI7317wf16!' ssh ...@177.91.64.37 '
  curl -sS -o /dev/null -w "/grafana: HTTP %{http_code}\n" -L --max-time 5 http://177.91.66.34/grafana/
  curl -sS -o /dev/null -w "/zabbix:  HTTP %{http_code}\n" --max-time 5 http://177.91.66.34/zabbix/
'

# Logs zabbix
sshpass -p 'Homolog@2026!' ssh ...@10.0.0.201 '
  sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl logs -n zabbix zabbix-web --tail 50
  sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl logs -n zabbix zabbix-server --tail 50
  sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl logs -n zabbix zabbix-postgres --tail 20
'

# Logs Grafana
sshpass -p 'Homolog@2026!' ssh ...@10.0.0.201 '
  sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl logs -n grafana -l app.kubernetes.io/name=grafana --tail 30
'

# Reiniciar tudo
sshpass -p 'Homolog@2026!' ssh ...@10.0.0.201 '
  sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl delete pods -A --all --force --grace-period=0
'
```

## Limitações Conhecidas

1. **Sem persistence** — Zabbix perde DB se pod postgres reiniciar
2. **nodeName pinning** — Zabbix postgres pinned em k8s-cp1 (sem auto-scaling)
3. **Ingress único node** — se k8s-cp1 cair, monitoramento fica off
4. **Datasource Prometheus só via pod network** — funciona dentro do cluster
5. **Sem HTTPS** — HTTP puro (configurar cert-manager para TLS)
6. **Grafana sem plugin store** — dashboards e datasource configurados manualmente

## Roadmap

- [ ] HTTPS via cert-manager + Cloudflare DNS-01
- [ ] Persistence Zabbix via Longhorn/NFS
- [ ] HA Zabbix (2+ servers)
- [ ] HA ingress (multi-node)
- [ ] Alerts Telegram via Grafana/Prometheus
- [ ] Slack/Teams integration Zabbix
