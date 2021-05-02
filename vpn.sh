#!/bin/bash -e

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <IDENTITY_FILE> <INSTANCE_IP>"
  exit
fi

IDENTITY_FILE=$1
INSTANCE_IP=$2

echo "Install packages"
{
sudo apt-get update
sudo apt-get install -y wireguard resolvconf
} >> logs

echo "Configure server"
scp -i "$IDENTITY_FILE" vpn-server.sh "ubuntu@$INSTANCE_IP:"
ssh -i "$IDENTITY_FILE" "ubuntu@$INSTANCE_IP" bash vpn-server.sh

echo "Configure client"
ssh -i "$IDENTITY_FILE" "ubuntu@$INSTANCE_IP" cat client.conf | sudo tee /etc/wireguard/wg0.conf
wg-quick up wg0

echo "Run tests"
./test-connection.sh