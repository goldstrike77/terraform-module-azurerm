#### Usage
Only the release number needs to be modified.
```hcl
module "resource_group" {
  source   = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//resource-group?ref=v0.1"
  tags     = var.tags
  res_spec = var.res_spec
}
```

#### Variables
There are some variables that can (Or needs to) be overridden:
```hcl
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
variable "res_spec" {
  default = {
    rg_spec = [
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
}
```