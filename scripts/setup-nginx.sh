#!/bin/bash
# Setup Nginx for devman.me domains (SSL via Cloudflare)
set -e

echo "=== Installing Nginx ==="
sudo apt update
sudo apt install -y nginx

echo "=== Creating directories ==="
sudo mkdir -p /var/www/devman.me

echo "=== Deploying Nginx configs ==="
sudo cp /opt/infrastructure/nginx/*.conf /etc/nginx/sites-available/

for conf in /opt/infrastructure/nginx/*.conf; do
    name=$(basename "$conf")
    sudo ln -sf /etc/nginx/sites-available/$name /etc/nginx/sites-enabled/
done

sudo rm -f /etc/nginx/sites-enabled/default

echo "=== Reloading Nginx ==="
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Nginx configured!"
