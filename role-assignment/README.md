#### Usage
The release number and dependency resource ID needs to be modified.
```hcl
module "role_assignment" {
  source    = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = var.rg_spec
  resource  = module.resource_group.resource_group_id
}
```