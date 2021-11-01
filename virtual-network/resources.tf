# Manages a virtual network.
resource "azurerm_virtual_network" "virtual_network" {
  for_each            = { for s in var.res_spec.vnet : format("%s", s.name) => s }
  name                = each.value.name
  resource_group_name = var.res_spec.rg[0].name
  address_space       = each.value.cidr
  dns_servers         = each.value.dns != [] ? each.value.dns : null
  location            = each.value.location
  tags                = merge(var.tags,each.value.tags)
}

/*
# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count     = length(local.role_flat) > 0 ? 1 : 0
  source    = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource  = { for i, resource_group in azurerm_resource_group.resource_group: i => resource_group.id }
}
*/