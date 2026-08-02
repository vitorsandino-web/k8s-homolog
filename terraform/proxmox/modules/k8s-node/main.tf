# VM do cluster k8s-homolog
#
# Estratégia: linked clone puro (disco 2.2 GB do template, rápido)
# + expansão posterior via Ansible (playbook expand-disks.yml).
# Isso evita o zeroinit lento do Terraform (~2 min/VM) e problemas de drift.

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
    user_account {
      username = var.username
      # Sem SSH key — autenticação exclusiva via senha (lab/homolog)
      # Senha injetada pelo template cloud-init (user-data snippet)
      keys = []
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

  # agent desabilitado para evitar travamento do apply
  # (template não tem qemu-guest-agent pré-instalado)
  agent {
    enabled = false
  }

  on_boot = true

  tags = ["k8s-homolog", var.role]
}
