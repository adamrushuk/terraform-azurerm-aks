# Local Testing of terraform-azurerm-aks

## Contents

- [Local Testing of terraform-azurerm-aks](#local-testing-of-terraform-azurerm-aks)
  - [Contents](#contents)
  - [Apply](#apply)
  - [Destroy / Cleanup](#destroy--cleanup)

## Apply

```bash
# Navigate into test folder
cd test

# Init
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Outputs
terraform output
```

## Destroy / Cleanup

```bash
# Navigate into test folder
cd test

# Destroy all resources
terraform destroy

# Delete local TF state and plan
rm -rf terraform.tfstate* tfplan

# [OPTIONAL] Delete provider binaries and git modules
rm -rf .terraform
```
