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

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count     = length(local.role_flat) > 0 ? 1 : 0
  source    = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource  = { for i, virtual_network in azurerm_virtual_network.virtual_network: i => virtual_network.id }
}

# Manages a virtual network peering which allows resources to access other resources in the linked virtual network.
resource "azurerm_virtual_network_peering" "virtual_network_peering" {
  for_each                     = { for s in var.res_spec.vnet[0].peering : format("%s", s.remote_virtual_network_id) => s }
  name                         = "peer-to-${substr(each.value.remote_virtual_network_id, 130, -1)}"
  resource_group_name          = var.res_spec.rg[0].name
  virtual_network_name         = var.res_spec.vnet[0].name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_virtual_network_access = lookup(each.value, "allow_virtual_network_access", true)
  allow_forwarded_traffic      = lookup(each.value, "allow_forwarded_traffic", false)
  allow_gateway_transit        = lookup(each.value, "allow_gateway_transit", false)
  use_remote_gateways          = lookup(each.value, "use_remote_gateways", false)
}