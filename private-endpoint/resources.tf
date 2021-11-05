# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in var.private_endpoint_spec : format("%s", s.res_name) => s }
  name = each.value.network.subnet
  virtual_network_name = each.value.network.virtual_network
  resource_group_name = each.value.network.resource_group
}

# Manages a Private Endpoint.
resource "azurerm_private_endpoint" "private_endpoint" {
  for_each = { for s in var.private_endpoint_spec : format("%s", s.res_name) => s }
  name = "pe-${each.value.res_name}"
  location = each.value.location
  resource_group_name = each.value.rg
  subnet_id = data.azurerm_subnet.subnet[each.value.res_name].id

  private_service_connection {
    name                           = "ps-${each.value.res_name}"
    private_connection_resource_id = var.resource[each.value.res_name]
    is_manual_connection           = false
    subresource_names              = each.value.subresource
  }
}