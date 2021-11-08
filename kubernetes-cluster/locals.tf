# 将通过变量传入的元数据映射投影到每个变量都有单独元素的集合。
locals {
  pool_flat = flatten([
    for s in var.res_spec.aks[*] : [
      for t in s.node_pool[*] : {
        cluster_name = s.name
        plugin = s.network_profile.plugin
        tags = s.tags
        kubelet_config = s.kubelet_config
        linux_os_config = s.linux_os_config
        name = t.name
        os_type = lookup(t, "os_type", "Linux")
        vm_size = lookup(t, "vm_size", "Standard_B2s")
        os_disk_size_gb = lookup(t, "os_disk_size_gb", "127")
        ultra_ssd = lookup(t, "ultra_ssd", false)
        auto_scaling = lookup(t, "auto_scaling", false)
        node_count = t.auto_scaling ? null : lookup(t, "node_count", 2)
        max_count = t.auto_scaling ? lookup(t, "max_count", 1) : null
        min_count = t.auto_scaling ? lookup(t, "min_count", 0) : null
        max_surge = lookup(t, "max_surge", null)
        max_pods = lookup(t, "max_pods", 30)
        host_encryption = lookup(t, "host_encryption", false)
        labels = lookup(t, "labels", null)
      }
    ] if length(s.node_pool[*]) > 0
  ])
}

locals {
  role_flat = flatten([
    for s in var.res_spec.rg[*] : [
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