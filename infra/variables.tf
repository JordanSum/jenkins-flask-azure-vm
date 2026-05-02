variable "rg" {
    description = "Name of the resource group"
    type        = string
  
}

variable "location" {
    description = "Azure region for the resources"
    type        = string
}

variable "your_ip" {
    description = "Your current IP address for firewall rules"
    type        = string
}

variable "ssh_public_key_path" {
    description = "Path to the SSH public key for the Jenkins VM"
    type        = string
    default = "~/.ssh/id_rsa.pub"
}

variable "certbot_email" {
    description = "Email address for Let's Encrypt certificate registration"
    type        = string
}

variable "domain_name" {
    description = "Domain name for the Flask app"
    type        = string
}

variable "route53_zone_name" {
    description = "Route 53 hosted zone name for the domain"
    type        = string
}