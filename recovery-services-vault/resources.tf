# Manages a Recovery Services Vault.
resource "azurerm_recovery_services_vault" "recovery_services_vault" {
for_each = { for s in var.res_spec.rsv : format("%s", s.name) => s }
  name = each.value.name
  location = each.value.location
  resource_group_name = var.res_spec.rg[0].name
  sku = each.value.sku
  soft_delete_enabled = each.value.soft_delete_enabled
  tags = merge(var.tags,each.value.tags)
  identity {
    type = "SystemAssigned"
  }
}

# Assigns a given Principal (User, Group or App) to a given Role.
module "role_assignment" {
  count = length(local.role_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//role-assignment?ref=v0.1"
  role_spec = local.role_flat
  resource = { for i, recovery_services_vault in azurerm_recovery_services_vault.recovery_services_vault: i => recovery_services_vault.id }
}