terraform {
  # versioning syntax: https://www.terraform.io/docs/configuration/version-constraints.html#version-constraint-syntax
  required_version = ">= 1.0"

  # versioning syntax: https://www.terraform.io/docs/configuration/modules.html#module-versions
  # ~> 1.0 = 1.x
  required_providers {

    # https://github.com/terraform-providers/terraform-provider-azurerm/releases
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }

    # https://github.com/terraform-providers/terraform-provider-azuread/releases
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 2.0"
    }
  }
}
