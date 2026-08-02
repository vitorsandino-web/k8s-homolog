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
    w2 = module.k8s_w2.ip_only
  }
}

output "all_cluster_nodes" {
  value = {
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
    "k8s-w2" = {
      ip   = module.k8s_w2.ip_only
      role = "worker"
    }
  }
}

# nat-gw não está aqui — provisionado manualmente (ver docs/SETUP.md)
