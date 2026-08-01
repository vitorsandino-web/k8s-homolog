resource "proxmox_virtual_environment_vm" "k8s_node" {
  name      = var.name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  # Linked clone puro - herda disco do template
  clone {
    vm_id = var.template_vm_id
    full  = false
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  # Rede
  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  initialization {
    user_account {
      username = var.username
      keys     = [var.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }
  }

  agent {
    enabled = false
  }

  on_boot = true

  tags = ["k8s-homolog", var.role]
}
