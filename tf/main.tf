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

  storage_account_name       = var.storage_account_name
  storage_account_access_key = data.azurerm_storage_account.demo.primary_access_key
  service_plan_id            = azurerm_service_plan.demo.id
  https_only                 = true

  auth_settings {
    enabled = true
    active_directory {
      client_id = var.CLIENTID
    }
  }

  site_config {
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
  name                = "demo-linux-psfunction-app"
  resource_group_name = var.rgname
  location            = var.location

  storage_account_name       = var.storage_account_name
  storage_account_access_key = data.azurerm_storage_account.demo.primary_access_key
  service_plan_id            = azurerm_service_plan.demo.id
  https_only                 = true

  auth_settings {
    enabled = false
  }

  site_config {
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
