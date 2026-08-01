resource "proxmox_virtual_environment_vm" "nat_gw" {
  name      = var.name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  # Clone do template cloud-init
  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  # Recursos
  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  # Disco (será herdado do clone, mas podemos ajustar)
  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
    interface    = "virtio0"
  }

  # Duas interfaces de rede: privada (vmbr0 mesmo, mas rede lógica diferente) e pública
  network_device {
    bridge   = var.bridge
    model    = "virtio"
    mac_address = "00:50:56:01:01:01"  # MAC fixo para previsibilidade
  }

  network_device {
    bridge   = var.bridge
    model    = "virtio"
    mac_address = "00:50:56:01:01:02"
  }

  # Inicialização via cloud-init
  initialization {
    user_account {
      username = var.username
      password = var.password
    }

    # Interface privada (ens18 - primeira interface)
    ip_config {
      ipv4 {
        address = "${var.private_ip}/${var.private_cidr}"
      }
    }

    # DNS
    dns {
      servers = var.dns_servers
    }
  }

  # Habilita agente QEMU para melhor integração
  agent {
    enabled = true
  }

  # Inicia automaticamente
  on_boot = true

  # Tags para organização
  tags = ["k8s-homolog", "nat-gateway"]
}
