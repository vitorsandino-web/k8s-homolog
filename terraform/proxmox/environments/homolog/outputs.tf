output "nat_gateway" {
  value = {
    private_ip = module.nat_gw.ip_addresses.private
    public_ip  = module.nat_gw.ip_addresses.public
  }
}

output "control_planes" {
  value = {
    cp1 = module.k8s_cp1.ip_only
    cp2 = module.k8s_cp2.ip_only
    cp3 = module.k8s_cp3.ip_only
  }
}

output "workers" {
  value = {
    w1 = module.k8s_w1.ip_only
  }
}

output "all_nodes" {
  value = {
    "nat-gw" = {
      ip   = module.nat_gw.ip_addresses.private
      role = "nat-gateway"
    }
    "k8s-cp1" = {
      ip   = module.k8s_cp1.ip_only
      role = "control-plane"
    }
    "k8s-cp2" = {
      ip   = module.k8s_cp2.ip_only
      role = "control-plane"
    }
    "k8s-cp3" = {
      ip   = module.k8s_cp3.ip_only
      role = "control-plane"
    }
    "k8s-w1" = {
      ip   = module.k8s_w1.ip_only
      role = "worker"
    }
  }
}
