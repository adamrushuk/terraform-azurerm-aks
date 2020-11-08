# Test AKS module
provider "azurerm" {
  version = "2.35.0"
  features {}
}

locals {
  # version used for both main AKS API service, and default node pool
  # https://github.com/Azure/AKS/releases
  # az aks get-versions --location uksouth --output table
  kubernetes_version  = "1.16.15"
  prefix              = "rush"
  location            = "uksouth"
  resource_group_name = "${local.prefix}-rg-azurerm-kubernetes-cluster"
  name                = "${local.prefix}-aks-cluster"

  tags = {
    Env    = "Dev"
    Owner  = "Adam Rush"
    Source = "terraform"
  }
}

resource "azurerm_resource_group" "aks" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

module "aks" {
  source = "../"

  kubernetes_version  = local.kubernetes_version
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  name                = local.name
  tags                = local.tags

  # override defaults
  default_node_pool = {
    count    = 1
    max_pods = 99
  }
}