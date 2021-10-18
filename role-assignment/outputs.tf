output "azurerm_role_assignment" {
  value = { for i, role_assignment in local.role_flat: i => role_assignment }
}