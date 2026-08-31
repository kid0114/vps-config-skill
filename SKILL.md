---
name: vps-config
description: Use when setting up or hardening a VPS with SSH key login, WireGuard, and security hardening steps.
---

# VPS Config Skill

## 用途
一键配置新 VPS：SSH 密钥登录 + WireGuard 梯子 + 安全加固

## 前置条件
- 本地已安装 `sshpass`
- 客户端 WireGuard 密钥对（公钥 + 私钥）

## 用法

```bash
# Step 1: SSH 配置（IP、端口、密码、别名）
~/.codex/skills/vps-config/scripts/01_ssh_setup.sh <IP> <PORT> <PASSWORD> <ALIAS>

# Step 2: WireGuard 配置（别名、客户端公钥、客户端私钥、监听端口）
~/.codex/skills/vps-config/scripts/02_wg_install.sh <ALIAS> <CLIENT_PUB> <CLIENT_PRIV> <LISTEN_PORT>

# 可选：指定 WireGuard 内网地址，避免和已有 LAN / Docker / 其他 WG 网段冲突
WG_SERVER_IPV4_CIDR=10.3.0.1/24 \
WG_CLIENT_IPV4_CIDR=10.3.0.2/24 \
~/.codex/skills/vps-config/scripts/02_wg_install.sh <ALIAS> <CLIENT_PUB> <CLIENT_PRIV> <LISTEN_PORT>

# Step 3: 安全加固（别名）
~/.codex/skills/vps-config/scripts/03_security_hardening.sh <ALIAS>
```

## 参数说明
- `<IP>`: VPS 公网 IP
- `<PORT>`: SSH 端口
- `<PASSWORD>`: 初始密码
- `<ALIAS>`: SSH Config 中的 Host 别名（如 vps_jp2），密钥自动命名为 `~/.ssh/id_ed25519_jp2`
- `<CLIENT_PUB>`: 客户端 WireGuard 公钥
- `<CLIENT_PRIV>`: 客户端 WireGuard 私钥
- `<LISTEN_PORT>`: WireGuard 监听端口（自定义）

### Step 2 可选环境变量

- `WG_SERVER_IPV4_CIDR`: 服务端 IPv4 内网地址，默认 `10.0.0.1/24`
- `WG_CLIENT_IPV4_CIDR`: 客户端 IPv4 内网地址，默认 `10.0.0.2/24`
- `WG_CLIENT_ALLOWED_IPV4`: 服务端 peer AllowedIPs 的客户端 IPv4，默认从 `WG_CLIENT_IPV4_CIDR` 推导为 `/32`
- `WG_SERVER_IPV6_CIDR`: 服务端 IPv6 内网地址，默认 `fd42:42:42::1/64`
- `WG_CLIENT_IPV6_CIDR`: 客户端 IPv6 内网地址，默认 `fd42:42:42::2/64`
- `WG_CLIENT_ALLOWED_IPV6`: 服务端 peer AllowedIPs 的客户端 IPv6，默认从 `WG_CLIENT_IPV6_CIDR` 推导为 `/128`

## 分步说明

### Step 1: SSH Setup
- 根据 alias 自动推导密钥路径（如 `~/.ssh/id_ed25519_jp2`）
- 密钥不存在则自动生成
- 上传公钥
- 测试密钥登录（失败则开启 PubkeyAuth）
- 写入本地 SSH Config
- 测试 alias 连接
- **必须每步验证通过后才能继续**

### Step 2: WireGuard Setup
- 安装 wireguard + wireguard-tools + iptables
- 动态检测网卡
- 生成服务端密钥 + 写 wg0.conf（使用传入的客户端公钥和监听端口）
- WireGuard 内网地址默认使用 `10.0.0.0/24`，但可通过环境变量弹性覆盖；新节点要先避开本地 LAN、旁路由、Docker 和已有 WG 网段
- IPv6 启用时写入 `net.ipv6.conf.wg0.disable_ipv6=0` 和 `net.ipv6.conf.all.forwarding=1`
- 启动 wg-quick
- 检查握手状态
- 生成客户端配置（使用传入的客户端私钥和监听端口）

### Step 3: Security Hardening
- 确认密钥登录正常
- 关闭 PasswordAuthentication
- 设置 PermitRootLogin prohibit-password
- 最终验证

## 注意事项
- 每步执行后必须检查输出，失败则停止
- 网卡动态检测，不硬编码
- 密码登录最后才关闭，防止锁死
- 所有敏感信息均为参数传入，无硬编码
- 密钥路径根据 alias 自动推导
- 监听端口可自定义
- VPS 无 IPv6 时，客户端配置不要加 `::/0`（IPv6 全隧道），否则 IPv6 流量进隧道后到不了服务端会丢包
