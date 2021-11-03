# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in var.res_spec.bastion : format("%s", s.name) => s }
  name = each.value.network.subnet
  virtual_network_name = each.value.network.virtual_network
  resource_group_name = each.value.network.resource_group
}

# Manages a Public IP Address.
resource "azurerm_public_ip" "public_ip" {
  for_each = { for s in var.res_spec.bastion : format("%s", s.name) => s }
  name = "pip-${each.value.name}"
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  allocation_method = "Static"
  sku = "Standard"
  availability_zone = "No-Zone"
  tags = merge(var.tags,each.value.tags)
}

# Manages a Bastion Host.
resource "azurerm_bastion_host" "bastion_host" {
  for_each = { for s in var.res_spec.bastion : format("%s", s.name) => s }  
  name = each.value.name
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  tags = merge(var.tags,each.value.tags)
  ip_configuration {
    name = "configuration"
    subnet_id = data.azurerm_subnet.subnet[each.value.name].id
    public_ip_address_id = azurerm_public_ip.public_ip[each.value.name].id
  }
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, bastion_host in azurerm_bastion_host.bastion_host: i => bastion_host.id }
}