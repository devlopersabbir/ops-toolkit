#!/usr/bin/env bash

set -e

REPO_BASE="https://raw.githubusercontent.com/YOUR_USERNAME/devops-tools/main"

# ============================================
# UI Prompt (simple, clean)
# ============================================

echo "======================================"
echo "   🚀 DevOps Cleanup Toolkit"
echo "======================================"
echo ""
echo "Select a service to remove:"
echo "1) Nginx"
echo "2) Caddy"
echo "3) Docker"
echo "0) Exit"
echo ""

read -p "Enter choice: " choice

case $choice in
    1)
        SERVICE="nginx/remove.sh"
        ;;
    2)
        SERVICE="caddy/remove.sh"
        ;;
    3)
        SERVICE="docker/remove.sh"
        ;;
    0)
        echo "Bye 👋"
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

read -p "⚠️ Are you sure? This will remove nginx completely (y/n): " confirm

if [[ "$confirm" != "y" ]]; then
    echo "Cancelled."
    exit 0
fi

echo "⚙️ Executing $SERVICE..."

# ============================================
# Fetch & Execute Selected Script
# ============================================

curl -fsSL "$REPO_BASE/services/$SERVICE" | bash
