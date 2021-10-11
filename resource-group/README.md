#### Usage
Only the release number needs to be modified.
```hcl
module "resource_group" {
  source  = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//resource-group?ref=v0.1"
  env     = var.env
  tags    = var.tags
  rg_flat = var.rg_flat
}
```

#### Variables
There are some variables that can (Or needs to) be overridden:
```hcl
variable "env" {
  default = {
    geography    = "china"
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
variable "rg_flat" {
  default = {
    name = "rg-aks-prd-001"
  }
}
```