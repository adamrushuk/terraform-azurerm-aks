terraform {
  # versioning syntax: https://www.terraform.io/docs/configuration/version-constraints.html#version-constraint-syntax
  required_version = ">= 0.12"
}

# https://github.com/terraform-providers/terraform-provider-azurerm/releases
provider "azurerm" {
  version  = "~> 2.12"
  features {}
}
