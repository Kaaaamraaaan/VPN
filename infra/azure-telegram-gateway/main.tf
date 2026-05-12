provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

locals {
  name = substr(regexreplace(lower(var.resource_prefix), "[^a-z0-9-]", "-"), 0, 40)

  tags = {
    workload   = "telegram-vpn-gateway"
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "gateway" {
  name     = "${local.name}-rg"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "gateway" {
  name                = "${local.name}-vnet"
  address_space       = ["10.42.0.0/16"]
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name
  tags                = local.tags
}

resource "azurerm_subnet" "gateway" {
  name                 = "${local.name}-subnet"
  resource_group_name  = azurerm_resource_group.gateway.name
  virtual_network_name = azurerm_virtual_network.gateway.name
  address_prefixes     = ["10.42.1.0/24"]
}

resource "azurerm_public_ip" "gateway" {
  name                = "${local.name}-pip"
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_security_group" "gateway" {
  name                = "${local.name}-nsg"
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name
  tags                = local.tags

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWireGuard"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.wireguard_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowTelegramSocks"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.telegram_socks_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

resource "azurerm_network_interface" "gateway" {
  name                = "${local.name}-nic"
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.gateway.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gateway.id
  }
}

resource "azurerm_linux_virtual_machine" "gateway" {
  name                            = "${local.name}-vm"
  computer_name                   = "${local.name}-vm"
  location                        = azurerm_resource_group.gateway.location
  resource_group_name             = azurerm_resource_group.gateway.name
  network_interface_ids           = [azurerm_network_interface.gateway.id]
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tftpl", {
    public_ip                    = azurerm_public_ip.gateway.ip_address
    wireguard_port               = var.wireguard_port
    wireguard_client_name        = var.wireguard_client_name
    telegram_socks_port          = var.telegram_socks_port
    telegram_socks_username      = var.telegram_socks_username
    telegram_socks_password_b64  = base64encode(var.telegram_socks_password)
  }))
  tags = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
