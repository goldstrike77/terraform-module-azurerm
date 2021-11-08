/*
output "subnet_id" {
  value = { for i, subnet in data.azurerm_subnet.subnet: i => subnet.id if length(regexall("vmappnode01", i)) > 0 }
}
*/

output "subnet_id" {
  value = [for i in keys(azurerm_network_interface.network_interface): i if length(regexall("vmappnode01", i)) > 0]
}