#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

echo 'root:Admin@@11' | chpasswd

mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/99-custom.conf <<'EOF'
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords no
EOF

chmod 600 /etc/ssh/sshd_config.d/99-custom.conf

sshd -t

if command -v systemctl >/dev/null 2>&1; then
  systemctl reload ssh
else
  service ssh reload
fi

echo "Completed successfully"
