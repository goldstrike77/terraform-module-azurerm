# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  rg_flat = flatten([
    for s in var.rg_spec[*] : {
      name     = s.name
      tags     = s.tags
      location = s.location
    }
  ])
}