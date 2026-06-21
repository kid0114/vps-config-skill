# VPS Config Skill

[简体中文](./README.zh-CN.md)

A **3-step automation skill** for configuring new VPS servers with SSH key authentication and WireGuard VPN.

## Features
- ✅ **SSH Key Setup** - Auto-derive key path from alias, upload public key, enable PubkeyAuthentication, configure local SSH config
- ✅ **WireGuard Server** - Install dependencies, auto-detect network interface, configurable listen port, generate client config
- ✅ **Security Hardening** - Disable password login, set `PermitRootLogin prohibit-password`

## Prerequisites
- `sshpass` installed locally
- Client WireGuard key pair (public + private)

## Usage

```bash
# Step 1: SSH Setup (IP, Port, Password, Alias)
./scripts/01_ssh_setup.sh <IP> <PORT> <PASSWORD> <ALIAS>

# Step 2: WireGuard Setup (Alias, Client Public Key, Client Private Key, Listen Port)
./scripts/02_wg_install.sh <ALIAS> <CLIENT_PUB> <CLIENT_PRIV> <LISTEN_PORT>

# Step 3: Security Hardening (Alias)
./scripts/03_security_hardening.sh <ALIAS>
```

## Parameters
- `<IP>`: VPS public IP
- `<PORT>`: SSH port
- `<PASSWORD>`: Initial password
- `<ALIAS>`: SSH host alias (e.g., `vps_jp2`), key auto-named as `~/.ssh/id_ed25519_jp2`
- `<CLIENT_PUB>`: Client WireGuard public key
- `<CLIENT_PRIV>`: Client WireGuard private key
- `<LISTEN_PORT>`: WireGuard listen port (custom)

## How It Works
1. **Step 1**: Auto-derives SSH key from alias → generates if missing → uploads key → tests login → writes `~/.ssh/config`
2. **Step 2**: Installs WireGuard + iptables → detects interface → generates server keys → writes wg0.conf → starts VPN → outputs client config
3. **Step 3**: Verifies key auth → disables password login → sets `PermitRootLogin prohibit-password`

## Templates
- `templates/client.conf` - Client configuration template with placeholders

## Security Notes
- All secrets are **parameterized** (no hardcoded IPs/keys/passwords)
- Password login is disabled **last** to prevent lockout
- `PermitRootLogin prohibit-password` allows root key login while blocking password

## License
MIT License. Feel free to use and modify.
