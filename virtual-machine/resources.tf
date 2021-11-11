# Manages an Availability Set for Virtual Machines.
resource "azurerm_availability_set" "availability_set" {
  for_each = { for s in var.res_spec.vm[*] : format("%s", s.component) => s }
  name = "avail-${each.value.component}"
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
  managed = true
  tags = merge(var.tags,each.value.tags)
}

# Manages an Azure Backup VM Backup Policy.
resource "azurerm_backup_policy_vm" "backup_policy_vm" {
  for_each = { for s in var.res_spec.rsv : format("%s", s.name) => s }
  name = "policy-${each.key}-vm"
  resource_group_name = var.res_spec.rg[0].name
  recovery_vault_name = each.key
  timezone = lookup(each.value.policy, "timezone", "China Standard Time")
  backup {
    frequency = title(lookup(each.value.policy, "frequency", "daily"))
    time = lookup(each.value.policy, "time", "23:00")
  }
  retention_daily {
    count = lookup(each.value.policy, "count", 7)
  }
}

# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in local.nic_flat : format("%s-%d", s.res_name,s.nic_name) => s }
  name = each.value.subnet
  virtual_network_name = each.value.virtual_network
  resource_group_name = each.value.resource_group
}

# Manages a Public IP Address.
resource "azurerm_public_ip" "public_ip" {
  for_each = { for s in local.nic_flat : format("%s-%d", s.res_name,s.nic_name) => s if s.public }
  name = "pip-vm-${each.value.res_name}"
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  allocation_method = "Static"
  sku = "Standard"
  availability_zone = "No-Zone"
  tags = merge(var.tags,each.value.tags)
}

