#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: sudo bash setup_ssl_wings.sh your-node-domain.com"
    exit 1
fi

DOMAIN="$1"

echo "=== [1/3] Install Certbot ==="
apt update
apt install -y certbot

echo "=== [2/3] Request SSL Certificate (standalone mode, port 80 must be free) ==="
systemctl stop wings || true
certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN

echo "=== [3/3] Update config.yml for SSL ==="
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
if [ -f /etc/pterodactyl/config.yml ]; then
    sed -i "s#^  ssl: false#  ssl: true#" /etc/pterodactyl/config.yml
    sed -i "s#^  cert:.*#  cert: $CERT_PATH#" /etc/pterodactyl/config.yml
    sed -i "s#^  key:.*#  key: $KEY_PATH#" /etc/pterodactyl/config.yml
    echo "config.yml updated for SSL."
else
    echo "config.yml not found! Please update manually:"
    echo "ssl: true"
    echo "cert: $CERT_PATH"
    echo "key: $KEY_PATH"
fi

systemctl start wings
echo "=== Selesai! Wings sekarang berjalan dengan SSL di $DOMAIN ==="
