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

resource "azurerm_resource_group" "maria" {
    name     = var.resource_group_name
    location = var.account_location
}

resource "azurerm_virtual_network" "maria" {
    count               = var.maria_srv_count
    name                = "maria-network.${count.index}"
    address_space       = ["10.${count.index}.0.0/16"]
    location            = azurerm_resource_group.maria.location
    resource_group_name = azurerm_resource_group.maria.name
}

resource "azurerm_subnet" "maria" {
    count                = var.maria_srv_count
    name                 = "internal${count.index}"
    resource_group_name  = azurerm_resource_group.maria.name
    virtual_network_name = azurerm_virtual_network.maria[count.index].name
    address_prefixes     = ["10.${count.index}.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "mariapi" {
    count                = var.maria_srv_count
    name                 = "maria-pubIP${count.index}"
    location             = azurerm_resource_group.maria.location
    resource_group_name  = azurerm_resource_group.maria.name
    allocation_method    = "Static"
    
    domain_name_label    = join( "", [ var.maria_host_pre, tostring( count.index  ) ] )
}


resource "azurerm_network_interface" "maria" {
    count               = var.maria_srv_count
    name                = "maria-nic${count.index}"
    location            = azurerm_resource_group.maria.location
    resource_group_name = azurerm_resource_group.maria.name

    ip_configuration {
        name                          = "internal${count.index}"
        subnet_id                     = azurerm_subnet.maria[count.index].id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.mariapi[count.index].id
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "maria-nsg" {
    count               = var.maria_srv_count
    name                = "mariaNSG${count.index}"
    location            = azurerm_resource_group.maria.location
    resource_group_name = azurerm_resource_group.maria.name

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
        name                       = "mysql-client-in"
        priority                   = 1005
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "mysql-client-out"
        priority                   = 1005
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    tags = {
        environment = "mariadb"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "maria" {
    count                     = var.maria_srv_count
    network_interface_id      = azurerm_network_interface.maria[count.index].id
    network_security_group_id = azurerm_network_security_group.maria-nsg[count.index].id
}

# Bootstrapping Template File
data "template_file" "maria-vm-cloud-init" {
    count                     = var.maria_srv_count
    template = file("install-maria${count.index}.sh")

    vars = {
        iter       = count.index
        db_fqdn    = join( "", [ var.maria_host_pre, "${count.index}", var.maria_fqdn_post ] )
        db_user    = var.maria_usr_name
        db_pwd     = var.maria_usr_pwd
        db_rep_usr = var.maria_rep_name
        db_rep_pwd = var.maria_rep_pwd
    }
}

resource "azurerm_linux_virtual_machine" "maria" {
    count               = var.maria_srv_count
    name                = "maria-machine${count.index}"
    resource_group_name = azurerm_resource_group.maria.name
    location            = azurerm_resource_group.maria.location
    size                = "Standard_B1ls"
    admin_username      = "adminuser"
    network_interface_ids = [
        azurerm_network_interface.maria[count.index].id,
    ]

    admin_ssh_key {
        username   = "adminuser"
        public_key = file("~/.ssh/id_rsa_ghaz303.pub")
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

    custom_data = base64encode(data.template_file.maria-vm-cloud-init[count.index].rendered) 
}


