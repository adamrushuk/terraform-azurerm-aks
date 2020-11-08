
locals {
  # TODO: consider moving defaults to object var, as per: https://binx.io/blog/2020/01/02/module-parameter-defaults-with-the-terraform-object-type/
  default_agent_profile = {
    name                  = "default"
    count                 = 1
    orchestrator_version  = var.kubernetes_version
    vm_size               = "Standard_D2s_v3"
    os_type               = "Linux"
    availability_zones    = [1, 2, 3]
    enable_auto_scaling   = false
    min_count             = null
    max_count             = null
    type                  = "VirtualMachineScaleSets"
    node_taints           = null
    # TODO: add custom vnet support
    # vnet_subnet_id        = var.nodes_subnet_id
    max_pods              = 30
    os_disk_size_gb       = 32
    enable_node_public_ip = false
  }

  default_node_pool = merge(local.default_agent_profile, var.default_node_pool)
}
