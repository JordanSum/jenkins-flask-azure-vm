# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rg
  location = var.location
}

# Virtual Network & Subnets

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.rg}-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "jenkins_subnet" {
    name = "jenkins-subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["192.168.1.0/24"]
}

#resource "azurerm_subnet" "AzureBastionSubnet" {
#    name = "AzureBastionSubnet"
#    resource_group_name = azurerm_resource_group.rg.name
#    virtual_network_name = azurerm_virtual_network.vnet.name
#    address_prefixes = ["192.168.2.0/24"]
#}

# Bastion Host to access Jenkins VM and related resources
#resource "azurerm_bastion_host" "bastion" {
#  name                = "jenkins-bastion"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name
#
#  ip_configuration {
#    name                 = "bastion-ip-config"
#    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
#    public_ip_address_id = azurerm_public_ip.bastion_pip.id
#  }
#}

#resource "azurerm_network_security_group" "bastion_nsg" {
#  name                = "bastion-nsg"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name

#  security_rule {
#    name                       = "Allow-SSH"
#    priority                   = 1001
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "22"
#    source_address_prefix      = var.your_ip
#    destination_address_prefix = "*"
#  }

#  security_rule {
#    name                       = "Allow-HTTP"
#    priority                   = 1002
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "80"
#    source_address_prefix      = "*"
#    destination_address_prefix = "*"
#  }

#  security_rule {
#    name                       = "Allow-HTTPS"
#    priority                   = 1003
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "443"
#    source_address_prefix      = "*"
#    destination_address_prefix = "*"
#  }

#  security_rule {
#    name                      = "Allow-Bastion-Internal-comms"
#    priority                   = 1004
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "5701"
#    source_address_prefix      = var.your_ip
#    destination_address_prefix = "*"    
#  }
#}

#resource "azurerm_public_ip" "bastion_pip" {
#  name                = "bastion-pip"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name
#  allocation_method   = "Static"
#  sku                 = "Standard"
#}

# Jenkins VM
resource "azurerm_network_interface" "jenkins_nic" {
  name                = "jenkins-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "jenkins-ip-config"
    subnet_id                     = azurerm_subnet.jenkins_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_pip.id
  }
}

resource "azurerm_public_ip" "jenkins_pip" {
  name                = "jenkins-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "jenkins_nsg" {
  name                = "jenkins-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  security_rule {
    name                       = "Allow-Jenkins"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.your_ip
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.your_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jenkins_nic.id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
}

resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "jenkins-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.jenkins_nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key_path)
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
  
  custom_data = base64encode(templatefile("${path.module}/cloud-init-jenkins.sh", {
  fqdn  = var.domain_name
  email = var.certbot_email
  }))

  depends_on = [aws_route53_record.app]

}

data "aws_route53_zone" "primary" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [azurerm_public_ip.jenkins_pip.ip_address]
}
