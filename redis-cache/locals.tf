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