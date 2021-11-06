# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in var.private_endpoint_spec : format("%s", s.res_name) => s }
  name = each.value.network_interface.subnet
  virtual_network_name = each.value.network_interface.virtual_network
  resource_group_name = each.value.network_interface.resource_group
}

# Access information about an existing Private DNS Zone.
data "azurerm_private_dns_zone" "private_dns_zone" {
  for_each = { for s in var.private_endpoint_spec : format("%s", s.res_name) => s if length(s.private_dns_zone) > 0 }
  name = each.value.private_dns_zone.name
  resource_group_name = each.value.private_dns_zone.resource_group
}

# Manages a Private Endpoint.
resource "azurerm_private_endpoint" "private_endpoint" {
  for_each = { for s in var.private_endpoint_spec : format("%s", s.res_name) => s }
  name = "pe-${each.value.res_name}"
  location = each.value.location
  resource_group_name = each.value.rg
  subnet_id = data.azurerm_subnet.subnet[each.value.res_name].id

  private_service_connection {
    name = "ps-${each.value.res_name}"
    private_connection_resource_id = var.resource[each.value.res_name]
    is_manual_connection = false
    subresource_names = each.value.subresource
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone) == 0 ? [] : [1]
    content {
      name = "pdnsz-${each.value.res_name}"
      private_dns_zone_ids = [data.azurerm_private_dns_zone.private_dns_zone[each.value.res_name].id]
    }
  }
}