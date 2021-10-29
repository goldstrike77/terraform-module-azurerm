# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  role_flat = flatten([
    for s in var.rg_spec[*] : [
      for t in s.role_ass[*] : [
        for u in t.name[*] : {
          res_name  = s.name
          tags      = s.tags
          location  = s.location
          type      = t.type
          role_name = u
          role      = t.role
        }
      ]
    ] if length(s.role_ass[*]) > 0
  ])
}