# Query the object ID for each user.
data "azuread_user" "user" {
  for_each            = { for s in local.role_flat : format("%s", s.name) => s if lower(s.type) == "user" }
  user_principal_name = each.value.name
}

# Query the object ID for each group.
data "azuread_group" "group" {
  for_each     = { for s in local.role_flat : format("%s", s.name) => s if lower(s.type) == "group" }
  display_name = each.value.name
}

# Query the object ID for each service principal.
data "azuread_service_principal" "app" {
  for_each     = { for s in local.role_flat : format("%s", s.name) => s if lower(s.type) == "app" }
  display_name = each.value.name
}

# Assigns an User to a given Role.
resource "azurerm_role_assignment" "role_assignment_user" {
  for_each             = { for s in local.role_flat : format("%s", s.name) => s if lower(s.type) == "user" }
  scope                = var.resource_id
  role_definition_name = each.value.role
  principal_id         = data.azuread_user.user[each.key].object_id
}

# Assigns an Group to a given Role.
resource "azurerm_role_assignment" "role_assignment_group" {
  for_each             = { for s in local.role_flat : format("%s", s.name) => s if lower(s.type) == "group" }
  scope                = var.resource_id
  role_definition_name = each.value.role
  principal_id         = data.azuread_group.group[each.key].object_id
}

# Assigns an Applications to a given Role.
resource "azurerm_role_assignment" "role_assignment_app" {
  for_each             = { for s in local.role_flat : format("%s", s.name) => s if lower(s.type) == "app" }
  scope                = var.resource_id
  role_definition_name = each.value.role
  principal_id         = data.azuread_service_principal.app[each.key].object_id
}