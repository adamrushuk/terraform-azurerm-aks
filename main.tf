locals {
  # TODO: consider moving defaults to object var, as per: https://binx.io/blog/2020/01/02/module-parameter-defaults-with-the-terraform-object-type/
  default_agent_profile = {
    name                 = "default"
    count                = 1
    orchestrator_version = var.kubernetes_version
    vm_size              = "Standard_D2s_v3"
    os_type              = "Linux"
    enable_auto_scaling  = false
    min_count            = null
    max_count            = null
    type                 = "VirtualMachineScaleSets"
    node_taints          = null
    # TODO: add custom vnet support
    # vnet_subnet_id        = var.nodes_subnet_id
    max_pods              = 30
    os_disk_size_gb       = 32
    enable_node_public_ip = false
  }

  default_node_pool = merge(local.default_agent_profile, var.default_node_pool)
}

# AKS
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# NOTE: Requires "Azure Active Directory Graph" "Directory.ReadWrite.All" Application API permission to create, and
# also requires "User Access Administrator" role to delete
# ! You can assign one of the required Azure Active Directory Roles with the AzureAD PowerShell Module
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group
resource "azuread_group" "aks_admins" {
  count                   = var.aad_auth_enabled ? 1 : 0
  display_name            = "${var.name}-aks-administrators"
  description             = "${var.name} Kubernetes cluster administrators"
  prevent_duplicate_names = true
  security_enabled        = true
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.name
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = var.sla_sku
  role_based_access_control_enabled = var.role_based_access_control_enabled
  tags                              = var.tags

  default_node_pool {
    name                 = local.default_node_pool.name
    orchestrator_version = local.default_node_pool.orchestrator_version
    vm_size              = local.default_node_pool.vm_size
    node_count           = local.default_node_pool.count
    enable_auto_scaling  = local.default_node_pool.enable_auto_scaling
    min_count            = local.default_node_pool.min_count
    max_count            = local.default_node_pool.max_count
    max_pods             = local.default_node_pool.max_pods
    os_disk_size_gb      = local.default_node_pool.os_disk_size_gb
    type                 = local.default_node_pool.type
    node_taints          = local.default_node_pool.node_taints
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

  # managed identity block
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#identity
  identity {
    type = "SystemAssigned"
  }

  # https://docs.microsoft.com/en-us/azure/aks/azure-ad-rbac
  # conditional dynamic block
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.aad_auth_enabled ? [1] : []
    content {
      managed = true
      admin_group_object_ids = [
        azuread_group.aks_admins[0].id
      ]
    }
  }

  # https://docs.microsoft.com/en-ie/azure/governance/policy/concepts/policy-for-kubernetes
  azure_policy_enabled = var.azure_policy_enabled

  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#oms_agent
  # conditional dynamic block
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != "" ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#network_plugin
  network_profile {
    load_balancer_sku  = var.load_balancer_sku
    outbound_type      = "loadBalancer"
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }
}

# Add role to access AKS Resource View
# https://docs.microsoft.com/en-us/azure/aks/kubernetes-portal
resource "azurerm_role_assignment" "aks_portal_resource_view" {
  principal_id         = azuread_group.aks_admins[0].id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks.id
}


# Add existing AAD group as a member to the <AKS_CLUSTER_NAME>-aks-administrators group
data "azuread_group" "existing_aks_admins" {
  count            = var.aks_admin_group_member_name != "" ? 1 : 0
  display_name     = var.aks_admin_group_member_name
  security_enabled = true
}

resource "azuread_group_member" "existing_aks_admins" {
  count            = var.aks_admin_group_member_name != "" ? 1 : 0
  group_object_id  = azuread_group.aks_admins[0].id
  member_object_id = data.azuread_group.existing_aks_admins[0].id
}
