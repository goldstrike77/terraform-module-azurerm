output "azurerm_role_assignment" {
  value = { for i, role_assignment in var.role_spec: i => role_assignment }
}