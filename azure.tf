resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "azure-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.azure_vpc_cidr]
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.gateway_subnet]
}

resource "azurerm_subnet" "azure_subnet" {
  name                 = "WorkloadSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.azure_subnet]
}

resource "azurerm_public_ip" "public_ip_1" {
  name                = "azure-public-ip-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "public_ip_2" {
  name                = "azure-public-ip-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "public_ip_3" {
  name                = "azure-public-ip-3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "azure-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = true
  enable_bgp          = true
  sku                 = "VpnGw1"
  bgp_settings {
    asn = var.azure_bgp_asn
    peering_addresses {
      ip_configuration_name = "gw-ip1"
      apipa_addresses       = [cidrhost("169.254.21.0/30", 2), cidrhost("169.254.21.4/30", 2)]
    }
    peering_addresses {
      ip_configuration_name = "gw-ip2"
      apipa_addresses       = [cidrhost("169.254.22.0/30", 2), cidrhost("169.254.22.4/30", 2)]
    }
  }
  ip_configuration {
    name                          = "gw-ip1"
    public_ip_address_id          = azurerm_public_ip.public_ip_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }
  ip_configuration {
    name                          = "gw-ip2"
    public_ip_address_id          = azurerm_public_ip.public_ip_2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }
}

resource "azurerm_local_network_gateway" "gateway_1_tunnel_1" {
  depends_on          = [azurerm_virtual_network_gateway.gateway]
  name                = "aws-vpn-1-tunnel-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  gateway_address     = aws_vpn_connection.azure-vpn1.tunnel1_address
  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = cidrhost("169.254.21.0/30", 1)
  }
}

resource "azurerm_local_network_gateway" "gateway_1_tunnel_2" {
  depends_on          = [azurerm_virtual_network_gateway.gateway]
  name                = "aws-vpn-1-tunnel-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  gateway_address     = aws_vpn_connection.azure-vpn1.tunnel2_address
  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = cidrhost("169.254.21.4/30", 1)
  }
}

resource "azurerm_local_network_gateway" "gateway_2_tunnel_1" {
  depends_on          = [azurerm_virtual_network_gateway.gateway]
  name                = "aws-vpn-2-tunnel-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  gateway_address     = aws_vpn_connection.azure-vpn2.tunnel1_address
  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = cidrhost("169.254.22.0/30", 1)
  }
}

resource "azurerm_local_network_gateway" "gateway_2_tunnel_2" {
  depends_on          = [azurerm_virtual_network_gateway.gateway]
  name                = "aws-vpn-2-tunnel-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  gateway_address     = aws_vpn_connection.azure-vpn2.tunnel2_address
  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = cidrhost("169.254.22.4/30", 1)
  }
}

resource "azurerm_virtual_network_gateway_connection" "aws_tunnel_1" {
  name                       = "aws-vpn-1-tunnel-1"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.gateway_1_tunnel_1.id
  shared_key                 = aws_vpn_connection.azure-vpn1.tunnel1_preshared_key
}

resource "azurerm_virtual_network_gateway_connection" "aws_tunnel_2" {
  name                       = "aws-vpn-1-tunnel-2"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.gateway_1_tunnel_2.id
  shared_key                 = aws_vpn_connection.azure-vpn1.tunnel2_preshared_key
}

resource "azurerm_virtual_network_gateway_connection" "aws_tunnel_3" {
  name                       = "aws-vpn-2-tunnel-1"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.gateway_2_tunnel_1.id
  shared_key                 = aws_vpn_connection.azure-vpn2.tunnel1_preshared_key
}

resource "azurerm_virtual_network_gateway_connection" "aws_tunnel_4" {
  name                       = "aws-vpn-2-tunnel-2"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.gateway_2_tunnel_2.id
  shared_key                 = aws_vpn_connection.azure-vpn2.tunnel2_preshared_key
}