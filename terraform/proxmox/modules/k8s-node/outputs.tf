output "vm_id" {
  value = proxmox_virtual_environment_vm.k8s_node.vm_id
}

output "name" {
  value = proxmox_virtual_environment_vm.k8s_node.name
}

output "ip_address" {
  value = var.ip_address
}

output "role" {
  value = var.role
}

output "ip_only" {
  value = split("/", var.ip_address)[0]
}
