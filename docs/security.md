# Segurança - Credenciais e Secrets

## Política

**Nenhum secret é commitado neste repositório.**

Todas as credenciais sensíveis são gerenciadas via:
- Variáveis de ambiente do Terraform (`TF_VAR_*`)
- Variáveis de ambiente do shell
- Vault pessoal do operador (NUNCA em mensagens)

## Setup por ambiente

Antes de rodar `terraform apply`, configure:

```bash
# Token de API do Proxmox
# Criar em: Datacenter → Permissions → API Tokens → Add
# Formato: root@pam!terraform-token=<secret>
export TF_VAR_proxmox_api_token="root@pam!terraform-token=SEU-SECRET-AQUI"

# Senha padrão das VMs
export TF_VAR_default_password="SuaSenhaForte@2026"

# Depois rode normalmente:
cd terraform/proxmox/environments/homolog
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Arquivos protegidos

O `.gitignore` bloqueia:
- `*.tfvars` (qualquer arquivo de variáveis sem ser `.example`)
- `*.tfstate` (estado do Terraform)
- `*.tfstate.*` (backups do state)
- `terraform.tfstate` (state principal)
- `*.tfbackend` (configuração de backend)
- `tfplan`, `tfplan.json` (planos locais)
- `inventory/hosts.ini`, `inventory/hosts.json` (inventário Ansible)
- `.kube/config*` (kubeconfig)
- `*.retry` (Ansible retries)

## Auditoria

Antes de cada commit, verifique:

```bash
# Verifica se há secrets no que vai ser commitado
git diff --staged

# Procura por padrões comuns de secret
git diff --staged | grep -E "token|secret|password|key" | head -20
```

## Rotação de credenciais

Se um token vazar (commit acidental, log exposto):

1. Revogar imediatamente em Proxmox: API Tokens → Remove
2. Criar novo token
3. Atualizar env var local
4. Atualizar `.gitignore` se necessário
5. `git filter-branch` ou `git filter-repo` para limpar histórico
6. Forçar push (com cuidado)

## Histórico de incidentes

Nenhum incidente registrado até o momento.
