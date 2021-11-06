# Generates random maintenance hour values.
resource "random_integer" "integer" {
  for_each = { for s in var.res_spec.redis : format("%s", s.name) => s }
  min = 0
  max = 23
  keepers = {
    seed = each.value.name
  }
}

# Manages a Redis Cache.
resource "azurerm_redis_cache" "redis_cache" {
  for_each = { for s in var.res_spec.redis : format("%s", s.name) => s }
  name = each.value.name
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  capacity = each.value.capacity
  family = lookup(each.value, "sku", "basic") == lower("premium") ? "P" : "C"
  sku_name = each.value.sku
  enable_non_ssl_port = lookup(each.value, "enable_non_ssl", false)
  minimum_tls_version = lookup(each.value, "minimum_tls_version", "1.2")
  public_network_access_enabled = lookup(each.value, "public_network_access", false)
  redis_version = lookup(each.value, "version", "4")
  tags = merge(var.tags,each.value.tags)

  dynamic "redis_configuration" {
    for_each = length(each.value.redis_configuration) == 0 ? [] : [1]
    content {
      enable_authentication = lookup(each.value.redis_configuration, "enable_authentication", true)
      maxmemory_reserved = lookup(each.value.redis_configuration, "maxmemory_reserved", 2)
      maxfragmentationmemory_reserved = lookup(each.value.redis_configuration, "maxfragmentationmemory_reserved", 2)
      maxmemory_delta = lookup(each.value.redis_configuration, "maxmemory_delta", 2)
      maxmemory_policy = lookup(each.value.redis_configuration, "maxmemory_policy", "volatile-lru")
    }
  }

  dynamic "patch_schedule" {
    for_each = length(each.value.patch_schedule) == 0 ? [] : [1]
    content {
      day_of_week = lookup(each.value.patch_schedule, "day_of_week", title("Sunday"))
      start_hour_utc = lookup(each.value.patch_schedule, "start_hour_utc", random_integer.integer[each.value.name].result)
      maintenance_window = lookup(each.value.patch_schedule, "maintenance_window", "PT5H")
    }
  }
}

# Manages a Firewall Rule associated with a Redis Cache.
resource "azurerm_redis_firewall_rule" "redis_firewall_rule" {
  for_each = { for s in local.firewall_rule_flat : format("%s", s.name) => s }
  name = each.value.role_name
  redis_cache_name = azurerm_redis_cache.redis_cache[each.value.name].name
  resource_group_name = var.res_spec.rg[0].name
  start_ip = each.value.start
  end_ip = each.value.end
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, redis_cache in azurerm_redis_cache.redis_cache: i => redis_cache.id }
}

# Manages a Private Endpoint.
module "private_endpoint" {
  count = length(local.private_endpoint_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//private-endpoint?ref=v0.1"
  private_endpoint_spec = local.private_endpoint_flat
  resource = { for i, redis_cache in azurerm_redis_cache.redis_cache: i => redis_cache.id }
}