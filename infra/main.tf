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

# Bastion Host (Jenkins VM) and related resources
resource "azurerm_bastion_host" "bastion" {
  name                = "jenkins-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.jenkins_subnet.id
    public_ip_address_id = azurerm_public_ip.jenkins_pip.id
  }
}

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
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
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
  
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    #wait for system to initialize
    sleep 60
    
    sudo apt update

    # Install Java and Jenkins
    sudo apt install -y fontconfig openjdk-21-jre
    
    sleep 30
    sudo mkdir -p /etc/apt/keyrings
    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    sudo apt update
    
    # wait for update to complete
    sleep 30
    
    sudo apt install -y jenkins
    
    # wait for jenkins to finish installing
    sleep 30

    # Install Docker
    curl -fsSL https://get.docker.com | sudo sh

    sudo usermod -aG docker jenkins
    
    # wait for docker to finish installing
    sleep 60

    sudo chmod 666 /var/run/docker.sock

    # enable and start Jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins

    # Install Nginx
    sudo apt install -y nginx

    # Install Certbot and DNS-01 Route53 plugin (run certbot manually after DNS is configured)
    sudo apt install -y certbot python3-certbot-dns-route53

    # Write Nginx reverse proxy config for the Flask app
    sudo tee /etc/nginx/sites-available/flaskapp > /dev/null <<'NGINXCONF'
    server {
        listen 80;
        server_name ${var.domain_name};

        location / {
            proxy_pass http://localhost:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    NGINXCONF

    sudo ln -s /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default

    sudo systemctl enable nginx
    sudo systemctl start nginx

    # Run certbot manually after pointing DNS to this VM's IP:
    # sudo certbot certonly --dns-route53 -d ${var.domain_name} --non-interactive --agree-tos -m ${var.certbot_email}
    # sudo certbot install --nginx -d ${var.domain_name}
    
  EOF
  )
}
