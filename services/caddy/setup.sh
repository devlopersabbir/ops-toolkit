#!/usr/bin/env bash

# ============================================
# CADDY OFFICIAL SETUP SCRIPT
# ============================================
# Follows official Caddy documentation for:
# - Debian/Ubuntu
# - CentOS/RHEL/Fedora
# ============================================

set -e

# --- Load Infrastructure ---
REPO_BASE="${REPO_BASE:-https://raw.githubusercontent.com/devlopersabbir/ops-toolkit/main}"

load_component() {
    local type=$1 # constants or libs
    local file=$2
    if [ -f "../../$type/$file" ]; then source "../../$type/$file";
    elif [ -f "./$type/$file" ]; then source "./$type/$file";
    else source <(curl -fsSL "$REPO_BASE/$type/$file"); fi
}

load_component "constants" "colors.sh"
load_component "libs" "logger.sh"
load_component "libs" "utils.sh"

# --- Main Logic ---

log_header "CADDY INSTALLATION"

log_step "Detecting OS"
OS=$(detect_os)
[ "$OS" = "unknown" ] && log_error "Unsupported OS" && exit 1
log_success "OS detected: $OS"

log_step "Setting up the repository"
if [ "$OS" = "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg --yes
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt-get update
elif [ "$OS" = "redhat" ]; then
    sudo yum install -y 'dnf-command(copr)'
    sudo dnf copr enable -y @caddy/caddy
fi

log_step "Installing Caddy"
if [ "$OS" = "debian" ]; then
    sudo apt-get install -y caddy
elif [ "$OS" = "redhat" ]; then
    sudo dnf install -y caddy
fi

log_step "Starting Caddy"
manage_service "start" "caddy"

log_step "Verifying installation"
if command -v caddy &>/dev/null; then
    VERSION=$(caddy version)
    log_success "Caddy installed successfully: $VERSION"
else
    log_error "Caddy installation failed."
    exit 1
fi

log_success "Caddy setup completed!"
