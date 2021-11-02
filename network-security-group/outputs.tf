output "network_security_group_id" {
  value = { for i, network_security_group in azurerm_network_security_group.network_security_group: i => network_security_group.id }
}