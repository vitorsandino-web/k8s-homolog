resource "proxmox_virtual_environment_vm" "nat_gw" {
  name      = var.name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  # Linked clone puro - herda disco do template (2.2 GB)
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

  # Duas interfaces: privada (10.0.0.0/24) + pública (177.91.66.32/29)
  network_device {
    bridge      = var.bridge
    model       = "virtio"
    mac_address = "00:50:56:01:01:01"
  }

  network_device {
    bridge      = var.bridge
    model       = "virtio"
    mac_address = "00:50:56:01:01:02"
  }

  initialization {
    user_account {
      username = var.username
      password = var.password
    }

    # IP da primeira interface (privada) via cloud-init
    ip_config {
      ipv4 {
        address = "${var.private_ip}/${var.private_cidr}"
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

  tags = ["k8s-homolog", "nat-gateway"]
}
