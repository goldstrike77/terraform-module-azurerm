# Manages a subnet.
resource "azurerm_subnet" "subnet" {
  for_each             = { for s in var.res_spec.subnet : format("%s", s.name) => s }
  name                 = each.value.name
  resource_group_name  = var.res_spec.rg[0].name
  virtual_network_name = var.res_spec.vnet[0].name
  address_prefixes     = each.value.subnet_prefixes
  enforce_private_link_endpoint_network_policies = lookup(each.value, "enforce_private_link_endpoint_network_policies", false)
  enforce_private_link_service_network_policies = lookup(each.value, "enforce_private_link_service_network_policies", false)
  service_endpoints = lookup(each.value, "service_endpoints", null)

  dynamic "delegation" {
    for_each = length(each.value.service_delegation_name) == 0 ? [] : [1]
    content {
      name = "delegation"
      service_delegation {
        name    = each.value.service_delegation_name
        actions = ["Microsoft.Network/networkinterfaces/*","Microsoft.Network/virtualNetworks/subnets/action","Microsoft.Network/virtualNetworks/subnets/join/action","Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action","Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
  }
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count     = length(local.role_flat) > 0 ? 1 : 0
  source    = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource  = { for i, subnet in azurerm_subnet.subnet: i => subnet.id }
}