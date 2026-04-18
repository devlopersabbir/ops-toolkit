#!/usr/bin/env bash

# ============================================
# NGINX COMPLETE REMOVAL SCRIPT
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

log_header "NGINX REMOVAL"

log_step "Detecting OS"
OS=$(detect_os)
[ "$OS" = "unknown" ] && log_error "Unsupported OS" && exit 1
log_success "OS detected: $OS"

log_step "Stopping service"
manage_service "stop" "nginx"

log_step "Cleaning systemd"
clean_systemd "nginx"

log_step "Removing packages"
remove_packages "$OS" "nginx" "nginx-common" "nginx-full" "nginx-core"

log_step "Cleaning directories"
cleanup_dirs "/etc/nginx" "/var/log/nginx" "/var/cache/nginx" "/usr/share/nginx" "/var/www/html"

log_step "Removing user/group"
remove_user_group "nginx"

log_step "Verifying removal"
if command -v nginx &>/dev/null; then
    log_warn "nginx binary still exists!"
else
    log_success "nginx binary removed"
fi

log_success "Nginx completely removed from system!"
