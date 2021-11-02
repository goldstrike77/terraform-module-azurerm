# Manages a network security group that contains a list of network security rules.
resource "azurerm_network_security_group" "network_security_group" {
  for_each            = { for s in var.res_spec.subnet : format("%s", s.name) => s if s.security_group_rules !=[] }
  name                = "nsg-${each.value.name}"
  resource_group_name = var.res_spec.rg[0].name
  location            = var.res_spec.vnet[0].location
  tags                = merge(var.tags,each.value.tags)
}

# Manages a Network Security Rule.
resource "azurerm_network_security_rule" "network_security_rule" {
  for_each                     = { for s in var.nsgr_flat : format("%s", s.name) => s }
  resource_group_name          = var.res_spec.rg[0].name
  network_security_group_name  = azurerm_network_security_group.network_security_group[each.value.res_name].name
  name                         = each.value.name
  direction                    = each.value.direction
  access                       = each.value.access
  priority                     = each.value.priority
  protocol                     = each.value.protocol
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  source_port_range            = lookup(each.value, "source_port_range", null)
  source_port_ranges           = lookup(each.value, "source_port_ranges", null)
  destination_port_range       = lookup(each.value, "destination_port_range", null)
  destination_port_ranges      = lookup(each.value, "destination_port_ranges", null)
}

/*
# Associates a Network Security Group with a Subnet within a Virtual Network.
resource "azurerm_subnet_network_security_group_association" "subnet_network_security_group_association" {
  for_each                  = { for s in var.res_spec.subnet : format("%s", s.name) => s if s.security_group_rules !=[] }
  subnet_id                 = var.resource[each.value.name]
  network_security_group_id = azurerm_network_security_group.network_security_group[each.key].id
}
*/