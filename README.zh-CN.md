# VPS 配置技能

[English](./README.md)

一个**三步自动化技能**，用于配置新 VPS 服务器的 SSH 密钥登录和 WireGuard 梯子。

## 功能
- ✅ **SSH 密钥配置** - 根据别名自动推导密钥路径、上传公钥、开启 PubkeyAuthentication、配置本地 SSH config
- ✅ **WireGuard 梯子** - 安装依赖、自动检测网卡、自定义监听端口、生成客户端配置
- ✅ **安全加固** - 关闭密码登录、设置 `PermitRootLogin prohibit-password`

## 前置条件
- 本地已安装 `sshpass`
- 客户端 WireGuard 密钥对（公钥 + 私钥）

## 使用方法

```bash
# 第一步：SSH 配置（IP、端口、密码、别名）
./scripts/01_ssh_setup.sh <IP> <PORT> <PASSWORD> <ALIAS>

# 第二步：WireGuard 配置（别名、客户端公钥、客户端私钥、监听端口）
./scripts/02_wg_install.sh <ALIAS> <CLIENT_PUB> <CLIENT_PRIV> <LISTEN_PORT>

# 可选：覆盖 WireGuard 内网地址，避免和 LAN / Docker / 已有 WG 网段冲突
WG_SERVER_IPV4_CIDR=10.3.0.1/24 \
WG_CLIENT_IPV4_CIDR=10.3.0.2/24 \
./scripts/02_wg_install.sh <ALIAS> <CLIENT_PUB> <CLIENT_PRIV> <LISTEN_PORT>

# 第三步：安全加固（别名）
./scripts/03_security_hardening.sh <ALIAS>
```

## 参数说明
- `<IP>`: VPS 公网 IP
- `<PORT>`: SSH 端口
- `<PASSWORD>`: 初始密码
- `<ALIAS>`: SSH 别名（如 `vps_jp2`），密钥自动命名为 `~/.ssh/id_ed25519_jp2`
- `<CLIENT_PUB>`: 客户端 WireGuard 公钥
- `<CLIENT_PRIV>`: 客户端 WireGuard 私钥
- `<LISTEN_PORT>`: WireGuard 监听端口（自定义）

### 第二步可选环境变量

- `WG_SERVER_IPV4_CIDR`: 服务端 IPv4 隧道地址，默认 `10.0.0.1/24`
- `WG_CLIENT_IPV4_CIDR`: 客户端 IPv4 隧道地址，默认 `10.0.0.2/24`
- `WG_CLIENT_ALLOWED_IPV4`: 服务端 peer `AllowedIPs` 中的客户端 IPv4，默认从 `WG_CLIENT_IPV4_CIDR` 推导为 `/32`
- `WG_SERVER_IPV6_CIDR`: 服务端 IPv6 隧道地址，默认 `fd42:42:42::1/64`
- `WG_CLIENT_IPV6_CIDR`: 客户端 IPv6 隧道地址，默认 `fd42:42:42::2/64`
- `WG_CLIENT_ALLOWED_IPV6`: 服务端 peer `AllowedIPs` 中的客户端 IPv6，默认从 `WG_CLIENT_IPV6_CIDR` 推导为 `/128`

## 工作流程
1. **第一步**：根据别名自动推导密钥路径 → 不存在则生成 → 上传密钥 → 测试登录 → 写入 `~/.ssh/config`
2. **第二步**：安装 WireGuard + iptables → 检测网卡 → 生成服务端密钥 → 写入 wg0.conf → 启动梯子 → 输出客户端配置。WireGuard 内网地址可配置，新节点要避开本地 LAN、Docker 和已有 WireGuard 网段；服务端配置会先显式启用 `wg0` 的 IPv6，再开启 IPv6 转发。
3. **第三步**：验证密钥登录 → 关闭密码登录 → 设置 `PermitRootLogin prohibit-password`

## 模版
- `templates/client.conf` - 客户端配置模版（含占位符）

## 安全说明
- 所有敏感信息均为**参数传入**（无硬编码 IP/密钥/密码）
- 密码登录**最后关闭**，防止锁死
- `PermitRootLogin prohibit-password` 允许 root 密钥登录，同时禁止密码登录
- VPS 没有可用 IPv6 出口时，客户端 `AllowedIPs` 不要包含 `::/0`，否则 IPv6 流量进隧道后可能黑洞。

## 许可证
MIT 许可证。欢迎使用和修改。
