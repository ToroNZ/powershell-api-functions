# Time sleep resource
resource "time_sleep" "wait_for_stgaccount" {
  create_duration = "10s"

  depends_on = [azurerm_storage_account.functions]
}

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
    ip_rules       = [var.PUBLIC_IP]
    bypass         = ["Metrics", "Logging", "AzureServices"]
  }

}

# Create container for frontend
resource "azurerm_storage_container" "frontend_container" {
  name                 = "frontend-function"
  storage_account_name = azurerm_storage_account.functions.name

  depends_on = [azurerm_storage_account.functions, time_sleep.wait_for_stgaccount]
}

# Upload function for frontend

data "archive_file" "frontend_function" {
  type        = "zip"
  source_dir  = var.frontend_code
  output_path = "function.zip"

  depends_on = [null_resource.pip]
}

resource "null_resource" "pip" {
  triggers = {
    requirements_md5 = "${filemd5("${var.frontend_code}/requirements.txt")}"
  }
  provisioner "local-exec" {
    command     = "pip install --target='.python_packages/lib/site-packages' -r requirements.txt"
    working_dir = var.frontend_code
  }
}

resource "azurerm_storage_blob" "frontend_blob" {
  name                   = "functions-${substr(data.archive_file.frontend_function.output_md5, 0, 6)}.zip"
  storage_account_name   = azurerm_storage_account.functions.name
  storage_container_name = azurerm_storage_container.frontend_container.name
  type                   = "Block"
  content_md5            = data.archive_file.frontend_function.output_md5
  source                 = "function.zip"
}

# Create container for backend

resource "azurerm_storage_container" "backend_container" {
  name                 = "backend-function"
  storage_account_name = azurerm_storage_account.functions.name

  depends_on = [azurerm_storage_account.functions, time_sleep.wait_for_stgaccount]
}
