# Manages a Log Analytics Workspace.
resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  for_each = { for s in var.res_spec.loga : format("%s", s.name) => s }
  name = each.value.name
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  sku = each.value.sku
  retention_in_days = lookup(each.value, "retention_in_days", 180)
  internet_ingestion_enabled = lookup(each.value, "internet_ingestion_enabled", false)
  internet_query_enabled = lookup(each.value, "internet_query_enabled", false)
  tags = merge(var.tags,each.value.tags)
}