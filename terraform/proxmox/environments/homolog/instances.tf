# NAT Gateway - saída de internet do cluster + bastion SSH
module "nat_gw" {
  source = "../../modules/nat-gateway"

  name           = "nat-gw"
  vm_id          = 200
  proxmox_node   = var.proxmox_node
  template_vm_id = var.template_id
  private_ip     = "10.0.0.1"
  public_ip      = "177.91.66.34"
  public_gateway = "177.91.66.33"
  cores          = 4
  memory         = 1024
  bridge         = var.bridge
  username       = var.default_username
  ssh_public_key = var.ssh_public_key
}

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
  username       = var.default_username
  ssh_public_key = var.ssh_public_key
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
  username       = var.default_username
  ssh_public_key = var.ssh_public_key
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
  username       = var.default_username
  ssh_public_key = var.ssh_public_key
}

# Worker 1 - 12 GB RAM (roda todos os workloads)
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
  username       = var.default_username
  ssh_public_key = var.ssh_public_key
}
