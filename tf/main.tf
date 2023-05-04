# Networking (private LAN)
resource "azurerm_virtual_network" "demo" {
  name                = "demo-vnet"
  address_space       = ["10.200.0.0/23"]
  location            = var.location
  resource_group_name = var.rgname
}

resource "azurerm_subnet" "demo" {
  name                 = "demo-subnet"
  resource_group_name  = var.rgname
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.200.1.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

# Storage account to upload the function(s) to
resource "azurerm_storage_account" "functions" {
  name                = "gwfunctiondemostgaccount"
  resource_group_name = var.rgname

  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

# Create App Insights for debugging/logging

resource "azurerm_application_insights" "functions" {
  name                = "demo-psfunctions-appinsights"
  location            = var.location
  resource_group_name = var.rgname
  application_type    = "other"
}

# Function app stuff (powershell triggered by http call)

resource "azurerm_service_plan" "demo" {
  name                = "demo-app-service-plan"
  resource_group_name = var.rgname
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption based SKU
}

resource "azurerm_linux_function_app" "web" {
  name                = "demo-linux-jsfunction-app"
  resource_group_name = var.rgname
  location            = var.location

  storage_account_name = azurerm_storage_account.functions.name
  service_plan_id      = azurerm_service_plan.demo.id
  https_only           = true

  auth_settings {
    enabled = true
    active_directory {
      client_id = var.CLIENTID
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME         = "node"
    FUNCTIONS_WORKER_RUNTIME_VERSION = "~18"
    storage_uses_managed_identity    = true
  }

  site_config {
    application_insights_key    = azurerm_application_insights.functions.instrumentation_key
    minimum_tls_version         = "1.2"
    scm_minimum_tls_version     = "1.2"
    scm_use_main_ip_restriction = true
    http2_enabled               = true
    application_stack {
      node_version = "18"
    }
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_linux_function_app" "function1" {
  name                = "demo-linux-ps7function-app"
  resource_group_name = var.rgname
  location            = var.location

  storage_account_name = azurerm_storage_account.functions.name
  service_plan_id      = azurerm_service_plan.demo.id
  https_only           = true

  auth_settings {
    enabled = false
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME         = "powershell"
    FUNCTIONS_WORKER_RUNTIME_VERSION = "~7"
    storage_uses_managed_identity    = true
  }

  site_config {
    application_insights_key    = azurerm_application_insights.functions.instrumentation_key
    minimum_tls_version         = "1.2"
    scm_minimum_tls_version     = "1.2"
    scm_use_main_ip_restriction = true
    http2_enabled               = true
    application_stack {
      powershell_core_version = "7.2"
    }
    ip_restriction {
      action                    = "Allow"
      virtual_network_subnet_id = azurerm_subnet.demo.id
    }
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_function_app_function" "function1" {
  name            = "demo-ps7function-app"
  function_app_id = azurerm_linux_function_app.function1.id
  language        = "PowerShell"
  file {
    name    = "pinghost.ps1"
    content = file("../functions/pinghost.ps1")
  }
  test_data = jsonencode({
    "host" = "1.1.1.1"
  })
  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "function"
        "direction" = "in"
        "methods" = [
          "post",
        ]
        "name" = "req"
        "type" = "httpTrigger"
      },
      {
        "direction" = "out"
        "name"      = "$return"
        "type"      = "http"
      },
    ]
  })
}

# Managed identities permissions to read blob
resource "azurerm_role_assignment" "web" {
  scope                = azurerm_storage_account.functions.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_function_app.web.identity[0].principal_id
}

resource "azurerm_role_assignment" "function1" {
  scope                = azurerm_storage_account.functions.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_function_app.function1.identity[0].principal_id
}
