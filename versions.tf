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
