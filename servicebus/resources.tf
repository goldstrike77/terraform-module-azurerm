# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in local.network_rule_flat : format("%s-%s", s.res_name,s.subnet) => s }
  name = each.value.subnet
  virtual_network_name = each.value.virtual_network
  resource_group_name = each.value.resource_group
}

# Manages a ServiceBus Namespace.
resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  for_each = { for s in var.res_spec.servicebus : format("%s", s.namespace) => s }
  name = each.key
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  sku = title(lookup(each.value, "sku", "Standard"))
  capacity = title(lookup(each.value, "sku", "Standard")) == "Premium" ? lookup(each.value, "capacity", 1) : 0
  zone_redundant = title(lookup(each.value, "sku", "Standard")) == "Premium" ? lookup(each.value, "zone_redundant", true) : false
  tags = merge(var.tags,each.value.tags)
}

# Manages a Private Endpoint.
module "private_endpoint" {
  count = length(local.private_endpoint_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//private-endpoint?ref=v0.1"
  private_endpoint_spec = local.private_endpoint_flat
  resource = { for i, servicebus_namespace in azurerm_servicebus_namespace.servicebus_namespace: i => servicebus_namespace.id }
}

# Manages a ServiceBus Namespace Network Rule Set Set.
resource "azurerm_servicebus_namespace_network_rule_set" "servicebus_namespace_network_rule_set" {
  for_each = { for s in var.res_spec.servicebus : format("%s", s.namespace) => s if s.sku == "Premium" }
  namespace_name = azurerm_servicebus_namespace.servicebus_namespace[each.key].name
  resource_group_name = var.res_spec.rg[0].name
  default_action = "Deny"
  ip_rules = each.value.ip_rules
  dynamic "network_rules" {
    iterator = subnet
    for_each = { for s in local.network_rule_flat : format("%s-%s", s.res_name,s.subnet) => s if s.res_name == each.value.namespace }
    content {
      subnet_id = data.azurerm_subnet.subnet["${subnet.value.res_name}-${subnet.value.subnet}"].id
      ignore_missing_vnet_service_endpoint = subnet.value.ignore_missing_vnet_service_endpoint
    }
  }
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, servicebus_namespace in azurerm_servicebus_namespace.servicebus_namespace: i => servicebus_namespace.id }
}