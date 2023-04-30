data "azurerm_storage_account" "demo" {
  name                = var.storage_account_name
  resource_group_name = var.location
}
