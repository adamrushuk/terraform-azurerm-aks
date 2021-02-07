provider "azurerm" {
  version = "2.46.1"
  features {}
}

resource "random_string" "aks" {
  length  = 4
  special = false
  upper   = false
}

locals {
  # version used for both main AKS API service, and default node pool
  # https://github.com/Azure/AKS/releases
  # az aks get-versions --location uksouth --output table
  kubernetes_version  = "1.17.16"
  location            = "uksouth"
  resource_group_name = "${random_string.aks.result}-rg-azurerm-kubernetes-cluster"
  name                = "${random_string.aks.result}-aks-cluster"

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
  source  = "adamrushuk/aks/azurerm"

  kubernetes_version  = local.kubernetes_version
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  name                = local.name
  tags                = local.tags
}

output "aks_credentials_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${module.aks.name} --overwrite-existing  --admin"
}

output "full_object" {
  value     = module.aks.full_object
  sensitive = true
}
