# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  lb_flat = flatten([
    for s in var.res_spec.lb[*] : [
      for t in s.network : {
        lb_name = s.component
        location = s.location
        tags = s.tags
        nic_name = t.name
        subnet = t.subnet
        virtual_network = t.virtual_network
        resource_group = t.resource_group
        lb_public = lookup(t, "lb_public", false)
      } if length(t.lb_spec[*]) > 0
    ]
  ])
}

locals {
  nic_flat = flatten([
    for s in var.res_spec.lb[*] : [
      for t in s.network : [
        for u in s.name : {
          res_name = u
          lb_name = s.component
          nic_name = t.name
        }
      ] if length(t.lb_spec[*]) > 0
    ]
  ])
}

locals {
  port_flat = flatten([
    for s in var.res_spec.lb[*] : [
      for t in s.network : [
        for u in t.lb_spec : {
          lb_name = s.component
          nic_name = t.name
          lb_public = lookup(t, "lb_public", false)
          nat = lookup(u, "nat", false)
          protocol = lower(u.protocol)
          frontend_port = u.frontend_port
          backend_port = u.backend_port
          probe_port = u.probe_port
          probe_protocol = lower(lookup(u, "probe_protocol", "tcp"))
          probe_path = lookup(u, "probe_path", "/")
          probe_interval = lookup(u, "probe_interval", "15")
          probe_number = lookup(u, "probe_number", 2)
        }
      ] if length(t.lb_spec[*]) > 0
    ]
  ])
}