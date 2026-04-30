output "jenkins_public_ip" {
    description = "Public IP address of the Jenkins VM"
    value       = azurerm_public_ip.jenkins_pip.ip_address
}