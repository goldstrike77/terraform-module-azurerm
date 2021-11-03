# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in var.res_spec.aks : format("%s", s.name) => s if s.network.plugin == "azure" }
  name = each.value.network.subnet
  virtual_network_name = each.value.network.virtual_network
  resource_group_name = each.value.network.resource_group
}

# Manages a Managed Kubernetes Cluster.
resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  for_each                = { for s in var.res_spec.aks : format("%s", s.name) => s }
  name                    = each.value.name
  dns_prefix              = each.value.name
  location                = each.value.location
  resource_group_name     = var.res_spec.rg[0].name
  kubernetes_version      = lookup(each.value, "version", "1.20.7")
  private_cluster_enabled = lookup(each.value, "private_cluster", true)
  sku_tier                = lookup(each.value, "sku_tier", "Free")
  tags                    = merge(var.tags,each.value.tags)
  network_profile {
    docker_bridge_cidr = lookup(each.value, "docker_cidr", "172.17.0.1/16")
    service_cidr       = lookup(each.value, "service_cidr", "10.0.0.0/16")
    dns_service_ip     = cidrhost(lookup(each.value, "service_cidr", "10.0.0.0/16"), 10)
    network_plugin     = lookup(each.value.network, "plugin", "azure")
  }
  default_node_pool {
    vnet_subnet_id      = each.value.network.plugin == "azure" ? data.azurerm_subnet.subnet[each.value.name].id : null
    name                = "defaultpool"
    vm_size             = lookup(each.value.default_node_pool, "node_size", "Standard_B2s")
    os_disk_size_gb     = lookup(each.value.default_node_pool, "os_disk_size_gb", "127")
    enable_auto_scaling = lookup(each.value.default_node_pool, "auto_scaling", false)
    node_count          = lookup(each.value.default_node_pool, "node_count", 2)
    max_count           = each.value.default_node_pool.auto_scaling ? lookup(each.value.default_node_pool, "max_count", 2) : null
    min_count           = each.value.default_node_pool.auto_scaling ? lookup(each.value.default_node_pool, "min_count", 2) : null
    max_pods            = lookup(each.value.default_node_pool, "max_pods", 30)
    tags                = merge(var.tags,each.value.tags,each.value.default_node_pool.tags)
    node_labels         = merge(each.value.tags,each.value.default_node_pool.tags)
/*
    kubelet_config {
      container_log_max_size_mb = 100
    }

    linux_os_config {
      swap_file_size_mb = "0"
      transparent_huge_page_defrag = "never"
      transparent_huge_page_enabled = "never"

      sysctl_config {
        net_core_somaxconn = "65535"
        net_ipv4_ip_local_port_range_max = "60999"
        net_ipv4_ip_local_port_range_min = "1025"
        net_ipv4_neigh_default_gc_thresh1 = "4096"
        net_ipv4_neigh_default_gc_thresh2 = "6144"
        net_ipv4_neigh_default_gc_thresh3 = "8192"
        net_ipv4_tcp_fin_timeout = "10"
        net_ipv4_tcp_keepalive_intvl = "30"
        net_ipv4_tcp_keepalive_probes = "3"
        net_ipv4_tcp_max_syn_backlog = "20480"
      }

    }
*/
  }
  identity {
    type = "SystemAssigned"
  }
}