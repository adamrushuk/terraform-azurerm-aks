terraform {
  # versioning syntax: https://www.terraform.io/docs/configuration/version-constraints.html#version-constraint-syntax
  required_version = ">= 0.12"

  # providers (pin all versions)
  # versioning syntax: https://www.terraform.io/docs/configuration/modules.html#module-versions
  # ~> 1.0 = 1.x
  required_providers {
    # https://github.com/terraform-providers/terraform-provider-azuread/releases
    azuread = "~> 1.0"
    random  = "~> 2.2"
    tls     = "~> 2.1"
  }
}

# https://github.com/terraform-providers/terraform-provider-azurerm/releases
provider "azurerm" {
  version = "~> 2.20"
  features {}
}

locals {
  # TODO: consider moving defaults to object var, as per: https://binx.io/blog/2020/01/02/module-parameter-defaults-with-the-terraform-object-type/
  default_agent_profile = {
    name                 = "default"
    count                = 1
    orchestrator_version = var.kubernetes_version
    vm_size              = "Standard_D2s_v3"
    os_type              = "Linux"
    availability_zones   = [1, 2, 3]
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
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group
# ! You can assign one of the required Azure Active Directory Roles with the AzureAD PowerShell Module
resource "azuread_group" "aks_admins" {
  count = var.aad_auth_enabled ? 1 : 0

  name        = "${var.name}-aks-administrators"
  description = "${var.name} Kubernetes cluster administrators"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
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

  # https://docs.microsoft.com/en-us/azure/aks/azure-ad-rbac
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
    # https://docs.microsoft.com/en-ie/azure/governance/policy/concepts/policy-for-kubernetes
    azure_policy {
      enabled = var.azure_policy_enabled
    }

    # cannot remove this deprecated block yet, due to this issue:
    # https://github.com/terraform-providers/terraform-provider-azurerm/issues/7716
    kube_dashboard {
      enabled = false
    }

    oms_agent {
      enabled                    = var.log_analytics_workspace_id != "" ? true : false
      log_analytics_workspace_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
    }
  }

  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#network_plugin
  network_profile {
    load_balancer_sku  = "Standard"
    outbound_type      = "loadBalancer"
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  tags = var.tags
}
