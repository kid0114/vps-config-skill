#!/bin/bash
# Step 1: SSH 密钥上传 + 配置
set -e

IP=$1; PORT=$2; PASS=$3
ALIAS=$4
KEY=~/.ssh/id_ed25519_${ALIAS#vps_}

echo "=== Step 1: SSH Setup ==="
echo "  Alias: ${ALIAS}"
echo "  Key: ${KEY}"

if [ ! -f "${KEY}.pub" ]; then
  echo "  -> Key not found, generating..."
  ssh-keygen -t ed25519 -f "${KEY}" -N "" -C "vps@${ALIAS}"
fi

# 1. 先检测并开启 PubkeyAuthentication
echo "[1] Checking PubkeyAuthentication..."
PUBKEY_STATUS=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -p "$PORT" root@"$IP" \
  "grep -E '^#\?PubkeyAuthentication' /etc/ssh/sshd_config | grep -v 'yes' || echo 'not_found'" 2>/dev/null || echo "not_found")

if [ -n "$PUBKEY_STATUS" ]; then
  echo "  -> PubkeyAuthentication not enabled, fixing..."
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -p "$PORT" root@"$IP" \
    "sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd"
  sleep 2
  echo "  ✅ PubkeyAuthentication enabled"
else
  echo "  ✅ PubkeyAuthentication already enabled"
fi

# 2. 上传公钥
echo "[2] Uploading SSH key..."
sshpass -p "$PASS" ssh-copy-id -o StrictHostKeyChecking=no -p "$PORT" -i ${KEY}.pub root@"$IP"

# 3. 测试密钥登录
echo "[3] Testing SSH key auth..."
if ! ssh -i $KEY -p "$PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$IP" "echo OK" 2>/dev/null; then
  echo "  ❌ Key auth failed, aborting..."
  exit 1
fi
echo "  ✅ SSH key auth works"

# 4. 写入本地 SSH Config
echo "[4] Writing local SSH config..."
cat >> ~/.ssh/config << EOF

Host ${ALIAS}
    HostName ${IP}
    Port ${PORT}
    User root
    IdentityFile ${KEY}
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

# 5. 测试 alias 连接
echo "[5] Testing alias connection..."
ssh ${ALIAS} "echo 'ALIAS_OK'"
echo "  ✅ SSH alias works"

echo "=== Step 1 Done ==="
