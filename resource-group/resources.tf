# Manages a Resource Group.
resource "azurerm_resource_group" "resource_group" {
  for_each = { for s in var.res_spec.rg : format("%s", s.name) => s }
  name = each.value.name
  location = each.value.location
  tags = merge(var.tags,each.value.tags)
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, resource_group in azurerm_resource_group.resource_group: i => resource_group.id }
}