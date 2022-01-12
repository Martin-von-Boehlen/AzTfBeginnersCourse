# Bootstrapping Template File
data "template_file" "nginx-vm-cloud-init" {
    template = file("install-nginx.sh")

    vars = {
        nginx_fqdn = var.nginx_fqdn
        db_fqdn    = var.mysqlsrv_dns_name
        db_user    = var.mysqlsrv_usr_name
        db_pwd     = var.mysqlsrv_usr_pwd
    }
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
    name     = var.resource_group_name
    location = var.account_location
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
    domain_name_label            = var.nginx_hostname
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

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nginx-nsg" {
    name                = "nginxNSG"
    location            = azurerm_resource_group.nginx.location
    resource_group_name = azurerm_resource_group.nginx.name

    # If no security group exists, global default is "allow"
    # As soon as a NSG exists the global default changes to "deny"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "mysql-client"
        priority                   = 1005
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    security_rule {
        name                       = "HTTP"
        priority                   = 1011
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPS"
        priority                   = 1021
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "nginx"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nginx" {
    network_interface_id      = azurerm_network_interface.nginx.id
    network_security_group_id = azurerm_network_security_group.nginx-nsg.id
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

