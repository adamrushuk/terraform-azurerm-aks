output "name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "node_resource_group" {
  description = "The name of the Resource Group where the Kubernetes Nodes should exist"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kubelet_identity" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity
  description = "The user-defined Managed Identity assigned to the Kubelets"
}

output "kube_config_raw" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Kube configuration of AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

# TODO: add "kube_admin_config" and "kube_admin_config_raw" once Role Based Access Control with Azure Active Directory is enabled
