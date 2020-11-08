terraform {
  # versioning syntax: https://www.terraform.io/docs/configuration/version-constraints.html#version-constraint-syntax
  required_version = ">= 0.12"
  required_providers {
    helm       = ">= 1.3.2"
    kubernetes = ">= 1.13.2"
  }
}

# https://github.com/terraform-providers/terraform-provider-azurerm/releases
provider "azurerm" {
  version  = "~> 2.12"
  features {}
}
