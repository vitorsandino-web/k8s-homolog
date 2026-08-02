# Cluster Kubernetes de homologação
# IMPORTANTE: nat-gateway NÃO é gerenciado por Terraform.
# É provisionado manualmente via Proxmox (ver docs/SETUP.md §2.2) e
# gerenciado via Ansible (playbook 02-nat-gateway.yml).
# Razão: drift detection do Terraform recriava a nat-gw quando o
# disco era expandido manualmente.

# Control Plane 1 - 8 GB RAM
module "k8s_cp1" {
  source = "../../modules/k8s-node"

  name           = "k8s-cp1"
  vm_id          = 201
  proxmox_node   = var.proxmox_node
  template_vm_id = var.template_id
  ip_address     = "10.0.0.201/24"
  gateway        = "10.0.0.1"
  cores          = 4
  memory         = 8192
  datastore_id   = var.datastore_id
  bridge         = var.bridge
  role           = "control-plane"
  username       = "homolog"
}

# Control Plane 2 - 8 GB RAM
module "k8s_cp2" {
  source = "../../modules/k8s-node"

  name           = "k8s-cp2"
  vm_id          = 202
  proxmox_node   = var.proxmox_node
  template_vm_id = var.template_id
  ip_address     = "10.0.0.202/24"
  gateway        = "10.0.0.1"
  cores          = 4
  memory         = 8192
  datastore_id   = var.datastore_id
  bridge         = var.bridge
  role           = "control-plane"
  username       = "homolog"
}

# Control Plane 3 - 8 GB RAM
module "k8s_cp3" {
  source = "../../modules/k8s-node"

  name           = "k8s-cp3"
  vm_id          = 203
  proxmox_node   = var.proxmox_node
  template_vm_id = var.template_id
  ip_address     = "10.0.0.203/24"
  gateway        = "10.0.0.1"
  cores          = 4
  memory         = 8192
  datastore_id   = var.datastore_id
  bridge         = var.bridge
  role           = "control-plane"
  username       = "homolog"
}

# Worker 1 - 12 GB RAM (workloads)
module "k8s_w1" {
  source = "../../modules/k8s-node"

  name           = "k8s-w1"
  vm_id          = 211
  proxmox_node   = var.proxmox_node
  template_vm_id = var.template_id
  ip_address     = "10.0.0.211/24"
  gateway        = "10.0.0.1"
  cores          = 4
  memory         = 12288
  datastore_id   = var.datastore_id
  bridge         = var.bridge
  role           = "worker"
  username       = "homolog"
}

# Worker 2 - 12 GB RAM (redundância de workloads)
module "k8s_w2" {
  source = "../../modules/k8s-node"

  name           = "k8s-w2"
  vm_id          = 212
  proxmox_node   = var.proxmox_node
  template_vm_id = var.template_id
  ip_address     = "10.0.0.212/24"
  gateway        = "10.0.0.1"
  cores          = 4
  memory         = 12288
  datastore_id   = var.datastore_id
  bridge         = var.bridge
  role           = "worker"
  username       = "homolog"
}
