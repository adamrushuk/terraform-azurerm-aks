# Example: Basic AKS Cluster

This example shows how to spin up a basic
[Azure Kubernetes Service (AKS) cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster),
and a single [Azure AD Group](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group)
for admin access.

## Used resources

The main resources used are:

- `azuread_group`
- `azurerm_kubernetes_cluster`

## Prereqs

*This example was developed using Terraform version `0.13`.
It may not work out-of-the-box using other versions.*

This example expects you to already have
[Terraform installed](https://learn.hashicorp.com/tutorials/terraform/install-cli).

## How to

### Create

First, make sure the dependencies are downloaded and available:

```sh
terraform init
```

then carry on by creating the resources:

```sh
terraform apply
```

After the `apply` operation has finished you should see output
in your console similar to the one below:

```sh
...

Outputs:

aks_credentials_command = az aks get-credentials --resource-group <RANDOM_STRING>-rg-azurerm-kubernetes-cluster --name <RANDOM_STRING>-aks-cluster --overwrite-existing
full_object = <sensitive>
```

**Before** you run `aks_credentials_command` to download the AKS credentials and allow access via `kubectl`, you
must add yourself to the `<RANDOM_STRING>-aks-cluster-aks-administrators` AAD group.

You can view the full AKS module output by running the command below:

```sh
terraform output full_object
```

### Destroy

```sh
terraform destroy
```
