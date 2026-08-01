output "vm_id" {
  value = proxmox_virtual_environment_vm.nat_gw.vm_id
}

output "name" {
  value = proxmox_virtual_environment_vm.nat_gw.name
}

output "private_ip" {
  value = var.private_ip
}

output "public_ip" {
  value = var.public_ip
}

output "ip_addresses" {
  value = {
    private = var.private_ip
    public  = var.public_ip
  }
}
