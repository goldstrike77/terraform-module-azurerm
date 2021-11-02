# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  role_flat = flatten([
    for s in var.res_spec.subnet[*] : [
      for t in s.role_ass[*] : [
        for u in t.name[*] : {
          res_name  = s.name
          type      = t.type
          role_name = u
          role      = t.role
        }
      ]
    ] if length(s.role_ass[*]) > 0
  ])
}

locals {
  nsgr_flat = flatten([
    for s in var.res_spec.subnet[*] : [
      for t in s.security_group_rules[*] : {
        res_name                     = s.name
        tags                         = s.tags
        name                         = t.name
        direction                    = t.direction
        access                       = t.access
        priority                     = t.priority
        protocol                     = t.protocol
        source_address_prefix        = lookup(t, "source_address_prefix", null)
        source_address_prefixes      = lookup(t, "source_address_prefixes", null)
        destination_address_prefix   = lookup(t, "destination_address_prefix", null)
        destination_address_prefixes = lookup(t, "destination_address_prefixes", null)
        source_port_range            = lookup(t, "source_port_range", null)
        source_port_ranges           = lookup(t, "source_port_ranges", null)
        destination_port_range       = lookup(t, "destination_port_range", null)
        destination_port_ranges      = lookup(t, "destination_port_ranges", null)
      }
    ] if length(s.security_group_rules[*]) > 0
  ])
}