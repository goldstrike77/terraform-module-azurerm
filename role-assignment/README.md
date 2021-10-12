#### Usage
The release number and dependency resource ID needs to be modified.
```hcl
module "role_assignment" {
  source      = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec   = var.rg_spec
  resource_id = module.resource_group.resource_group_id
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
variable "rg_spec" {
  default = {
    name = "rg-example-prd-001"
    role_ass = [
      {
        type = "user"
        name = ["user1@contoso.com","user2@contoso.com"]
        role = "Reader"
      },
      {
        type = "group"
        name = ["infra","development"]
        role = "Owner"
      },
      {
        type = "app"
        name = ["azure-cli-2020-11-27-03-54-38","azure-cli-2021-10-08-09-44-48"]
        role = "Contributor"
      }
    ]
  }
}
```