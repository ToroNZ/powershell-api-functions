terraform {
  backend "azurerm" {
    resource_group_name  = "powershell-functions"
    storage_account_name = "demoterraformtfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
