# Bootstrapping Template File
data "template_file" "nginx-vm-cloud-init" {
  template = file("install-nginx.sh")
}

# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.90.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "nginx" {
  name     = "nginx-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "nginx" {
  name                = "nginx-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.nginx.location
  resource_group_name = azurerm_resource_group.nginx.name
}

resource "azurerm_subnet" "nginx" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.nginx.name
  virtual_network_name = azurerm_virtual_network.nginx.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "nginxpublicip" {
    name                         = "nginx-pubIP"
    location                     = azurerm_resource_group.nginx.location
    resource_group_name          = azurerm_resource_group.nginx.name
    allocation_method            = "Static"
}

resource "azurerm_network_interface" "nginx" {
  name                = "nginx-nic"
  location            = azurerm_resource_group.nginx.location
  resource_group_name = azurerm_resource_group.nginx.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nginx.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nginxpublicip.id
  }
}

resource "azurerm_linux_virtual_machine" "nginx" {
  name                = "nginx-machine"
  resource_group_name = azurerm_resource_group.nginx.name
  location            = azurerm_resource_group.nginx.location
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nginx.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa_nginx.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  custom_data = base64encode(data.template_file.nginx-vm-cloud-init.rendered) 
}

