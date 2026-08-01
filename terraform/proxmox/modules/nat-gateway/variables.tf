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

variable "private_ip" {
  type        = string
  description = "IP privado (interface net0)"
}

variable "private_cidr" {
  type        = number
  default     = 24
  description = "CIDR da rede privada"
}

variable "public_ip" {
  type        = string
  description = "IP público (interface net1)"
}

variable "public_cidr" {
  type        = number
  default     = 29
  description = "CIDR da rede pública"
}

variable "public_gateway" {
  type        = string
  description = "Gateway da rede pública (rota default)"
}

variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
  description = "Servidores DNS"
}

variable "cores" {
  type        = number
  default     = 4
}

variable "memory" {
  type        = number
  default     = 1024
  description = "RAM em MB"
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
}

variable "username" {
  type        = string
  default     = "ubuntu"
  description = "Usuário cloud-init"
}

variable "ssh_public_key" {
  type        = string
  description = "Chave SSH pública injetada via cloud-init"
}
