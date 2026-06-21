# VPS Config Skill

## 用途
一键配置新 VPS：SSH 密钥登录 + WireGuard 服务端 + 生成客户端配置

## 前置条件
- 本地已安装 `sshpass`
- 本地已有 SSH 密钥 `~/.ssh/id_ed25519_jp2`

## 用法
```bash
# Step 1: SSH 配置（输入 IP、端口、密码）
~/.codex/skills/vps-config/scripts/01_ssh_setup.sh <IP> <PORT> <PASSWORD>

# Step 2: WireGuard 配置（输入 alias、客户端公钥、客户端私钥）
~/.codex/skills/vps-config/scripts/02_wg_install.sh <ALIAS> <CLIENT_PUBLIC_KEY> <CLIENT_PRIVATE_KEY>

# Step 3: 安全加固（输入 alias）
~/.codex/skills/vps-config/scripts/03_security_hardening.sh <ALIAS>
```

## 参数说明
- `<IP>`: VPS 公网 IP
- `<PORT>`: SSH 端口
- `<PASSWORD>`: 初始密码
- `<ALIAS>`: SSH Config 中的 Host 别名（如 vps_jp2）
- `<CLIENT_PUBLIC_KEY>`: **客户端 WireGuard 公钥**（每次配置时填入）
- `<CLIENT_PRIVATE_KEY>`: **客户端 WireGuard 私钥**（每次配置时填入）

## 分步说明

### Step 1: SSH Setup
- 上传公钥
- 测试密钥登录（失败则开启 PubkeyAuth）
- 写入本地 SSH Config
- 测试 alias 连接
- **必须每步验证通过后才能继续**

### Step 2: WireGuard Setup
- 安装 wireguard + wireguard-tools + iptables
- 动态检测网卡
- 生成服务端密钥 + 写 wg0.conf（使用传入的客户端公钥）
- 启动 wg-quick
- 检查握手状态
- 生成客户端配置（使用传入的客户端私钥）

### Step 3: Security Hardening
- 确认密钥登录正常
- 关闭 PasswordAuthentication
- 最终验证

## 注意事项
- 每步执行后必须检查输出，失败则停止
- 网卡动态检测，不硬编码
- 密码登录最后才关闭，防止锁死
- **客户端公钥/私钥由用户每次配置时提供，脚本中不硬编码**
