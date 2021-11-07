#### Usage
The release number and dependency resource ID needs to be modified.
```hcl
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, resource_group in azurerm_resource_group.resource_group: i => resource_group.id }
}
```