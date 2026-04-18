#!/usr/bin/env bash

# ============================================
# DOCKER OFFICIAL SETUP SCRIPT
# ============================================
# Follows official Docker documentation for:
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

log_header "DOCKER INSTALLATION"

log_step "Detecting OS"
OS=$(detect_os)
[ "$OS" = "unknown" ] && log_error "Unsupported OS" && exit 1
log_success "OS detected: $OS"

log_step "Removing old versions"
if [ "$OS" = "debian" ]; then
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
elif [ "$OS" = "redhat" ]; then
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
fi

log_step "Setting up the repository"
if [ "$OS" = "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
elif [ "$OS" = "redhat" ]; then
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
fi

log_step "Installing Docker Engine"
if [ "$OS" = "debian" ]; then
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
elif [ "$OS" = "redhat" ]; then
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

log_step "Starting Docker"
manage_service "start" "docker"

log_step "Post-installation steps"
# Add current user to docker group if exists
if getent group docker &>/dev/null; then
    sudo usermod -aG docker $USER
    log_info "User '$USER' added to 'docker' group. Please log out and back in for changes to take effect."
fi

log_step "Verifying installation"
if command -v docker &>/dev/null; then
    VERSION=$(docker --version)
    log_success "Docker installed successfully: $VERSION"
else
    log_error "Docker installation failed."
    exit 1
fi

log_success "Docker setup completed!"
