terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.78.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_group = "snipee_rg"
  location       = "North Europe"
}

resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem
}

resource "azurerm_resource_group" "snipee_rg" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_virtual_network" "snipee_vnet" {
  name                = "snipee-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.snipee_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.snipee_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "snipee_public_ip" {
  name                = "snipee-public-ip"
  resource_group_name = azurerm_resource_group.snipee_rg.name
  location            = local.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "snipee_interface" {
  name                = "snipee-interface"
  location            = local.location
  resource_group_name = azurerm_resource_group.snipee_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.snipee_public_ip.id
  }
}

resource "azurerm_network_security_group" "snipee_nsg" {
  name                = "snipee-SecurityGroup1"
  location            = local.location
  resource_group_name = azurerm_resource_group.snipee_rg.name

  security_rule {
    name                       = "all-traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}
resource "azurerm_subnet_network_security_group_association" "snipee_nsga" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.snipee_nsg.id
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "linuxvm"
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_B1s"
  admin_username      = "linuxusr"
  network_interface_ids = [
    azurerm_network_interface.snipee_interface.id,
  ]
  admin_ssh_key {
    username   = "linuxusr"
    public_key = tls_private_key.linux_key.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "file" {
    source      = "package.sh"
    destination = "/home/linuxusr/package.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "ls -lh",
      "chmod 777 ./package.sh",
      "./package.sh",
    ]
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.snipee_public_ip.ip_address} >> local.txt"
  }

  connection {
    type        = "ssh"
    user        = "linuxusr"
    host        = azurerm_public_ip.snipee_public_ip.ip_address
    private_key = file(local_file.linuxkey.filename)
  }

  depends_on = [
    azurerm_network_interface.snipee_interface,
    tls_private_key.linux_key,
  ]
}
