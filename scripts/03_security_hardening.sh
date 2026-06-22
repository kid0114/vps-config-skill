#!/bin/bash
# Step 3: 安全加固 - 关闭密码登录 + 限制 root 登录
set -e

ALIAS=$1

echo "=== Step 3: Security Hardening ==="

# 3a. 确认密钥登录正常
echo "[3a] Verifying key auth works..."
ssh ${ALIAS} "echo 'KEY_AUTH_VERIFIED'"
echo "  ✅ Key auth confirmed"

# 3b. 关闭密码登录
echo "[3b] Disabling password authentication..."
ssh ${ALIAS} "sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config"

# 3c. 设置 PermitRootLogin prohibit-password
echo "[3c] Setting PermitRootLogin prohibit-password..."
ssh ${ALIAS} "sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config"

# 3d. 重启 sshd
echo "[3d] Restarting sshd..."
ssh ${ALIAS} "systemctl restart sshd"

# 3e. 最终验证密钥登录
echo "[3e] Final verification..."
sleep 2
ssh ${ALIAS} "echo 'SECURITY_HARDENED'"
echo "  ✅ Key-only login works"

# 3f. 检查配置
echo "[3f] Checking sshd config..."
ssh ${ALIAS} "grep -E '^(PasswordAuthentication|PermitRootLogin)' /etc/ssh/sshd_config"
echo "  ✅ Config verified"

echo ""
echo "=== ALL STEPS COMPLETE ==="
echo "✅ SSH key auth only"
echo "✅ WireGuard running"
echo "✅ Password login disabled"
echo "✅ PermitRootLogin prohibit-password"
