# Azure Telegram Gateway

This Terraform module deploys a small Ubuntu VM in Azure and configures:

- WireGuard for device-wide VPN routing.
- A Dante SOCKS5 proxy on TCP `443` for Telegram's in-app proxy settings.

Use this only where it is legal for you to operate a VPN/proxy and where it complies with Azure's terms. Networks with heavy filtering may still block Azure IP ranges, WireGuard UDP, or proxy traffic; this module does not guarantee connectivity in any specific country.

## Prerequisites

- Azure CLI authenticated with `az login`.
- Terraform `>= 1.5`.
- An SSH key pair.

## Deploy

```bash
cd infra/azure-telegram-gateway
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"

terraform init
terraform apply \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  -var="allowed_ssh_cidr=<your-public-ip>/32"
```

If you do not know your public IP, use a trusted IP lookup service before running `terraform apply`. The `allowed_ssh_cidr` value only controls SSH access; WireGuard and Telegram proxy ports remain reachable from the internet so clients can connect while traveling.

## Retrieve client settings

After `terraform apply` finishes, give cloud-init a minute or two to install packages and generate credentials.

Print the Telegram SOCKS5 settings and link:

```bash
terraform output -raw telegram_socks_command
```

Run the command it prints. The result includes:

- Server
- Port
- Username
- Password
- `https://t.me/socks?...` link

In Telegram, open the link or go to:

`Settings -> Data and Storage -> Proxy -> Add Proxy -> SOCKS5`

Print the WireGuard client configuration:

```bash
terraform output -raw wireguard_config_command
```

Render a QR code for importing into the WireGuard mobile app:

```bash
terraform output -raw wireguard_qr_command
```

Run the command it prints, then scan the QR code with the WireGuard app.

## Useful outputs

```bash
terraform output public_ip
terraform output ssh_command
terraform output telegram_socks_command
terraform output wireguard_config_command
terraform output wireguard_qr_command
```

## Optional variables

```bash
terraform apply \
  -var="location=westeurope" \
  -var="vm_size=Standard_B1s" \
  -var="wireguard_port=51820" \
  -var="telegram_socks_port=443" \
  -var="telegram_socks_username=telegramproxy" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  -var="allowed_ssh_cidr=<your-public-ip>/32"
```

Leave `telegram_socks_password` blank to generate a random password on the VM. If you set it yourself, Terraform will store that value in state, so protect your state file.

## Remove everything

```bash
terraform destroy \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```