# Manages a Network Interface.
resource "azurerm_network_interface" "network_interface" {
  for_each = { for s in local.nic_flat : format("%s-%d", s.res_name,s.nic_name) => s }
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

# Manages a managed disk.
resource "azurerm_managed_disk" "managed_disk" {
  for_each = { for s in local.disk_flat : format("%s-%d", s.res_name,s.disk_name) => s }
  name = "disk-${each.key}"
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  storage_account_type = each.value.type
  create_option = "Empty"
  disk_size_gb = each.value.size
  tags = merge(var.tags,each.value.tags)
}

# Manages a Linux Virtual Machine.
resource "azurerm_linux_virtual_machine" "linux_virtual_machine" {
  for_each = { for s in local.vm_flat : format("%s", s.res_name) => s if s.config.type == lower("linux") }
  name = lower(each.value.res_name)
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  availability_set_id = azurerm_availability_set.availability_set[each.value.component].id
  network_interface_ids = [for i in values(azurerm_network_interface.network_interface): i.id if length(regexall(each.key, i.id)) > 0]
  size = each.value.config.size
  computer_name = lower(each.value.res_name)
  admin_username = lookup(each.value.config, "user", "oper")
  admin_password = lookup(each.value.config, "pass", "Changeme@Changeit")
  disable_password_authentication = false
  tags = merge(var.tags,each.value.tags)
  os_disk {
    name = "osdisk-${lower(each.value.res_name)}"
    caching = each.value.config.os_disk_type == "Premium_LRS" ? "None" : "ReadWrite"
    storage_account_type = lookup(each.value.config, "os_disk_type", "Standard_LRS")
  }
  source_image_reference {
    publisher = each.value.config.publisher
    offer = each.value.config.offer
    sku = each.value.config.sku
    version = each.value.config.version
  }
  boot_diagnostics {}
}

# Manages attaching a Disk to a Linux Virtual Machine.
resource "azurerm_virtual_machine_data_disk_attachment" "linux_virtual_machine_data_disk_attachment" {
  for_each = { for s in local.disk_flat : format("%s-%d", s.res_name,s.disk_name) => s if s.config.type == lower("linux") }
  managed_disk_id = azurerm_managed_disk.managed_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.linux_virtual_machine[each.value.res_name].id
  lun = each.value.disk_name
  caching = each.value.type == "Premium_LRS" ? "None" : "ReadWrite"
}

# Manages a Linux Virtual Machine Extension to provide post deployment configuration and run automated tasks.
resource "azurerm_virtual_machine_extension" "linux_virtual_machine_extension" {
  for_each = { for s in local.extension_flat : format("%s", s.name) => s if s.config.type == lower("linux") }
  name = each.value.name
  virtual_machine_id = azurerm_linux_virtual_machine.linux_virtual_machine[each.value.res_name].id
  publisher = each.value.publisher
  type = each.value.type
  type_handler_version = each.value.handler_version
  tags = merge(var.tags,each.value.tags)
  settings = jsonencode(each.value.settings)
}

# Manages Azure Backup for an Linux Virtual Machine.
resource "azurerm_backup_protected_vm" "linux_backup_protected_vm" {
  for_each = { for s in local.vm_flat : format("%s", s.res_name) => s if s.config.type == lower("linux") && s.config.backup }
  resource_group_name = var.res_spec.rg[0].name
  recovery_vault_name = var.res_spec.rsv[0].name
  source_vm_id = azurerm_linux_virtual_machine.linux_virtual_machine[each.key].id
  backup_policy_id = azurerm_backup_policy_vm.backup_policy_vm[var.res_spec.rsv[0].name].id
}

# Manages a Windows Virtual Machine.
resource "azurerm_windows_virtual_machine" "windows_virtual_machine" {
  for_each = { for s in local.vm_flat : format("%s", s.res_name) => s if s.config.type == lower("windows") }
  name = lower(each.value.res_name)
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  availability_set_id = azurerm_availability_set.availability_set[each.value.component].id
  network_interface_ids = [for i in values(azurerm_network_interface.network_interface): i.id if length(regexall(each.key, i.id)) > 0]
  size = each.value.config.size
  computer_name = lower(each.value.res_name)
  admin_username = lookup(each.value.config, "user", "oper")
  admin_password = lookup(each.value.config, "pass", "Changeme@Changeit")
  tags = merge(var.tags,each.value.tags)
  os_disk {
    name = "osdisk-${lower(each.value.res_name)}"
    caching = each.value.config.os_disk_type == "Premium_LRS" ? "None" : "ReadWrite"
    storage_account_type = lookup(each.value.config, "os_disk_type", "Standard_LRS")
  }
  source_image_reference {
    publisher = each.value.config.publisher
    offer = each.value.config.offer
    sku = each.value.config.sku
    version = each.value.config.version
  }
  boot_diagnostics {}
}

# Manages attaching a Disk to a Windows Virtual Machine.
resource "azurerm_virtual_machine_data_disk_attachment" "windows_virtual_machine_data_disk_attachment" {
  for_each = { for s in local.disk_flat : format("%s-%d", s.res_name,s.disk_name) => s if s.config.type == lower("windows") }
  managed_disk_id = azurerm_managed_disk.managed_disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.windows_virtual_machine[each.value.res_name].id
  lun = each.value.disk_name
  caching = each.value.type == "Premium_LRS" ? "None" : "ReadWrite"
}

# Manages a Windows Virtual Machine Extension to provide post deployment configuration and run automated tasks.
resource "azurerm_virtual_machine_extension" "windows_virtual_machine_extension" {
  for_each = { for s in local.extension_flat : format("%s", s.name) => s if s.config.type == lower("windows") }
  name = each.value.name
  virtual_machine_id = azurerm_windows_virtual_machine.windows_virtual_machine[each.value.res_name].id
  publisher = each.value.publisher
  type = each.value.type
  type_handler_version = each.value.handler_version
  tags = merge(var.tags,each.value.tags)
  settings = jsonencode(each.value.settings)
}

# Manages Azure Backup for an Windows Virtual Machine.
resource "azurerm_backup_protected_vm" "windows_backup_protected_vm" {
  for_each = { for s in local.vm_flat : format("%s", s.res_name) => s if s.config.type == lower("windows") && s.config.backup }
  resource_group_name = var.res_spec.rg[0].name
  recovery_vault_name = var.res_spec.rsv[0].name
  source_vm_id = azurerm_windows_virtual_machine.windows_virtual_machine[each.key].id
  backup_policy_id = azurerm_backup_policy_vm.backup_policy_vm[var.res_spec.rsv[0].name].id
}

# Assigns a given Principal (User, Group or App) to a given Role for an Linux Virtual Machine..
module "linux_role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, linux_virtual_machine in azurerm_linux_virtual_machine.linux_virtual_machine: i => linux_virtual_machine.id }
}

# Assigns a given Principal (User, Group or App) to a given Role for an Windows Virtual Machine..
module "windows_role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, windows_virtual_machine in azurerm_windows_virtual_machine.windows_virtual_machine: i => windows_virtual_machine.id }
}

# Manages a Load Balancer Resource.
module "lb" {
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//lb?ref=v0.1"
  tags = var.tags
  res_spec = zipmap(["rg", "lb"], [var.res_spec.rg, var.res_spec.vm])
  depends_on = [azurerm_network_interface.network_interface]
}