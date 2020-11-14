# AKS
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# NOTE: Requires "Azure Active Directory Graph" "Directory.ReadWrite.All" Application API permission
resource "azuread_group" "aks_admins" {
  count = var.aad_auth_enabled ? 1 : 0

  name        = "${var.name}-aks-administrators"
  description = "${var.name} Kubernetes cluster administrators"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sla_sku

  default_node_pool {
    name                = local.default_node_pool.name
    node_count          = local.default_node_pool.count
    vm_size             = local.default_node_pool.vm_size
    availability_zones  = local.default_node_pool.availability_zones
    enable_auto_scaling = local.default_node_pool.enable_auto_scaling
    min_count           = local.default_node_pool.min_count
    max_count           = local.default_node_pool.max_count
    max_pods            = local.default_node_pool.max_pods
    os_disk_size_gb     = local.default_node_pool.os_disk_size_gb
    type                = local.default_node_pool.type
    node_taints         = local.default_node_pool.node_taints
    # TODO: add custom vnet support
    # vnet_subnet_id      = local.default_node_pool.vnet_subnet_id
  }

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = chomp(
        coalesce(
          var.admin_ssh_public_key,
          tls_private_key.ssh.public_key_openssh,
        )
      )
    }
  }

  # managed identity block: https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html#type-1
  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true

    # conditional dynamic block
    dynamic "azure_active_directory" {
      for_each = var.aad_auth_enabled ? [1] : []
      content {
        managed = true
        admin_group_object_ids = [
          azuread_group.aks_admins[0].id
        ]
      }
    }
  }

  addon_profile {
    # cannot remove this deprecated block yet, due to this issue:
    # https://github.com/terraform-providers/terraform-provider-azurerm/issues/7716
    kube_dashboard {
      enabled = false
    }

    # oms_agent {
    #   enabled                    = var.aks_container_insights_enabled
    #   log_analytics_workspace_id = var.aks_container_insights_enabled ? azurerm_log_analytics_workspace.aks[0].id : null
    # }
  }

  tags = var.tags
}
