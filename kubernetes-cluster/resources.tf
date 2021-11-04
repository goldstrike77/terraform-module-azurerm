# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in var.res_spec.aks : format("%s", s.name) => s if s.network_profile.plugin == "azure" }
  name = each.value.network_profile.subnet
  virtual_network_name = each.value.network_profile.virtual_network
  resource_group_name = each.value.network_profile.resource_group
}

# Manages a Managed Kubernetes Cluster.
resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  for_each = { for s in var.res_spec.aks : format("%s", s.name) => s }
  name = each.value.name
  dns_prefix = each.value.name
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  kubernetes_version = lookup(each.value, "version", "1.20.7")
  private_cluster_enabled = lookup(each.value, "private_cluster", true)
  sku_tier = lookup(each.value, "sku_tier", "Free")
  tags = merge(var.tags,each.value.tags)

  dynamic "role_based_access_control" {
    for_each = length(each.value.role_based_access_control) == 0 ? [] : [1]
    content {
      enabled = lookup(each.value.role_based_access_control, "enabled", true)
      azure_active_directory {
        managed = lookup(each.value.role_based_access_control.azure_active_directory, "managed", true)
        azure_rbac_enabled = lookup(each.value.role_based_access_control.azure_active_directory, "azure_rbac_enabled", true)
      }
    }
  }

  dynamic "service_principal" {
    for_each = length(each.value.service_principal) == 0 ? [] : [1]
    content {
      client_id = lookup(each.value.service_principal, "client_id", "")
      client_secret = lookup(each.value.service_principal, "client_secret", null)
    }
  }

  dynamic "network_profile" {
    for_each = length(each.value.network_profile) == 0 ? [] : [1]
    content {
      docker_bridge_cidr = lookup(each.value.network_profile, "docker_cidr", "172.17.0.1/16")
      service_cidr = lookup(each.value.network_profile, "service_cidr", "10.0.0.0/16")
      dns_service_ip = cidrhost(lookup(each.value.network_profile, "service_cidr", "10.0.0.0/16"), 10)
      network_plugin = lookup(each.value.network_profile, "plugin", "azure")
    }
  }

  dynamic "identity" {
    for_each = length(each.value.identity) == 0 ? [] : [1]
    content {
      type = lookup(each.value.identity, "type", "SystemAssigned")
      user_assigned_identity_id = lookup(each.value.identity, "user_assigned_identity_id", null)
    }
  }

  dynamic "addon_profile" {
    for_each = length(each.value.addon_profile) == 0 ? [] : [1]
    content {
      aci_connector_linux {
        enabled = lookup(each.value.addon_profile, "aci_connector_linux", false)
      }
      azure_policy {
        enabled = lookup(each.value.addon_profile, "azure_policy", false)
      }
      http_application_routing {
        enabled = lookup(each.value.addon_profile, "http_application_routing", false)
        }
      kube_dashboard {
        enabled = lookup(each.value.addon_profile, "kube_dashboard", false)
      }
      oms_agent {
        enabled = lookup(each.value.addon_profile, "oms_agent", false)
      }
    }
  }

  default_node_pool {
    vnet_subnet_id = each.value.network_profile.plugin == "azure" ? data.azurerm_subnet.subnet[each.value.name].id : null
    name = "default"
    vm_size = lookup(each.value.default_node_pool, "vm_size", "Standard_B2s")
    os_disk_size_gb = lookup(each.value.default_node_pool, "os_disk_size_gb", "127")
    ultra_ssd_enabled = lookup(each.value.default_node_pool, "ultra_ssd", false)
    enable_auto_scaling = lookup(each.value.default_node_pool, "auto_scaling", false)
    node_count = each.value.default_node_pool.auto_scaling ? null : lookup(each.value.default_node_pool, "node_count", 1)
    max_count = each.value.default_node_pool.auto_scaling ? lookup(each.value.default_node_pool, "max_count", 2) : null
    min_count = each.value.default_node_pool.auto_scaling ? lookup(each.value.default_node_pool, "min_count", 1) : null
    max_pods = lookup(each.value.default_node_pool, "max_pods", 30)
    enable_host_encryption = lookup(each.value.default_node_pool, "host_encryption", false)
    tags = merge(var.tags,each.value.tags)
    node_labels = each.value.default_node_pool.labels

    dynamic "upgrade_settings" {
      for_each = length(each.value.default_node_pool.max_surge) == null ? [] : [1]
      content {
        max_surge = lookup(each.value.default_node_pool, "max_surge", null)
      }
    }

    dynamic "kubelet_config" {
      for_each = length(each.value.kubelet_config) == 0 ? [] : [1]
      content {
        container_log_max_size_mb = lookup(each.value.kubelet_config, "container_log_max_size_mb", 100)
      }
    }

    dynamic "linux_os_config" {
      for_each = length(each.value.linux_os_config) == 0 ? [] : [1]
      content {
        swap_file_size_mb = lookup(each.value.linux_os_config, "swap_file_size_mb", "0")
        transparent_huge_page_defrag = lookup(each.value.linux_os_config, "transparent_huge_page_defrag", "never")
        transparent_huge_page_enabled = lookup(each.value.linux_os_config, "transparent_huge_page_enabled", "never")
        sysctl_config {
          net_core_somaxconn = lookup(each.value.linux_os_config, "net_core_somaxconn", "65535")
          net_ipv4_ip_local_port_range_max = lookup(each.value.linux_os_config, "net_ipv4_ip_local_port_range_max", "60999")
          net_ipv4_ip_local_port_range_min = lookup(each.value.linux_os_config, "net_ipv4_ip_local_port_range_min", "1025")
          net_ipv4_neigh_default_gc_thresh1 = lookup(each.value.linux_os_config, "net_ipv4_neigh_default_gc_thresh1", "4096")
          net_ipv4_neigh_default_gc_thresh2 = lookup(each.value.linux_os_config, "net_ipv4_neigh_default_gc_thresh2", "6144")
          net_ipv4_neigh_default_gc_thresh3 = lookup(each.value.linux_os_config, "net_ipv4_neigh_default_gc_thresh3", "8192")
          net_ipv4_tcp_fin_timeout = lookup(each.value.linux_os_config, "net_ipv4_tcp_fin_timeout", "10")
          net_ipv4_tcp_keepalive_intvl = lookup(each.value.linux_os_config, "net_ipv4_tcp_keepalive_intvl", "30")
          net_ipv4_tcp_keepalive_probes = lookup(each.value.linux_os_config, "net_ipv4_tcp_keepalive_probes", "3")
          net_ipv4_tcp_max_syn_backlog = lookup(each.value.linux_os_config, "net_ipv4_tcp_max_syn_backlog", "20480")
        }
      }
    }
  }
}

