# Access information about an existing Virtual Network.
data "azurerm_virtual_network" "virtual_network" {
  for_each = { for s in distinct(local.vnet_flat) : format("%s", s.vnet) => s }
  name = each.value.vnet
  resource_group_name = each.value.rg
}

# Manage Private DNS zones within Azure DNS.
resource "azurerm_private_dns_zone" "private_dns_zone" {
  for_each = { for s in var.res_spec.private_dns_zone[*] : format("%s", s.name) => s }
  name = each.value.name
  resource_group_name = var.res_spec.rg[0].name
  tags = merge(var.tags,each.value.tags)
}

# Manage Private DNS zone Virtual Network Links.
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_virtual_network_link" {
  for_each = { for s in local.dns_flat : format("%s%s%s", s.name, s.rg, s.vnet) => s }
  name = "link-to-${each.value.vnet}"
  resource_group_name  = var.res_spec.rg[0].name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone[each.value.name].name
  registration_enabled = each.value.registration
  tags = merge(var.tags,each.value.tags)
  virtual_network_id = data.azurerm_virtual_network.virtual_network[each.value.vnet].id
}