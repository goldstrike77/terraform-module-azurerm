#### Usage
Only the release number needs to be modified.
```hcl
module "resource_group" {
  source  = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//resource-group?ref=v0.1"
  tags    = var.tags
  rg_spec = var.rg_spec
}
```

#### Variables
There are some variables that can (Or needs to) be overridden:
```hcl
variable "env" {
  default = {
    location     = "chinaeast2"
    subscription = "f55a9c04-d605-4b56-9e3b-9a4b4d8db8cc"
  }
}
variable "tags" {
  default = {
    location    = "chinaeast2"
    environment = "prd"
    customer    = "Learn"
    owner       = "Somebody"
    email       = "somebody@mail.com"
    title       = "Engineer"
    department  = "IS"
  }
}
variable "rg_spec" {
  default = [
    {
      name     = "rg-aks-prd-001"
      location = "chinaeast2"
      tags     = {
        project = "test"
      }
      role_ass = [
        {
          type = "user"
          name = ["user1@contoso.com","user2@contoso.com"]
          role = "Reader"
        },
        {
          type = "group"
          name = ["infra","test"]
          role = "Owner"
        },
        {
          type = "app"
          name = ["azure-cli-2020-11-27-03-54-38","azure-cli-2021-10-08-09-44-48"]
          role = "Contributor"
        }
      ]
    },
    {
      name     = "rg-aks-prd-002"
      location = "chinanorth2"
      tags     = {
        project = "test"
      }
      role_ass = []
    }
  ]
}
```