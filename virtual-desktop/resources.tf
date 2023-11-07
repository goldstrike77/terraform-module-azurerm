# Manages a Virtual Desktop Host Pool.
resource "azurerm_virtual_desktop_host_pool" "virtual_desktop_host_pool" {
  location                 = var.res_spec.virtual_desktop.location
  resource_group_name      = var.res_spec.rg[0].name
  name                     = var.res_spec.virtual_desktop.host_pool.name
  type                     = lookup(var.res_spec.virtual_desktop.host_pool, "type", "Pooled")
  load_balancer_type       = lower(var.res_spec.virtual_desktop.host_pool.type) == "personal" ? "Persistent" : lookup(var.res_spec.virtual_desktop.host_pool, "load_balancer_type", "BreadthFirst")
  validate_environment     = lookup(var.res_spec.virtual_desktop.host_pool, "validate_environment", false)
  start_vm_on_connect      = lookup(var.res_spec.virtual_desktop.host_pool, "start_vm_on_connect", false)
  custom_rdp_properties    = var.res_spec.virtual_desktop.host_pool.custom_rdp_properties
  maximum_sessions_allowed = lower(var.res_spec.virtual_desktop.host_pool.type) == "pooled" ? lookup(var.res_spec.virtual_desktop.host_pool, "maximum_sessions_allowed", 50) : null
  preferred_app_group_type = lookup(var.res_spec.virtual_desktop.host_pool, "preferred_app_group_type", "Desktop")
  tags                     = merge(var.tags, var.res_spec.virtual_desktop.tags)
  dynamic "scheduled_agent_updates" {
    for_each = length(var.res_spec.virtual_desktop.host_pool.scheduled_agent_updates) == 0 ? [] : [1]
    content {
      enabled                   = lookup(var.res_spec.virtual_desktop.host_pool.scheduled_agent_updates, "enabled", true)
      timezone                  = lookup(var.res_spec.virtual_desktop.host_pool.scheduled_agent_updates, "timezone", "UTC")
      use_session_host_timezone = lookup(var.res_spec.virtual_desktop.host_pool.scheduled_agent_updates, "use_session_host_timezone", false)
      schedule {
        day_of_week = lookup(var.res_spec.virtual_desktop.host_pool.scheduled_agent_updates.schedule, "day_of_week", "Sunday")
        hour_of_day = lookup(var.res_spec.virtual_desktop.host_pool.scheduled_agent_updates.schedule, "hour_of_day", 0)
      }
    }
  }
}

# Manages a rotating time resource.
resource "time_rotating" "rotating" {
  rotation_days = var.res_spec.virtual_desktop.host_pool.expiration_date
}

# Manages the Registration Info for a Virtual Desktop Host Pool.
resource "azurerm_virtual_desktop_host_pool_registration_info" "virtual_desktop_host_pool_registration_info" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.virtual_desktop_host_pool.id
  expiration_date = time_rotating.rotating.rotation_rfc3339
}

# Manages a Virtual Desktop Workspace.
resource "azurerm_virtual_desktop_workspace" "virtual_desktop_workspace" {
  name                          = var.res_spec.virtual_desktop.workspace.name
  resource_group_name           = var.res_spec.rg[0].name
  location                      = var.res_spec.virtual_desktop.location
  public_network_access_enabled = lookup(var.res_spec.virtual_desktop.workspace, "public_network_access_enabled", true)
  tags                          = merge(var.tags, var.res_spec.virtual_desktop.tags)
}

# Manages a Virtual Desktop Application Group.
resource "azurerm_virtual_desktop_application_group" "virtual_desktop_application_group" {
  name                = var.res_spec.virtual_desktop.application_group.name
  resource_group_name = var.res_spec.rg[0].name
  location            = var.res_spec.virtual_desktop.location
  type                = lookup(var.res_spec.virtual_desktop.application_group, "type", "Desktop")
  host_pool_id        = azurerm_virtual_desktop_host_pool.virtual_desktop_host_pool.id
  tags                = merge(var.tags, var.res_spec.virtual_desktop.tags)
}

# Manages a Virtual Desktop Workspace Application Group Association.
resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  workspace_id         = azurerm_virtual_desktop_workspace.virtual_desktop_workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.virtual_desktop_application_group.id
}

# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  name                 = var.res_spec.virtual_desktop.host_pool.subnet.name
  virtual_network_name = var.res_spec.virtual_desktop.host_pool.subnet.vnet_name
  resource_group_name  = var.res_spec.virtual_desktop.host_pool.subnet.rg_name
}

# Manages a Network Interface.
resource "azurerm_network_interface" "network_interface" {
  count               = var.res_spec.virtual_desktop.host_pool.number
  name                = "nic-${var.res_spec.virtual_desktop.host_pool.name}-${count.index}"
  location            = var.res_spec.virtual_desktop.location
  resource_group_name = var.res_spec.rg[0].name
  tags                = merge(var.tags, var.res_spec.virtual_desktop.tags)
  ip_configuration {
    name                          = "avd-ipconf"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Random Password Generator.
resource "random_password" "password" {
  length      = 14
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

# Manages a Windows Virtual Machine.
resource "azurerm_windows_virtual_machine" "windows_virtual_machine" {
  count                 = var.res_spec.virtual_desktop.host_pool.number
  name                  = "vm-avd-${count.index}"
  location              = var.res_spec.virtual_desktop.location
  resource_group_name   = var.res_spec.rg[0].name
  size                  = lookup(var.res_spec.virtual_desktop.host_pool, "size", "Standard_B2s")
  computer_name         = "vm-avd-${count.index}"
  license_type          = lookup(var.res_spec.virtual_desktop.host_pool, "license_type", "Windows_Client")
  admin_username        = lookup(var.res_spec.virtual_desktop.host_pool, "admin_username", "avdadmin")
  admin_password        = random_password.password.result
  network_interface_ids = [azurerm_network_interface.network_interface[count.index].id]
  tags                  = merge(var.tags, var.res_spec.virtual_desktop.tags)
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = lookup(var.res_spec.virtual_desktop.host_pool, "storage_account_type", "Standard_LRS")
  }
  source_image_reference {
    publisher = lookup(var.res_spec.virtual_desktop.host_pool, "publisher", "MicrosoftWindowsDesktop")
    offer     = lookup(var.res_spec.virtual_desktop.host_pool, "offer", "windows-11")
    sku       = lookup(var.res_spec.virtual_desktop.host_pool, "sku", "win11-21h2-avd")
    version   = lookup(var.res_spec.virtual_desktop.host_pool, "version", "latest")
  }
}
