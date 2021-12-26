output "azurerm_public_ip" {
  value = azurerm_public_ip.nginxpublicip.ip_address
}

output "azurerm_fqdn" {
  value = azurerm_public_ip.nginxpublicip.fqdn
}

