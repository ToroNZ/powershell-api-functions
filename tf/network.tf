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
