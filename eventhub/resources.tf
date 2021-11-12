# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in local.network_rule_flat : format("%s-%s", s.res_name,s.subnet) => s }
  name = each.value.subnet
  virtual_network_name = each.value.virtual_network
  resource_group_name = each.value.resource_group
}

# Manages an EventHub Namespace.
resource "azurerm_eventhub_namespace" "eventhub_namespace" {
  for_each = { for s in var.res_spec.eventhub : format("%s", s.namespace) => s }
  name = each.key
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  sku = title(lookup(each.value, "sku", "Standard"))
  capacity = lookup(each.value, "capacity", 2)
  auto_inflate_enabled = lookup(each.value, "auto_inflate", false)
  maximum_throughput_units = lookup(each.value, "auto_inflate", false) ? lookup(each.value, "maximum_throughput_units", 2) : null
  zone_redundant = title(lookup(each.value, "sku", "Standard")) == "Premium" ? lookup(each.value, "zone_redundant", true) : false
  tags = merge(var.tags,each.value.tags)
  network_rulesets {
    default_action = "Deny"
    trusted_service_access_enabled = true
    virtual_network_rule = [ for subnet in local.network_rule_flat : { ignore_missing_virtual_network_service_endpoint = subnet.ignore_missing_virtual_network_service_endpoint , subnet_id = data.azurerm_subnet.subnet["${subnet.res_name}-${subnet.subnet}"].id } if subnet.res_name == each.value.namespace ]
    ip_rule = [ for ip in local.ip_rule_flat : { action = "Allow", ip_mask = ip.ip_mask } if ip.res_name == each.value.namespace ]
  }
}

# Manages a Private Endpoint.
module "private_endpoint" {
  count = length(local.private_endpoint_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//private-endpoint?ref=v0.1"
  private_endpoint_spec = local.private_endpoint_flat
  resource = { for i, eventhub_namespace in azurerm_eventhub_namespace.eventhub_namespace: i => eventhub_namespace.id }
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, eventhub_namespace in azurerm_eventhub_namespace.eventhub_namespace: i => eventhub_namespace.id }
}