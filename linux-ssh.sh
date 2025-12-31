#!/bin/bash
# linux-ssh.sh using Serveo with fixed port

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
  echo "Please set 'LINUX_USER_PASSWORD' for user: $USER"
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
# Start Serveo reverse SSH tunnel
# -----------------------------
# Fixed port (change if needed)
SERVEO_PORT=2222
SERVEO_LOG=".serveo.log"
rm -f $SERVEO_LOG

# Run Serveo tunnel in background (-N prevents shell allocation)
ssh -o StrictHostKeyChecking=no -R ${SERVEO_PORT}:localhost:22 serveo.net -N > $SERVEO_LOG 2>&1 &

# Wait a few seconds for tunnel to initialize
sleep 5

# Check if tunnel started
if grep -q "remote port forwarding failed" $SERVEO_LOG; then
  echo "Failed to start Serveo tunnel. Check logs:"
  cat $SERVEO_LOG
  exit 4
fi

# -----------------------------
# Output SSH connection info
# -----------------------------
echo ""
echo "=========================================="
echo "To connect from Termux (Android):"
echo "ssh $LINUX_USERNAME@serveo.net -p $SERVEO_PORT"
echo "=========================================="
