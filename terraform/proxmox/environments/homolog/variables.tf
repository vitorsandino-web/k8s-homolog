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
  description = "ID do template cloud-init Ubuntu 22.04 (já com user homolog + senha)"
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Bridge de rede"
}
