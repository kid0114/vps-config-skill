# VPS Config Skill

[简体中文](./README.zh-CN.md)

A **3-step automation skill** for configuring new VPS servers with SSH key authentication and WireGuard VPN.

## Features
- ✅ **SSH Key Setup** - Upload public key, auto-enable PubkeyAuthentication, configure local SSH config
- ✅ **WireGuard Server** - Install dependencies, auto-detect network interface, configure wg0.conf, generate client config
- ✅ **Security Hardening** - Disable password login, set `PermitRootLogin prohibit-password`

## Prerequisites
- `sshpass` installed locally
- SSH key exists at `~/.ssh/id_ed25519_jp2`
- VPS credentials (IP, port, password)
- Client WireGuard key pair (public + private)

## Usage

```bash
# Step 1: SSH Setup (IP, Port, Password)
./scripts/01_ssh_setup.sh <IP> <PORT> <PASSWORD>

# Step 2: WireGuard Setup (Alias, Client Public Key, Client Private Key)
./scripts/02_wg_install.sh <ALIAS> <CLIENT_PUB> <CLIENT_PRIV>

# Step 3: Security Hardening (Alias)
./scripts/03_security_hardening.sh <ALIAS>
```

## How It Works
1. **Step 1**: Uploads SSH key → tests key login → writes `~/.ssh/config` → verifies alias connection
2. **Step 2**: Installs WireGuard + iptables → detects network interface → generates server keys → writes wg0.conf → starts VPN → outputs client config
3. **Step 3**: Verifies key auth → disables password login → sets `PermitRootLogin prohibit-password` → final verification

## Security Notes
- All secrets are **parameterized** (no hardcoded IPs/keys/passwords)
- Password login is disabled **last** to prevent lockout
- `PermitRootLogin prohibit-password` allows root key login while blocking password

## License
MIT License. Feel free to use and modify.
