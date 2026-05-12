variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use ARM_SUBSCRIPTION_ID or the active Azure CLI subscription."
  type        = string
  default     = null
}

variable "resource_prefix" {
  description = "Prefix used for Azure resource names."
  type        = string
  default     = "telegram-gateway"
}

variable "location" {
  description = "Azure region where the gateway will be deployed."
  type        = string
  default     = "eastus"
}

variable "admin_username" {
  description = "SSH username for the Azure VM."
  type        = string
  default     = "azureuser"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,30}$", var.admin_username))
    error_message = "admin_username must be a valid Linux username."
  }
}

variable "ssh_public_key" {
  description = "SSH public key allowed to connect to the VM."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to the VM. Use your own /32 IP instead of the default for production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B1s"
}

variable "wireguard_port" {
  description = "UDP port used by WireGuard."
  type        = number
  default     = 51820
}

variable "wireguard_client_name" {
  description = "Name used for the initial generated WireGuard client configuration."
  type        = string
  default     = "telegram-phone"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.wireguard_client_name))
    error_message = "wireguard_client_name may only contain letters, numbers, underscores, and dashes."
  }
}

variable "telegram_socks_port" {
  description = "TCP port used by the Telegram SOCKS5 proxy."
  type        = number
  default     = 443
}

variable "telegram_socks_username" {
  description = "Username for Telegram's SOCKS5 proxy settings."
  type        = string
  default     = "telegramproxy"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,30}$", var.telegram_socks_username))
    error_message = "telegram_socks_username must be a valid Linux username."
  }
}

variable "telegram_socks_password" {
  description = "Optional SOCKS5 password. Leave blank to generate one on the VM."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = var.telegram_socks_password == "" || can(regex("^[A-Za-z0-9._~-]{12,128}$", var.telegram_socks_password))
    error_message = "telegram_socks_password must be blank or 12-128 URL-safe characters: A-Z, a-z, 0-9, dot, underscore, tilde, or dash."
  }
}
