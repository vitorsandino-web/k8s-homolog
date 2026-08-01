resource "proxmox_virtual_environment_vm" "k8s_node" {
  name      = var.name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
    interface    = "virtio0"
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  initialization {
    user_account {
      username = var.username
      password = var.password
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
    enabled = true
  }

  on_boot = true

  tags = ["k8s-homolog", var.role]
}
