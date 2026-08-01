variable "proxmox_endpoint" {
  type        = string
  description = "URL da API do Proxmox (ex: https://IP:8006/api2/json)"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "Token de API no formato user@pam!tokenid=secret"
}

variable "proxmox_node" {
  type        = string
  description = "Nome do node Proxmox (hostname do host)"
}

variable "datastore_id" {
  type        = string
  description = "Datastore para discos (local-lvm, local-zfs, local, etc.)"
}

variable "template_id" {
  type        = number
  description = "ID do template cloud-init Ubuntu 22.04"
}

variable "ssh_public_key" {
  type        = string
  description = "Chave SSH pública injetada nas VMs via cloud-init"
}

variable "default_username" {
  type        = string
  default     = "ubuntu"
  description = "Usuário padrão em todas as VMs"
}

variable "default_password" {
  type        = string
  sensitive   = true
  description = "Senha padrão (não usada para nat-gateway; mantida para outras VMs via env var TF_VAR_default_password)"
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Bridge de rede"
}
