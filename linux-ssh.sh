#!/bin/bash
# linux-ssh.sh using Cloudflare Tunnel

# -----------------------------
# Add Linux user and set password
# -----------------------------
sudo useradd -m $LINUX_USERNAME
sudo adduser $LINUX_USERNAME sudo
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
sudo hostname $LINUX_MACHINE_NAME

# -----------------------------
# Validate required secrets
# -----------------------------
if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "Please set 'LINUX_USER_PASSWORD'"
  exit 2
fi

if [[ -z "$LINUX_USERNAME" ]]; then
  echo "Please set 'LINUX_USERNAME'"
  exit 3
fi

# -----------------------------
# Update user password
# -----------------------------
echo "### Update user password ###"
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

# -----------------------------
# Install cloudflared
# -----------------------------
echo "### Install Cloudflare Tunnel ###"
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# -----------------------------
# Start Cloudflare Tunnel for SSH (port 22)
# -----------------------------
CF_LOG=".cloudflared.log"
rm -f $CF_LOG

# Start tunnel in background
cloudflared tunnel --url ssh://localhost:22 > $CF_LOG 2>&1 &

# Wait a few seconds for tunnel to initialize
sleep 10

# Extract the public TCP URL from logs
PUBLIC_URL=$(grep -oE "tcp://[a-zA-Z0-9\.-]+:[0-9]+" $CF_LOG | head -n1)

if [[ -z "$PUBLIC_URL" ]]; then
  echo "Failed to start Cloudflare Tunnel. Check logs:"
  cat $CF_LOG
  exit 4
fi

# -----------------------------
# Output SSH connection info
# -----------------------------
echo ""
echo "=========================================="
echo "To connect from Termux (Android):"
echo "ssh $LINUX_USERNAME@${PUBLIC_URL#tcp://}"
echo "=========================================="
