# Manages a Resource Group.
resource "azurerm_resource_group" "resource_group" {
  for_each = { for s in local.rg_flat : format("%s", s.name) => s }
  name     = each.value.name
  location = each.value.location
  tags     = merge(var.tags,each.value.tags)
}