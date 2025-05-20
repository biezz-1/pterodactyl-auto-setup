#!/bin/bash
set -e

# --- Auto-fix line endings and permissions ---
if command -v dos2unix >/dev/null 2>&1; then
  sudo dos2unix "$0"
fi
sudo chmod +x "$0"
# --------------------------------------------

echo "=== [1/6] Update & Install Dependencies ==="
apt update && apt upgrade -y
apt install -y curl wget tar xz-utils git ufw

echo "=== [2/6] Install Docker ==="
curl -fsSL https://get.docker.com | bash
systemctl enable --now docker

echo "=== [3/6] Download Pterodactyl Wings ==="
mkdir -p /etc/pterodactyl
cd /etc/pterodactyl
curl -L https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 -o wings
chmod +x wings

echo "=== [4/6] Setup Firewall (UFW) ==="
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 2022/tcp
ufw allow 8080/tcp
ufw --force enable

echo "=== [5/6] Setup Wings as Systemd Service ==="
cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/etc/pterodactyl/wings
Restart=on-failure
StartLimitInterval=600
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wings

echo "=== [6/6] Wings installed! ==="
echo "Sekarang, login ke panel Pterodactyl Anda, buat node baru, dan download file konfigurasi wings (config.yml)."
echo "Upload config.yml ke /etc/pterodactyl/config.yml"
echo "Setelah itu, jalankan:"
echo "sudo systemctl start wings"
echo "Untuk melihat log: sudo journalctl -u wings -f"
