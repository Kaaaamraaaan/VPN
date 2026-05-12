# VPN

Azure deployment assets are in [`infra/azure-telegram-gateway`](infra/azure-telegram-gateway).

That module creates a small Azure VM with:

- WireGuard for device-wide VPN use.
- A Telegram-compatible SOCKS5 proxy with a generated `t.me/socks` link.

See the module README for deployment and client configuration steps.
