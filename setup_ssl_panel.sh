#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: sudo bash setup_ssl_panel.sh your-domain.com"
    exit 1
fi

DOMAIN="$1"

echo "=== [1/4] Install Certbot & Nginx Plugin ==="
apt update
apt install -y certbot python3-certbot-nginx

echo "=== [2/4] Konfigurasi Nginx untuk Domain ==="
sed -i "s/server_name _;/server_name $DOMAIN;/" /etc/nginx/sites-available/pterodactyl
systemctl reload nginx

echo "=== [3/4] Request SSL Certificate ==="
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN

echo "=== [4/4] Setup Auto Renewal ==="
systemctl enable certbot.timer
systemctl start certbot.timer

echo "=== Selesai! ==="
echo "Panel Anda sekarang dapat diakses dengan HTTPS di https://$DOMAIN"
echo "SSL akan diperpanjang otomatis."
