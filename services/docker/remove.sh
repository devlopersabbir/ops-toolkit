#!/usr/bin/env bash

# ============================================
# DOCKER COMPLETE REMOVAL SCRIPT
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

log_header "DOCKER REMOVAL"

log_step "Detecting OS"
OS=$(detect_os)
[ "$OS" = "unknown" ] && log_error "Unsupported OS" && exit 1
log_success "OS detected: $OS"

log_step "Stopping services"
manage_service "stop" "docker.socket"
manage_service "stop" "docker"
manage_service "stop" "containerd"

log_step "Removing packages"
if [ "$OS" = "debian" ]; then
    remove_packages "$OS" "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin" "docker-ce-rootless-extras"
elif [ "$OS" = "redhat" ]; then
    remove_packages "$OS" "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
fi

log_step "Cleaning directories"
cleanup_dirs "/var/lib/docker" "/var/lib/containerd" "/etc/docker" "/var/run/docker.sock"

log_step "Removing user group"
if getent group docker &>/dev/null; then
    sudo groupdel docker || true
fi

log_success "Docker completely removed from system!"
