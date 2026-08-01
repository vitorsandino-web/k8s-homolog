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
  description = "Nome do node Proxmox onde a VM será criada"
}

variable "template_vm_id" {
  type        = number
  description = "ID do template cloud-init no Proxmox"
}

variable "private_ip" {
  type        = string
  description = "IP privado (interface interna)"
}

variable "private_cidr" {
  type        = number
  default     = 24
  description = "CIDR da rede privada"
}

variable "public_ip" {
  type        = string
  description = "IP público (interface externa)"
}

variable "public_cidr" {
  type        = number
  default     = 29
  description = "CIDR da rede pública"
}

variable "public_gateway" {
  type        = string
  description = "Gateway da rede pública"
}

variable "private_interface" {
  type        = string
  default     = "ens18"
  description = "Nome da interface privada"
}

variable "public_interface" {
  type        = string
  default     = "ens19"
  description = "Nome da interface pública"
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
  default     = 1024
  description = "RAM em MB"
}

variable "datastore_id" {
  type        = string
  description = "Datastore do Proxmox (local-lvm, local-zfs, etc.)"
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Bridge de rede"
}

variable "username" {
  type        = string
  default     = "homolog"
  description = "Usuário padrão"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Senha padrão (hash será calculado)"
}

variable "ssh_password_auth" {
  type        = bool
  default     = true
  description = "Permitir autenticação SSH via senha"
}
