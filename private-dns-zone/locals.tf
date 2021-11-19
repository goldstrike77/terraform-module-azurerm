# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  vnet_flat = flatten([
    for s in var.res_spec.private_dns_zone[*] : [
      for t in s.link[*] : {
        resource_group = t.resource_group
        virtual_network = t.virtual_network
      }
    ] if length(s.link[*]) > 0
  ])
  dns_flat_vnet = flatten([
    for s in var.res_spec.private_dns_zone[*] : [
      for t in s.link[*] : [
        for u in s.name[*] : {
          name = u
          tags = lookup(s, "tags", null)
          registration = lookup(s, "registration", false)
          resource_group = t.resource_group
          virtual_network = t.virtual_network
        }
      ]
    ] if length(s.link[*]) > 0
  ])
  dns_flat = flatten([
    for s in var.res_spec.private_dns_zone[*] : [
      for t in s.name[*] : {
        name = t
        tags = lookup(s, "tags", null)
      }
    ] if length(s.link[*]) > 0
  ])
}