# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  firewall_rule_flat = flatten([
    for s in var.res_spec.redis[*] : [
      for t in s.firewall_rule[*] : {
        name = s.name
        role_name = t.name
        start = lookup(t, "start", "0.0.0.0")
        end = lookup(t, "end", "0.0.0.0")
      }
    ] if length(s.firewall_rule[*]) > 0
  ])
}

locals {
  role_flat = flatten([
    for s in var.res_spec.redis[*] : [
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
}

locals {
  private_endpoint_flat = flatten([
    for s in var.res_spec[*] : [
      for t in s.redis[*] : [
        for u in t.private_endpoint[*] : {
          rg = s.rg[0].name
          location = t.location
          res_name = t.name
          network_interface = lookup(u, "network_interface", null)
          private_dns_zone = lookup(u, "private_dns_zone", null)
          subresource = ["redisCache"]
        }
      ] if length(t.private_endpoint[*]) > 0
    ]
  ])
}