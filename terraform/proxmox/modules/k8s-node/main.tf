# VM do cluster k8s-homolog
#
# Estratégia: linked clone puro (disco 2.2 GB do template, rápido).
# A senha é injetada direto no bloco user_account do provider —
# isso evita dependência do qemu-guest-agent (que o template não tem).

resource "proxmox_virtual_environment_vm" "k8s_node" {
  name      = var.name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

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

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  initialization {
    # Senha explícita (Proxmox armazena de forma protegida na config VM)
    user_account {
      username = var.username
      password = var.default_password
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

  # agent habilitado para diagnóstico via `qm guest exec`
  agent {
    enabled = true
  }

  on_boot = true
  tags    = ["k8s-homolog", var.role]
}
