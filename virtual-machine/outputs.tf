output "network_interface_id" {
  value = { for i, network_interface in azurerm_network_interface.network_interface: i => network_interface.id }
}

output "linux_virtual_machine_id" {
  value = { for i, linux_virtual_machine in azurerm_linux_virtual_machine.linux_virtual_machine: i => regex(".*/(.*)", linux_virtual_machine.id) }
}

output "windows_virtual_machine_id" {
  value = { for i, windows_virtual_machine in azurerm_windows_virtual_machine.windows_virtual_machine: i => regex(".*/(.*)", windows_virtual_machine.id) }
}