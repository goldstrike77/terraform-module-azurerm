# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each             = { for s in local.lb_flat : format("%s-%d", s.lb_name, s.nic_name) => s }
  name                 = each.value.subnet
  virtual_network_name = each.value.virtual_network
  resource_group_name  = each.value.resource_group
}

# Access information about an existing Network Interface.
data "azurerm_network_interface" "network_interface" {
  for_each            = { for s in local.nic_flat : format("%s-%d", s.res_name, s.nic_name) => s }
  name                = "nic-${each.value.res_name}-${each.value.nic_name}"
  resource_group_name = var.res_spec.rg[0].name
}

# Manages a Public IP Address.
resource "azurerm_public_ip" "public_ip" {
  for_each            = { for s in local.lb_flat : format("%s-%d", s.lb_name, s.nic_name) => s if s.lb_public }
  name                = "pip-lb-${each.key}"
  location            = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = each.value.zones
  domain_name_label   = lookup(each.value, "domain_name_label", null)
  tags                = merge(var.tags, each.value.tags)
}

# Manages a Load Balancer Resource.
resource "azurerm_lb" "lb" {
  for_each            = { for s in local.lb_flat : format("%s-%d", s.lb_name, s.nic_name) => s }
  name                = lookup(each.value, "lb_public", false) ? "lbe-${each.key}" : "lbi-${each.key}"
  location            = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  sku                 = "Standard"
  tags                = merge(var.tags, each.value.tags)

  frontend_ip_configuration {
    zones                         = each.value.zones
    name                          = lookup(each.value, "lb_public", false) ? "pip-lb-${each.key}" : "ip-lb-${each.key}"
    public_ip_address_id          = lookup(each.value, "lb_public", false) ? azurerm_public_ip.public_ip[each.key].id : null
    subnet_id                     = lookup(each.value, "lb_public", false) ? null : data.azurerm_subnet.subnet[each.key].id
    private_ip_address_allocation = lookup(each.value, "lb_public", false) ? null : "Dynamic"
  }
}

# Manages a Load Balancer Backend Address Pool.
resource "azurerm_lb_backend_address_pool" "lb_backend_address_pool" {
  for_each        = { for s in local.lb_flat : format("%s-%d", s.lb_name, s.nic_name) => s }
  loadbalancer_id = azurerm_lb.lb[each.key].id
  name            = "pool-${each.key}"
}

# Manages the association between a Network Interface and a Load Balancer's Backend Address Pool.
resource "azurerm_network_interface_backend_address_pool_association" "network_interface_backend_address_pool_association" {
  for_each                = { for s in local.nic_flat : format("%s-%d", s.res_name, s.nic_name) => s }
  network_interface_id    = data.azurerm_network_interface.network_interface[each.key].id
  ip_configuration_name   = "ip-${each.value.res_name}-${each.value.nic_name}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${each.value.lb_name}-${each.value.nic_name}"].id
}


# Manages a LoadBalancer Probe Resource.
resource "azurerm_lb_probe" "lb_probe" {
  for_each            = { for s in local.port_flat : format("%s-%d-%s", s.lb_name, s.nic_name, s.backend_port) => s }
  loadbalancer_id     = azurerm_lb.lb["${each.value.lb_name}-${each.value.nic_name}"].id
  name                = "probe-${each.value.probe_protocol}-${each.value.probe_port}"
  protocol            = each.value.probe_protocol
  port                = each.value.probe_port
  request_path        = each.value.probe_protocol == "tcp" ? null : each.value.probe_path
  interval_in_seconds = each.value.probe_interval
  number_of_probes    = each.value.probe_number
}

# Manages a Load Balancer Rule.
resource "azurerm_lb_rule" "lb_rule" {
  for_each                       = { for s in local.port_flat : format("%s-%d-%s", s.lb_name, s.nic_name, s.backend_port) => s if !s.nat }
  loadbalancer_id                = azurerm_lb.lb["${each.value.lb_name}-${each.value.nic_name}"].id
  name                           = "rule-${each.value.protocol}-${each.value.backend_port}"
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  probe_id                       = azurerm_lb_probe.lb_probe[each.key].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${each.value.lb_name}-${each.value.nic_name}"].id]
  frontend_ip_configuration_name = lookup(each.value, "lb_public", false) ? "pip-lb-${each.value.lb_name}-${each.value.nic_name}" : "ip-lb-${each.value.lb_name}-${each.value.nic_name}"
}

# Manages a Load Balancer NAT Rule.
resource "azurerm_lb_nat_rule" "lb_nat_rule" {
  for_each                       = { for s in local.port_flat : format("%s-%d-%s", s.lb_name, s.nic_name, s.backend_port) => s if s.nat }
  resource_group_name            = var.res_spec.rg[0].name
  loadbalancer_id                = azurerm_lb.lb["${each.value.lb_name}-${each.value.nic_name}"].id
  name                           = "nat-${each.value.protocol}-${each.value.backend_port}"
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = lookup(each.value, "lb_public", false) ? "pip-lb-${each.value.lb_name}-${each.value.nic_name}" : "ip-lb-${each.value.lb_name}-${each.value.nic_name}"
}
