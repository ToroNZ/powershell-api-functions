# Manage identities permissions to read blob
resource "azurerm_user_assigned_identity" "web" {
  location            = var.location
  name                = "web"
  resource_group_name = var.rgname
}

resource "azurerm_user_assigned_identity" "function1" {
  location            = var.location
  name                = "function1"
  resource_group_name = var.rgname
}

resource "azurerm_role_assignment" "web" {
  scope                = azurerm_storage_account.functions.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.web.principal_id
}

resource "azurerm_role_assignment" "function1" {
  scope                = azurerm_storage_account.functions.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.function1.principal_id
}
