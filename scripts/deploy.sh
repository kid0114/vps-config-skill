#!/bin/bash
set -e

IP=$1; PORT=$2; PASS=$3; CLIENT_PUB=$4
KEY=~/.ssh/id_ed25519_jp2
ALIAS="vps_$(echo $IP | tr '.' '_')"

echo "=== VPS Deploy: $IP:$PORT ==="

# 1. 上传公钥
echo "[1/7] Uploading SSH key..."
sshpass -p "$PASS" ssh-copy-id -o StrictHostKeyChecking=no -p "$PORT" -i ${KEY}.pub root@"$IP"

# 2. 测试密钥登录（如果失败则开启 PubkeyAuth）
echo "[2/7] Testing SSH key auth..."
if ! ssh -i $KEY -p "$PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$IP" "echo OK" 2>/dev/null; then
  echo "  -> Key auth failed, enabling PubkeyAuthentication..."
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -p "$PORT" root@"$IP" \
    "sed -i 's/^PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd"
  sleep 2
fi

# 再次测试
ssh -i $KEY -p "$PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$IP" "echo 'SSH_KEY_OK'"
echo "  ✅ SSH key auth works"

# 3. 安装依赖（含 wg-quick）
echo "[3/7] Installing dependencies..."
ssh -i $KEY -p "$PORT" root@"$IP" "apt update && apt install -y wireguard wireguard-tools iptables"
echo "  ✅ wireguard + wireguard-tools + iptables installed"

# 4. 检测网卡
echo "[4/7] Detecting network interface..."
IFACE=$(ssh -i $KEY -p "$PORT" root@"$IP" "ip -4 route show default | awk '{print \$5}'")
echo "  ✅ Interface: $IFACE"

# 5. 生成密钥 + 写 wg0.conf
echo "[5/7] Configuring WireGuard..."
ssh -i $KEY -p "$PORT" root@"$IP" bash -s "$IFACE" "$CLIENT_PUB" << 'EOF'
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

# 6. 启动 WireGuard
echo "[6/7] Starting WireGuard..."
ssh -i $KEY -p "$PORT" root@"$IP" "wg-quick up wg0"
echo "  ✅ WireGuard started"

# 7. 检查连接
echo "[7/7] Checking connection..."
sleep 3
ssh -i $KEY -p "$PORT" root@"$IP" "wg show"
echo "  ✅ Done! Check for handshake."

# 8. 生成 Client 配置
SERVER_PUB=$(ssh -i $KEY -p "$PORT" root@"$IP" "cat /etc/wireguard/publickey")
cat << CLIENTEOF

=== Client Configuration ===
[Interface]
PrivateKey = UB2CnIAF8DNfyl66JYPAqHLpOqQuZXX6qycMzaV64FI=
Address = 10.0.0.2/24, fd42:42:42::2/64
DNS = 1.1.1.1, 2606:4700:4700::1111
MTU = 1380

[Peer]
PublicKey = ${SERVER_PUB}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${IP}:445
PersistentKeepalive = 28
CLIENTEOF

echo ""
echo "=== All done! ==="
