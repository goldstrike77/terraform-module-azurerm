# Manages a subnet.
resource "azurerm_subnet" "subnet" {
  for_each = { for s in local.snet_flat : format("%s", s.snet_name) => s }
  name = each.value.snet_name
  resource_group_name = var.res_spec.rg[0].name
  virtual_network_name = each.value.vnet_name
  address_prefixes = each.value.address_prefixes
  private_endpoint_network_policies_enabled = lookup(each.value, "private_endpoint_network_policies_enabled", true)
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)
  service_endpoints = lookup(each.value, "service_endpoints", [])

  dynamic "delegation" {
    for_each = length(each.value.service_delegation_name) == 0 ? [] : [1]
    content {
      name = "delegation"
      service_delegation {
        name = each.value.service_delegation_name
        actions = ["Microsoft.Network/networkinterfaces/*","Microsoft.Network/virtualNetworks/subnets/action","Microsoft.Network/virtualNetworks/subnets/join/action","Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action","Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
  }
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, subnet in azurerm_subnet.subnet: i => subnet.id }
}

# Manages a network security group that contains a list of network security rules.
resource "azurerm_network_security_group" "network_security_group" {
  for_each = { for s in local.nsg_flat : format("%s", s.subnet_name) => s }
  name = "nsg-${each.value.subnet_name}"
  resource_group_name = var.res_spec.rg[0].name
  location = each.value.location
  tags = merge(var.tags,each.value.tags)
}

# Manages a Network Security Rule.
resource "azurerm_network_security_rule" "network_security_rule" {
  for_each = { for s in local.nsgr_flat : format("%s", s.nsrg_name) => s }
  resource_group_name = var.res_spec.rg[0].name
  network_security_group_name = azurerm_network_security_group.network_security_group[each.value.subnet_name].name
  name = each.value.nsrg_name
  direction = each.value.direction
  access = each.value.access
  priority = each.value.priority
  protocol = each.value.protocol
  source_address_prefix = each.value.source_address_prefix
  source_address_prefixes = each.value.source_address_prefixes
  destination_address_prefix = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
  source_port_range = each.value.source_port_range
  source_port_ranges = each.value.source_port_ranges
  destination_port_range = each.value.destination_port_range
  destination_port_ranges = each.value.destination_port_ranges
  description = each.value.description
}

# Associates a Network Security Group with a Subnet within a Virtual Network.
resource "azurerm_subnet_network_security_group_association" "subnet_network_security_group_association" {
  for_each = { for s in local.nsg_flat : format("%s", s.subnet_name) => s }
  subnet_id = azurerm_subnet.subnet[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.network_security_group[each.value.subnet_name].id
}