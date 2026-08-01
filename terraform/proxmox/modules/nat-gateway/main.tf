resource "proxmox_virtual_environment_vm" "nat_gw" {
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

  # net0 - interface privada (sem gateway)
  network_device {
    bridge      = var.bridge
    model       = "virtio"
    mac_address = "00:50:56:01:01:01"
  }

  # net1 - interface pública (com gateway)
  network_device {
    bridge      = var.bridge
    model       = "virtio"
    mac_address = "00:50:56:01:01:02"
  }

  initialization {
    user_account {
      username = var.username
      keys     = [var.ssh_public_key]
    }

    # ip_config[0] -> net0 (privada, sem gateway)
    ip_config {
      ipv4 {
        address = "${var.private_ip}/${var.private_cidr}"
        # sem gateway aqui - de propósito
      }
    }

    # ip_config[1] -> net1 (pública, com gateway)
    # CORREÇÃO: configura direto no Terraform, não depende do Ansible
    ip_config {
      ipv4 {
        address = "${var.public_ip}/${var.public_cidr}"
        gateway = var.public_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }
  }

  # agent desabilitado enquanto o template não tiver qemu-guest-agent
  # pré-instalado (ver docs/NAT-GATEWAY.md §2 e AGENT.md §7.1)
  agent {
    enabled = false
  }

  on_boot = true

  tags = ["k8s-homolog", "nat-gateway"]
}
