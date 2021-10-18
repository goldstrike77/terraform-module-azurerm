# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  role_flat = flatten([
    for s in var.role_spec : [
      for t in var.resource : [
        for u in s.role_ass[*] : [
          for v in u.name[*] : {
            id       = t
            resource = s.name
            type     = u.type
            name     = v
            role     = u.role
          }
        ]
      ]
    ] if length(s.role_ass[*]) > 0
  ])
}