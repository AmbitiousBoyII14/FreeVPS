#!/bin/bash
# linux-ssh.sh using Serveo
# /home/runner/.serveo.log

# Add user and set password
sudo useradd -m $LINUX_USERNAME
sudo adduser $LINUX_USERNAME sudo
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
sudo hostname $LINUX_MACHINE_NAME

# Check required secrets
if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "Please set 'LINUX_USER_PASSWORD' for user: $USER"
  exit 2
fi

if [[ -z "$LINUX_USERNAME" ]]; then
  echo "Please set 'LINUX_USERNAME'"
  exit 3
fi

echo "### Update user password ###"
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

echo "### Start Serveo reverse SSH tunnel for port 22 ###"

# Remove old log
SERVEO_LOG=".serveo.log"
rm -f $SERVEO_LOG

# Run Serveo tunnel in background, allocate random public port
ssh -o StrictHostKeyChecking=no -R 0:localhost:22 serveo.net > $SERVEO_LOG 2>&1 &

# Wait for tunnel to initialize
sleep 5

# Extract the public host and port
PUBLIC_URL=$(grep -oE "Forwarding TCP connections from [^ ]+" $SERVEO_LOG | awk '{print $5}')

if [[ -z "$PUBLIC_URL" ]]; then
  echo "Failed to start Serveo tunnel. Check logs:"
  cat $SERVEO_LOG
  exit 4
fi

echo ""
echo "=========================================="
echo "To connect from Termux (Android):"
echo "ssh $LINUX_USERNAME@${PUBLIC_URL}"
echo "=========================================="
