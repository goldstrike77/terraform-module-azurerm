# Manages a Resource Group.
resource "azurerm_resource_group" "resource_group" {
  name     = var.rg_flat.name
  location = var.env.location
  tags     = var.tags
}
