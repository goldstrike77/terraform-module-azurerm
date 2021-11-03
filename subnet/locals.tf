# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  snet_flat = flatten([
    for s in var.res_spec.vnet[*] : [
      for t in s.subnet[*] : {
        vnet_name = s.name
        snet_name = t.name
        address_prefixes = t.address_prefixes
        enforce_private_link_endpoint_network_policies = lookup(t, "enforce_private_link_endpoint_network_policies", false)
        enforce_private_link_service_network_policies = lookup(t, "enforce_private_link_service_network_policies", false)
        service_endpoints = lookup(t, "service_endpoints", [])
        service_delegation_name = lookup(t, "service_delegation_name", null)
      }
    ]
  ])
}

locals {
  role_flat = flatten([
    for s in var.res_spec.vnet[*] : [
      for t in s.subnet[*] : [
        for u in t.role_ass[*] : [
          for v in u.name[*] : {
            res_name = t.name
            type = u.type
            role_name = v
            role = u.role
          }
        ]
      ] if length(t.role_ass[*]) > 0
    ]
  ])
}

locals {
  nsg_flat = flatten([
    for s in var.res_spec.vnet[*] : [
      for t in s.subnet[*] : {
        location = s.location
        subnet_name = t.name
        tags = t.tags
      } if length(t.security_group_rules[*]) > 0
    ]
  ])
}

locals {
  nsgr_flat = flatten([
    for s in var.res_spec.vnet[*] : [
      for t in s.subnet[*] : [
        for u in t.security_group_rules[*] : {
          location = s.location
          subnet_name = t.name
          tags = t.tags
          nsrg_name = u.name
          direction = u.direction
          access = u.access
          priority = u.priority
          protocol = u.protocol
          source_address_prefix = lookup(u, "source_address_prefix", null)
          source_address_prefixes = lookup(u, "source_address_prefixes", null)
          destination_address_prefix = lookup(u, "destination_address_prefix", null)
          destination_address_prefixes = lookup(u, "destination_address_prefixes", null)
          source_port_range = lookup(u, "source_port_range", null)
          source_port_ranges = lookup(u, "source_port_ranges", null)
          destination_port_range = lookup(u, "destination_port_range", null)
          destination_port_ranges = lookup(u, "destination_port_ranges", null)
        }
      ] if length(t.security_group_rules[*]) > 0
    ]
  ])
}