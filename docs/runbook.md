# Runbook - Cluster Kubernetes Homologação

## Procedimentos Operacionais

### Verificar saúde do cluster

```bash
kubectl get nodes
kubectl get pods -A
kubectl top nodes
```

### Acessar NAT Gateway

```bash
ssh homolog@10.0.0.1
# ou via Proxmox console
```

### Verificar logs do NAT

```bash
# No nat-gw
sudo iptables -t nat -L -v -n
sudo iptables -L -v -n
```

## Recuperação de Desastres

### Cenário 1: Worker caiu

```bash
# Verificar status
kubectl get nodes
kubectl describe node k8s-w1

# Se VM está down, religar via Proxmox
# Após religar, kubelet reconecta automaticamente
```

### Cenário 2: Control Plane caiu

```bash
# Se 1 CP caiu de 3, cluster continua funcionando
kubectl get nodes  # mostra CP como NotReady

# Religar VM via Proxmox
# CP reentra no etcd automaticamente
```

### Cenário 3: nat-gw caiu

```bash
# VMs perdem acesso à internet
# kubectl continua funcionando (rede interna)
# Workloads que dependem de internet (pull de imagens, API externa) falham

# Religar nat-gw
# Regras iptables persistem (se usar iptables-persistent)
```

### Cenário 4: Cluster inteiro perdido

```bash
# 1. Recriar VMs via Terraform
cd terraform/proxmox/environments/homolog
terraform apply

# 2. Reconfigurar nat-gw
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/02-nat-gateway.yml

# 3. Re-bootstrap cluster
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/01-bootstrap.yml
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/03-cp-init.yml
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/04-cp-join.yml
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/05-worker-join.yml
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/06-cilium.yml

# 4. ArgoCD ressincroniza tudo do Git
```

## Comandos Úteis

### MetalLB

```bash
# Ver pools
kubectl get ipaddresspools -n metallb-system

# Ver advertisements
kubectl get l2advertisement -n metallb-system

# Ver Services LoadBalancer
kubectl get svc -A | grep LoadBalancer
```

### Ingress

```bash
# Ver Ingress criados
kubectl get ingress -A

# Ver certificados
kubectl get certificate -A
```

### Logs específicos

```bash
# Logs de um Pod específico
kubectl logs -n namespace pod-name

# Logs de um Pod anterior (após restart)
kubectl logs -n namespace pod-name --previous

# Logs de todos os Pods de um Deployment
kubectl logs -n namespace -l app=deployment-name --tail=100 -f
```

## Manutenção Preventiva

### Limpeza de imagens Docker antigas

```bash
# Em cada node
docker system prune -a
```

### Verificar espaço em disco

```bash
# Em cada node
df -h
du -sh /var/lib/docker
```

### Backup do etcd

```bash
# No CP1
sudo ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```
