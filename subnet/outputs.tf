output "subnet_id" {
  value = { for i, subnet in azurerm_subnet.subnet: i => subnet.id }
}