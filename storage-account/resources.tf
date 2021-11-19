# Access information about an existing Subnet within a Virtual Network.
data "azurerm_subnet" "subnet" {
  for_each = { for s in local.network_rule_flat : format("%s-%s", s.res_name,s.subnet) => s }
  name = each.value.subnet
  virtual_network_name = each.value.virtual_network
  resource_group_name = each.value.resource_group
}

# Manages an Azure Storage Account.
resource "azurerm_storage_account" "storage_account" {
  for_each = { for s in var.res_spec.sa : format("%s", s.name) => s }
  name = each.key
  resource_group_name = var.res_spec.rg[0].name
  location = each.value.location
  account_kind = lookup(each.value, "kind", "StorageV2")
  account_tier = lookup(each.value, "tier", "Standard")
  account_replication_type = lookup(each.value, "replication_type", "LRS")
  enable_https_traffic_only = lookup(each.value, "https_traffic_only", true)
  min_tls_version = lookup(each.value, "min_tls_version", "TLS1_2")
  allow_blob_public_access = lookup(each.value, "blob_public", true)
  shared_access_key_enabled = lookup(each.value, "shared_access_key", true)
  is_hns_enabled = lookup(each.value, "is_hns", true)
  nfsv3_enabled = lookup(each.value, "nfsv3", false)
  tags = merge(var.tags,each.value.tags)
}

/*
# Manages a Private Endpoint.
module "private_endpoint" {
  count = length(local.private_endpoint_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//private-endpoint?ref=v0.1"
  private_endpoint_spec = local.private_endpoint_flat
  resource = [ for s in local.private_endpoint_flat[*] : { res_name = s.res_name }]
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, eventhub_namespace in azurerm_eventhub_namespace.eventhub_namespace: i => eventhub_namespace.id }
}
*/