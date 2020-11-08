variable "location" {
  description = "Location of Azure region in use"
  type        = string
}

variable "resource_group_name" {
  description = "Existing AKS resource group name"
  type        = string
}

variable "name" {
  description = "AKS cluster name"
  type        = string
}

# version used for both main AKS API service, and default node pool
# https://github.com/Azure/AKS/releases
# az aks get-versions --location uksouth --output table
variable "kubernetes_version" {
  description = "Version for both main AKS API service, and default node pool"
  type        = string
  default     = "1.16.15"
}

variable "sla_sku" {
  description = "Defines the SLA under which the managed master control plane of AKS is running"
  type        = string
  default     = "Free"
}

variable "tags" {
  description = "A map of the tags to use on the resources"
  type        = map(string)
  default = {
    Source = "terraform"
  }
}

variable "admin_username" {
  description = "The admin username of the node VMs that will be deployed"
  default     = "sysadmin"
}

# Use "cat ~/.ssh/id_rsa.pub"
variable "admin_ssh_public_key" {
  description = "Public key for SSH access to the node VMs"
  default     = ""
}

variable "default_node_pool" {
  description = <<EOD
Default node pool configuration. Overrides/merges with locals.default_agent_profile:
```
map(object({
    name                  = string
    count                 = number
    vm_size               = string
    os_type               = string
    availability_zones    = list(number)
    enable_auto_scaling   = bool
    min_count             = number
    max_count             = number
    type                  = string
    node_taints           = list(string)
    vnet_subnet_id        = string
    max_pods              = number
    os_disk_size_gb       = number
    enable_node_public_ip = bool
}))
```
EOD

  type    = map(any)
  default = {}
}
