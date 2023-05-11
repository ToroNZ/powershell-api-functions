# Create App Insights for debugging/logging
resource "azurerm_application_insights" "functions" {
  name                = "demo-psfunctions-appinsights"
  location            = var.location
  resource_group_name = var.rgname
  application_type    = "other"
}

# Function apps

resource "azurerm_service_plan" "demo" {
  name                = "demo-app-service-plan"
  resource_group_name = var.rgname
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption based SKU
}

resource "azurerm_linux_function_app" "web" {
  name                = "demo-frontend-app"
  resource_group_name = var.rgname
  location            = var.location

  storage_account_name          = azurerm_storage_account.functions.name
  storage_uses_managed_identity = true
  service_plan_id               = azurerm_service_plan.demo.id
  https_only                    = true

  auth_settings {
    enabled = true
    active_directory {
      client_id = var.CLIENTID
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME         = "Python"
    FUNCTIONS_WORKER_RUNTIME_VERSION = "~3"
    WEBSITE_RUN_FROM_PACKAGE         = 0
  }

  site_config {
    application_insights_key    = azurerm_application_insights.functions.instrumentation_key
    minimum_tls_version         = "1.2"
    scm_minimum_tls_version     = "1.2"
    scm_use_main_ip_restriction = true
    http2_enabled               = true
    application_stack {
      python_version = "3.9"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.web.id]
  }

  depends_on = [azurerm_role_assignment.web]

}

resource "azurerm_linux_function_app" "function1" {
  name                = "demo-backend-app"
  resource_group_name = var.rgname
  location            = var.location

  storage_account_name          = azurerm_storage_account.functions.name
  storage_uses_managed_identity = true
  service_plan_id               = azurerm_service_plan.demo.id
  https_only                    = true

  auth_settings {
    enabled = false
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME         = "powershell"
    FUNCTIONS_WORKER_RUNTIME_VERSION = "~7"
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

    cors {
      allowed_origins = ["${azurerm_linux_function_app.web.default_hostname}"]
    }
    ip_restriction {
      action                    = "Allow"
      virtual_network_subnet_id = azurerm_subnet.demo.id
    }
    ip_restriction {
      action     = "Allow"
      ip_address = "202.174.170.183/32"
    }
    dynamic "ip_restriction" {
      for_each = toset(azurerm_linux_function_app.web.possible_outbound_ip_address_list)
      content {
        ip_address = "${ip_restriction.value}/32"
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function1.id]
  }

  depends_on = [azurerm_role_assignment.function1]

}

resource "azurerm_function_app_function" "web" {
  name            = "demo-frontend1-app"
  function_app_id = azurerm_linux_function_app.web.id
  language        = "Python"
  file {
    name    = "__init__.py"
    content = <<EOT
import logging

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    if name:
        return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.")
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
             status_code=200
        )
EOT
  }
  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "function"
        "direction" = "in"
        "methods" = [
          "get"
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

resource "azurerm_function_app_function" "function1" {
  name            = "demo-backend1-app"
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
