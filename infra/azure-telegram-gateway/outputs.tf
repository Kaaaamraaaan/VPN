output "public_ip" {
  description = "Public IP address of the VPN/proxy gateway."
  value       = azurerm_public_ip.gateway.ip_address
}

output "ssh_command" {
  description = "SSH command for the deployed gateway."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.gateway.ip_address}"
}

output "wireguard_config_command" {
  description = "Command to print the generated WireGuard client configuration."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.gateway.ip_address} 'sudo cat /opt/privacy-gateway/wireguard/${var.wireguard_client_name}.conf'"
}

output "wireguard_qr_command" {
  description = "Command to print a terminal QR code for importing the WireGuard client configuration."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.gateway.ip_address} 'sudo qrencode -t ansiutf8 < /opt/privacy-gateway/wireguard/${var.wireguard_client_name}.conf'"
}

output "telegram_socks_command" {
  description = "Command to print Telegram SOCKS5 settings and a t.me link."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.gateway.ip_address} 'sudo cat /opt/privacy-gateway/telegram-socks.txt'"
}
