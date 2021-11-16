# Manages an Azure Container Registry.
resource "azurerm_container_registry" "container_registry" {
  for_each = { for s in var.res_spec.acr : format("%s", s.name) => s }
  name = each.key
  resource_group_name = var.res_spec.rg[0].name
  location = each.value.location
  sku = lookup(each.value, "sku", "Standard")
  admin_enabled = lookup(each.value, "admin_enabled", true)
  public_network_access_enabled = lookup(each.value, "public", false)
  tags = merge(var.tags,each.value.tags)
  dynamic "identity" {
    for_each = length(each.value.identity) == 0 ? [] : [1]
    content {
      type = lookup(each.value.identity, "type", "SystemAssigned")
      identity_ids = lookup(each.value.identity, "user_assigned_identity_id", null)
    }
  }
  dynamic "georeplications" {
    for_each = length(each.value.georeplications) == 0 ? [] : [1]
    content {
      location = each.value.georeplications.location
      zone_redundancy_enabled = lookup(each.value.georeplications, "zone_redundancy", false)
      tags = merge(var.tags,each.value.tags)
    }
  }
  dynamic "network_rule_set" {
    for_each = length(local.ip_rule_flat[*]) == 0 ? [] : [1]
    content {
      default_action = "Deny"
      ip_rule = [ for ip in local.ip_rule_flat : { action = "Allow", ip_range = ip.ip_range } if ip.res_name == each.value.name ]
    }
  }
}

# Manages a Private Endpoint.
module "private_endpoint" {
  count = length(local.private_endpoint_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//private-endpoint?ref=v0.1"
  private_endpoint_spec = local.private_endpoint_flat
  resource = { for i, container_registry in azurerm_container_registry.container_registry: i => container_registry.id }
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, container_registry in azurerm_container_registry.container_registry: i => container_registry.id }
}