# Manages a Node Pool within a Kubernetes Cluster.
resource "azurerm_kubernetes_cluster_node_pool" "kubernetes_cluster_node_pool" {
  for_each = { for s in local.pool_flat : format("%s", s.name) => s }
  kubernetes_cluster_id = azurerm_kubernetes_cluster.kubernetes_cluster[each.value.cluster_name].id
  vnet_subnet_id = each.value.plugin == "azure" ? data.azurerm_subnet.subnet[each.value.cluster_name].id : null
  name = lower(each.value.name)
  os_type = each.value.os_type
  vm_size = each.value.vm_size
  os_disk_size_gb = each.value.os_disk_size_gb
  ultra_ssd_enabled = each.value.ultra_ssd
  enable_auto_scaling = each.value.auto_scaling
  node_count = each.value.auto_scaling ? null : each.value.node_count
  max_count = each.value.auto_scaling ? each.value.max_count : null
  min_count = each.value.auto_scaling ? each.value.min_count : null
  max_pods = each.value.max_pods
  enable_host_encryption = each.value.host_encryption
  tags = merge(var.tags,each.value.tags)
  node_labels = each.value.labels

  dynamic "upgrade_settings" {
    for_each = length(each.value.max_surge) == null ? [] : [1]
    content {
      max_surge = lookup(each.value, "max_surge", null)
    }
  }

  dynamic "kubelet_config" {
    for_each = length(each.value.kubelet_config) == 0 ? [] : [1]
    content {
      container_log_max_size_mb = lookup(each.value.kubelet_config, "container_log_max_size_mb", 100)
    }
  }

  dynamic "linux_os_config" {
    for_each = length(each.value.linux_os_config) == 0 ? [] : [1]
    content {
      swap_file_size_mb = lookup(each.value.linux_os_config, "swap_file_size_mb", "0")
      transparent_huge_page_defrag = lookup(each.value.linux_os_config, "transparent_huge_page_defrag", "never")
      transparent_huge_page_enabled = lookup(each.value.linux_os_config, "transparent_huge_page_enabled", "never")
      sysctl_config {
        net_core_somaxconn = lookup(each.value.linux_os_config, "net_core_somaxconn", "65535")
        net_ipv4_ip_local_port_range_max = lookup(each.value.linux_os_config, "net_ipv4_ip_local_port_range_max", "60999")
        net_ipv4_ip_local_port_range_min = lookup(each.value.linux_os_config, "net_ipv4_ip_local_port_range_min", "1025")
        net_ipv4_neigh_default_gc_thresh1 = lookup(each.value.linux_os_config, "net_ipv4_neigh_default_gc_thresh1", "4096")
        net_ipv4_neigh_default_gc_thresh2 = lookup(each.value.linux_os_config, "net_ipv4_neigh_default_gc_thresh2", "6144")
        net_ipv4_neigh_default_gc_thresh3 = lookup(each.value.linux_os_config, "net_ipv4_neigh_default_gc_thresh3", "8192")
        net_ipv4_tcp_fin_timeout = lookup(each.value.linux_os_config, "net_ipv4_tcp_fin_timeout", "10")
        net_ipv4_tcp_keepalive_intvl = lookup(each.value.linux_os_config, "net_ipv4_tcp_keepalive_intvl", "30")
        net_ipv4_tcp_keepalive_probes = lookup(each.value.linux_os_config, "net_ipv4_tcp_keepalive_probes", "3")
        net_ipv4_tcp_max_syn_backlog = lookup(each.value.linux_os_config, "net_ipv4_tcp_max_syn_backlog", "20480")
      }
    }
  }
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, kubernetes_cluster in azurerm_kubernetes_cluster.kubernetes_cluster: i => kubernetes_cluster.id }
}