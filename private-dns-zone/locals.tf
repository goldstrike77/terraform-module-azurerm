# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  vnet_flat = flatten([
    for s in var.res_spec.private_dns_zone[*] : [
      for t in s.link[*] : {
        rg = t.rg
        vnet = t.vnet
      }
    ] if length(s.link[*]) > 0
  ])
}

locals {
  dns_flat = flatten([
    for s in var.res_spec.private_dns_zone[*] : [
      for t in s.link[*] : {
        name = s.name
        tags = lookup(s, "tags", null)
        registration = lookup(s, "registration", false)
        rg = t.rg
        vnet = t.vnet
      }
    ] if length(s.link[*]) > 0
  ])
}