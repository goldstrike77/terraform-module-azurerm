# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  vm_flat = flatten([
    for s in var.res_spec.vm[*] : [
      for t in s.name : {
        res_name = t
        tags = lookup(s, "tags", null)
        collection = s.collection
        location = s.location
        config = s.config
      }
    ]
  ])
}

locals {
  disk_flat = flatten([
    for s in var.res_spec.vm[*] : [
      for t in s.name : [
        for u in s.data_disk : {
          res_name = t
          location = s.location
          tags = s.tags
          name = u.name
          config = s.config
          type = lookup(u, "type", "Standard_LRS")
          size = lookup(u, "size", 10)
        }
      ]
    ] if length(s.data_disk[*]) > 0
  ])
}

locals {
  nic_flat = flatten([
    for s in var.res_spec.vm[*] : [
      for t in s.name : [
        for u in s.network : {
          res_name = t
          location = s.location
          tags = s.tags
          ip_forwarding = lookup(u, "ip_forwarding", false)
          accelerated = lookup(u, "accelerated", false)
          public = lookup(u, "public", false)
          name = u.name
          subnet = u.subnet
          virtual_network = u.virtual_network
          resource_group = u.resource_group
        }
      ]
    ]
  ])
}

locals {
  role_flat = flatten([
    for s in var.res_spec.vm[*] : [
      for t in s.role_assignment[*] : [
        for u in t.name[*] : [
          for v in s.name[*] : {
            res_name = v
            tags = s.tags
            location = s.location
            type = t.type
            role_name = u
            role = t.role
          }
        ]
      ]
    ] if length(s.role_assignment[*]) > 0
  ])
}

locals {
  extension_flat = flatten([
    for s in var.res_spec.vm[*] : [
      for t in s.name : [
        for u in s.extension : {
          res_name = t
          config = s.config
          name = u.name
          tags = lookup(s, "tags", null)
          publisher = u.publisher
          type = u.type
          handler_version = u.handler_version
          settings = lookup(u, "settings", null)
        }
      ]
    ] if length(s.extension[*]) > 0
  ])
}