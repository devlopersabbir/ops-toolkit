#!/usr/bin/env bash

# ============================================
# NGINX COMPLETE REMOVAL SCRIPT
# Author: DevOps Best Practice
# Description:
#   Fully removes nginx from system including:
#   - service
#   - packages
#   - configs
#   - logs
#   - cache
# ============================================

set -e  # Exit on error

echo "🔍 Detecting OS..."

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
else
    echo "❌ Unsupported OS"
    exit 1
fi

echo "✅ OS detected: $OS"

# ============================================
# Stop & Disable Nginx
# ============================================

echo "🛑 Stopping nginx service..."
sudo systemctl stop nginx 2>/dev/null || true

echo "🚫 Disabling nginx service..."
sudo systemctl disable nginx 2>/dev/null || true

# Remove systemd service leftovers
echo "🧹 Cleaning systemd..."
sudo rm -f /etc/systemd/system/nginx.service 2>/dev/null || true
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# ============================================
# Remove Packages
# ============================================

echo "📦 Removing nginx packages..."

if [ "$OS" = "debian" ]; then
    sudo apt-get purge -y nginx nginx-common nginx-full nginx-core || true
    sudo apt-get autoremove -y
elif [ "$OS" = "redhat" ]; then
    sudo yum remove -y nginx || true
fi

# ============================================
# Remove Files & Directories
# ============================================

echo "🧹 Removing nginx directories..."

DIRS=(
    /etc/nginx
    /var/log/nginx
    /var/cache/nginx
    /usr/share/nginx
    /var/www/html
)

for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Removing $dir"
        sudo rm -rf "$dir"
    fi
done

# ============================================
# Remove User & Group (if exists)
# ============================================

echo "👤 Removing nginx user/group..."

if id "nginx" &>/dev/null; then
    sudo userdel -r nginx || true
fi

if getent group nginx &>/dev/null; then
    sudo groupdel nginx || true
fi

# ============================================
# Verify Removal
# ============================================

echo "🔎 Verifying nginx removal..."

if command -v nginx &>/dev/null; then
    echo "⚠️ nginx binary still exists!"
else
    echo "✅ nginx binary removed"
fi

if systemctl list-units --full -all | grep -q nginx; then
    echo "⚠️ nginx service still present"
else
    echo "✅ nginx service removed"
fi

echo "🎉 Nginx completely removed from system!"
