# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  role_flat = flatten([
    for s in var.res_spec.sa[*] : [
      for t in s.role_assignment[*] : [
        for u in t.name[*] : {
          res_name = s.name
          tags = s.tags
          location = s.location
          type = t.type
          role_name = u
          role = t.role
        }
      ]
    ] if length(s.role_assignment[*]) > 0
  ])
  private_endpoint_flat = flatten([
    for s in var.res_spec[*] : [
      for t in s.sa[*] : [
        for u in t.private_endpoint[*] : [
          for v in ["blob","table","queue","file","web","dfs"] : {
            rg = s.rg[0].name
            location = t.location
            res_name = "${t.name}.${v}"
            network_interface = lookup(u, "network_interface", null)
            private_dns_zone = {
              resource_group = u.private_dns_zone.resource_group,
              name = "privatelink.${v}.${u.private_dns_zone.name}"
            }
            subresource = [v]
          }
        ]
      ] if length(t.private_endpoint) > 0
    ]
  ])
  network_rule_flat = flatten([
    for s in var.res_spec.sa[*] : [
      for t in s.network_rule : {
        res_name = s.name
        subnet = t.subnet
        virtual_network = t.virtual_network
        resource_group = t.resource_group
        ignore_missing_virtual_network_service_endpoint = lookup(t, "ignore_missing_virtual_network_service_endpoint", false)
      }
    ] if length(s.network_rule[*]) > 0
  ])
  ip_rule_flat = flatten([
    for s in var.res_spec.sa[*] : [
      for t in s.ip_rule : {
        res_name = s.name
        ip_mask = t.ip_mask
      }
     ] if length(s.ip_rule[*]) > 0
  ])
}