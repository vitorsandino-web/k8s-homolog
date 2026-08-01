variable "name" {
  type        = string
  description = "Nome da VM"
}

variable "vm_id" {
  type        = number
  description = "VM ID no Proxmox"
}

variable "proxmox_node" {
  type        = string
  description = "Nome do node Proxmox"
}

variable "template_vm_id" {
  type        = number
  description = "ID do template cloud-init"
}

variable "ip_address" {
  type        = string
  description = "IP da VM no formato CIDR (ex: 10.0.0.201/24)"
}

variable "gateway" {
  type        = string
  description = "Default gateway"
}

variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
  description = "Servidores DNS"
}

variable "cores" {
  type        = number
  default     = 4
  description = "vCPUs"
}

variable "memory" {
  type        = number
  default     = 12288
  description = "RAM em MB"
}

variable "datastore_id" {
  type        = string
  description = "Datastore do Proxmox"
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Bridge de rede"
}

variable "role" {
  type        = string
  description = "Role da VM (control-plane ou worker)"
}

variable "username" {
  type        = string
  default     = "homolog"
  description = "Usuário padrão"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Senha padrão"
}
