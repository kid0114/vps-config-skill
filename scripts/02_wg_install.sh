#!/bin/bash
# Step 2: WireGuard 安装 + 配置
set -e

ALIAS=$1; CLIENT_PUB=$2; CLIENT_PRIV=$3

echo "=== Step 2: WireGuard Setup ==="

# 2a. 安装依赖（含 wg-quick）
echo "[2a] Installing dependencies..."
ssh ${ALIAS} "apt update && apt install -y wireguard wireguard-tools iptables"
echo "  ✅ wireguard + wireguard-tools + iptables installed"

# 2b. 检测网卡
echo "[2b] Detecting network interface..."
IFACE=$(ssh ${ALIAS} "ip -4 route show default | awk '{print \$5}'")
echo "  ✅ Interface: ${IFACE}"

# 2c. 生成密钥 + 写 wg0.conf
echo "[2c] Configuring WireGuard..."
ssh ${ALIAS} bash -s "${IFACE}" "${CLIENT_PUB}" << 'EOF'
IFACE=$1; CLIENT_PUB=$2
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = 10.0.0.1/24, fd42:42:42::1/64
ListenPort = 445

PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i %i -o ${IFACE} -j ACCEPT
PostUp = iptables -A FORWARD -i ${IFACE} -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ${IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -o ${IFACE} -j ACCEPT
PostDown = iptables -D FORWARD -i ${IFACE} -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ${IFACE} -j MASQUERADE

PostUp = sysctl -w net.ipv6.conf.all.forwarding=1
PostUp = ip6tables -A FORWARD -i %i -o ${IFACE} -j ACCEPT
PostUp = ip6tables -A FORWARD -i ${IFACE} -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT
PostUp = ip6tables -t nat -A POSTROUTING -o ${IFACE} -j MASQUERADE
PostDown = ip6tables -D FORWARD -i %i -o ${IFACE} -j ACCEPT
PostDown = ip6tables -D FORWARD -i ${IFACE} -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = ip6tables -t nat -D POSTROUTING -o ${IFACE} -j MASQUERADE

[Peer]
PublicKey = ${CLIENT_PUB}
AllowedIPs = 10.0.0.2/32, fd42:42:42::2/128
WGEOF
echo "wg0.conf written"
EOF
echo "  ✅ wg0.conf configured"

# 2d. 启动 WireGuard
echo "[2d] Starting WireGuard..."
ssh ${ALIAS} "wg-quick up wg0"
echo "  ✅ WireGuard started"

# 2e. 检查连接
echo "[2e] Checking connection..."
sleep 3
ssh ${ALIAS} "wg show"
echo "  ✅ Check handshake above"

# 2f. 生成 Client 配置
echo ""
SERVER_PUB=$(ssh ${ALIAS} "cat /etc/wireguard/publickey")
SERVER_IP=$(grep -A1 "^Host ${ALIAS}" ~/.ssh/config | grep HostName | awk '{print $2}')
SERVER_PORT=$(grep -A2 "^Host ${ALIAS}" ~/.ssh/config | grep Port | awk '{print $2}')

cat << CLIENTEOF

=== Client Configuration (copy to your device) ===
[Interface]
PrivateKey = ${CLIENT_PRIV}
Address = 10.0.0.2/24, fd42:42:42::2/64
DNS = 1.1.1.1, 2606:4700:4700::1111
MTU = 1380

[Peer]
PublicKey = ${SERVER_PUB}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${SERVER_IP}:${SERVER_PORT}
PersistentKeepalive = 28
CLIENTEOF

echo ""
echo "=== Step 2 Done ==="
