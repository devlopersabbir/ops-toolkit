#!/usr/bin/env bash

set -e

REPO_BASE="https://raw.githubusercontent.com/devlopersabbir/devops-tools/main"

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

echo "⚙️ Executing $SERVICE..."

# ============================================
# Fetch & Execute Selected Script
# ============================================

curl -fsSL "$REPO_BASE/services/$SERVICE" | bash
