# Storage account to upload the function(s) to
resource "azurerm_storage_account" "functions" {
  name                = "gwfunctiondemostgaccount"
  resource_group_name = var.rgname

  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  network_rules {
    default_action = "Deny"
    bypass         = ["Metrics", "Logging", "AzureServices"]
  }

}
