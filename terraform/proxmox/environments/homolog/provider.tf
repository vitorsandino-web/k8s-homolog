provider "proxmox" {
  endpoint = var.proxmox_endpoint
  # Token vem de variável de ambiente TF_VAR_proxmox_api_token
  # Configure com: export TF_VAR_proxmox_api_token="seu-token-aqui"
  api_token = var.proxmox_api_token
  insecure  = true  # Lab com certificado self-signed
}
