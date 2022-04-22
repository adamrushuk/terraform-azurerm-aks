terraform {
  required_version = ">= 0.13"

  required_providers {
    # https://github.com/terraform-providers/terraform-provider-azurerm/releases
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.3.0"
    }
    # https://github.com/terraform-providers/terraform-provider-azuread/releases
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.21.0"
    }
  }
}

provider "azurerm" {
  features {}
}
