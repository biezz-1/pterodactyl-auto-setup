#!/bin/bash
set -e

# --- Auto-fix line endings and permissions ---
if command -v dos2unix >/dev/null 2>&1; then
  sudo dos2unix "$0"
fi
sudo chmod +x "$0"
# --------------------------------------------

# Pterodactyl Panel Auto Installer for Ubuntu 20.04
# Author: Copilot
# Date: 2025-05-20

# 1. Update & Install Dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip tar nginx mariadb-server redis-server software-properties-common

# Add PHP 8.0 repository
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php8.0 php8.0-fpm php8.0-cli php8.0-gd php8.0-mysql php8.0-pgsql php8.0-redis php8.0-mbstring php8.0-xml php8.0-curl php8.0-zip php8.0-bcmath php8.0-gmp php8.0-intl

# Install Composer
cd ~
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

# 2. Configure MariaDB
sudo systemctl enable mariadb
sudo systemctl start mariadb
sudo mysql_secure_installation

# 3. Create Pterodactyl Database
DB_PASS=$(openssl rand -base64 16)
sudo mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE panel;
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# 4. Download Pterodactyl Panel
cd /var/www/
sudo curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
sudo mkdir -p /var/www/pterodactyl
sudo tar -xzvf panel.tar.gz -C /var/www/pterodactyl --strip-components=1
sudo rm panel.tar.gz
cd /var/www/pterodactyl

# 5. Install Composer Dependencies
sudo composer install --no-dev --optimize-autoloader

# 6. Setup Environment
sudo cp .env.example .env
sudo php artisan key:generate --force

# 7. Configure .env for Database
sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=panel/" .env
sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=pterodactyl/" .env
sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" .env

# 8. Run Migrations
sudo php artisan migrate --seed --force

# 9. Set Permissions
sudo chown -R www-data:www-data /var/www/pterodactyl/*
sudo chmod -R 755 /var/www/pterodactyl/storage/* /var/www/pterodactyl/bootstrap/cache/

# 10. Configure Nginx
sudo tee /etc/nginx/sites-available/pterodactyl > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/pterodactyl/public;

    index index.php;
    charset utf-8;
    client_max_body_size 100m;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors on;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/pterodactyl
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# 11. Output Info
clear
echo "=== Selesai! ==="
echo "Panel Pterodactyl sudah terinstall."
echo "Akses melalui: http://<IP-SERVER-ANDA>"
echo "Jangan lupa setup email di .env dan buat user admin dengan:"
echo "cd /var/www/pterodactyl && php artisan p:user:make"
echo "Database password (simpan!): ${DB_PASS}"
