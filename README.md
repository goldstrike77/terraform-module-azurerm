#### Environment variables
```hcl
export ARM_ENVIRONMENT="china"
export TF_DATA_DIR="/home/[YourName]/.terraform"
export TF_REGISTRY_CLIENT_TIMEOUT=120
export ARM_CLIENT_ID="6d34ee51-7558-4744-b3da-63bfe2474bd5"
export ARM_CLIENT_SECRET="c187c231-8c99-45b0-9d07-dbb4df620616"
export ARM_TENANT_ID="2b2af97b-542e-4860-a500-fb45adea87d9"
```

#### Requirements
| Name | Version |
|------|---------|
| terraform | >= 0.13.5 |

#### Providers
| Name | Version |
|------|---------|
| hashicorp/azurerm | >= 2.83.0 |
| hashicorp/azuread | >= 2.8.0 |
| hashicorp/random  | >= 3.1.0 |

#### provider.tf
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.83.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}
provider azurerm {
  features {}
  subscription_id = var.env.subscription
}
```
#### variables.tf
```hcl
variable "env" {
  default = {
    subscription = "58334aac-c8aa-4295-99ef-0dcaa649dd8d"
  }
}
```