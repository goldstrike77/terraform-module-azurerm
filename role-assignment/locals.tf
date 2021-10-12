# 将通过变量传入的角色属性映射投影到每个变量都有单独元素的集合。
locals {
  role_flat = flatten([
    for s in var.role_spec.role_ass[*] : [
      for k in s.name : {
        type = s.type
        name = k
        role = s.role
      }
    ]
  ])
}