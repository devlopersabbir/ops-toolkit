#!/usr/bin/env bash

# ============================================
# CADDY COMPLETE REMOVAL SCRIPT
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

log_header "CADDY REMOVAL"

log_step "Detecting OS"
OS=$(detect_os)
[ "$OS" = "unknown" ] && log_error "Unsupported OS" && exit 1
log_success "OS detected: $OS"

log_step "Stopping service"
manage_service "stop" "caddy"

log_step "Cleaning systemd"
clean_systemd "caddy"

log_step "Removing packages"
remove_packages "$OS" "caddy"

log_step "Cleaning directories"
cleanup_dirs "/etc/caddy" "/var/lib/caddy" "/var/log/caddy" "/usr/bin/caddy"

log_step "Removing user/group"
remove_user_group "caddy"

log_success "Caddy completely removed from system!"
