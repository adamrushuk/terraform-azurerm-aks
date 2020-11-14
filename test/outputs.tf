output "aks_credentials_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${module.aks.name} --overwrite-existing"
}

output "full_object" {
  value     = module.aks.full_object
  sensitive = true
}
