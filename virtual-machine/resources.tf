# Manages an Availability Set for Virtual Machines.
resource "azurerm_availability_set" "availability_set" {
  for_each = { for s in var.res_spec.vm[*] : format("%s", s.collection) => s }
  name = "avail-${each.value.collection}"
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
  managed = true
  tags = merge(var.tags,each.value.tags)
}

# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in local.nic_flat : format("%s-%02d", s.res_name,s.name) => s }
  name = each.value.subnet
  virtual_network_name = each.value.virtual_network
  resource_group_name = each.value.resource_group
}

# Manages a Public IP Address.
resource "azurerm_public_ip" "public_ip" {
  for_each = { for s in local.nic_flat : format("%s-%02d", s.res_name,s.name) => s if s.public }
  name = "pip-${each.value.res_name}"
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  allocation_method = "Static"
  sku = "Standard"
  availability_zone = "No-Zone"
  tags = merge(var.tags,each.value.tags)
}

# Manages a Network Interface.
resource "azurerm_network_interface" "network_interface" {
  for_each = { for s in local.nic_flat : format("%s-%02d", s.res_name,s.name) => s }
  name = "nic-${each.key}"
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  enable_ip_forwarding = each.value.ip_forwarding
  enable_accelerated_networking = each.value.accelerated
  tags = merge(var.tags,each.value.tags)
  ip_configuration {
    name = "ip-${each.key}"
    subnet_id = data.azurerm_subnet.subnet[each.key].id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = each.value.public ? azurerm_public_ip.public_ip[each.key].id : null
  }
}

/*
# Manages a Linux Virtual Machine.
resource "azurerm_linux_virtual_machine" "linux_virtual_machine" {
  for_each = { for s in local.vm_flat : format("%s", s.res_name) => s if s.config.type == lower("linux") }
  name = lower(each.value.res_name)
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  availability_set_id = azurerm_availability_set.availability_set[each.value.collection].id
  network_interface_ids = [azurerm_network_interface.network_interface[[for i in keys(azurerm_network_interface.network_interface[*]): i if length(regexall("vmappnode01", i)) > 0]].id]
  size = each.value.config.size
  computer_name = lower(each.value.res_name)
  admin_username = lookup(each.value.config, "user", "oper")
  admin_password = lookup(each.value.config, "pass", "changeme")
  disable_password_authentication = false
  tags = merge(var.tags,each.value.tags)
  os_disk {
    name = "osdisk-${lower(each.value.res_name)}"
    caching = each.value.config.os_disk_type == "Premium_LRS" ? "None" : "ReadWrite"
    storage_account_type = lookup(each.value.config, "os_disk_type", "Standard_LRS")
  }
  source_image_reference {
    publisher = each.value.config.publisher
    offer     = each.value.config.offer
    sku       = each.value.config.sku
    version   = each.value.config.version
  }
  boot_diagnostics {}
}
*/