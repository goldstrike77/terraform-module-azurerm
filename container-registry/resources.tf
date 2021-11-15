# Manages an Azure Container Registry.
resource "azurerm_container_registry" "container_registry" {
  for_each = { for s in var.res_spec.acr : format("%s", s.name) => s }
  name = each.key
  resource_group_name = var.res_spec.rg[0].name
  location = each.value.location
  sku = lookup(each.value, "sku", "Standard")
  admin_enabled = lookup(each.value, "admin_enabled", false)
  public_network_access_enabled = lookup(each.value, "public", false)
  tags = merge(var.tags,each.value.tags)
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, container_registry in azurerm_container_registry.container_registry: i => container_registry.id }
}