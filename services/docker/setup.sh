#!/usr/bin/env bash

# ============================================
# DOCKER OFFICIAL INSTALLATION (PROD READY)
# ============================================

set -euo pipefail  # safer bash (exit on error, undefined var, pipe fail)

# --- Load Infrastructure ---
REPO_BASE="${REPO_BASE:-https://raw.githubusercontent.com/devlopersabbir/ops-toolkit/main}"

load_component() {
    local type=$1
    local file=$2

    if [ -f "../../$type/$file" ]; then
        source "../../$type/$file"
    elif [ -f "./$type/$file" ]; then
        source "./$type/$file"
    else
        source <(curl -fsSL "$REPO_BASE/$type/$file")
    fi
}

load_component "constants" "colors.sh"
load_component "libs" "logger.sh"
load_component "libs" "utils.sh"

# --- Main ---
log_header "DOCKER INSTALLATION (OFFICIAL)"

log_step "Detecting OS"
OS=$(detect_os)
[ "$OS" = "unknown" ] && log_error "Unsupported OS" && exit 1
log_success "OS detected: $OS"

# --- Remove old versions (official step) ---
log_step "Removing old Docker versions"
remove_old_docker() {
    if [ "$OS" = "debian" ]; then
        sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
    else
        sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
    fi
}
remove_old_docker

# --- Install dependencies ---
log_step "Installing dependencies"
install_dependencies() {
    if [ "$OS" = "debian" ]; then
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
    else
        sudo yum install -y yum-utils
    fi
}
install_dependencies

# --- Setup repository ---
log_step "Setting up Docker repository"

setup_repo_debian() {
    source /etc/os-release  # load ID, VERSION_CODENAME

    # Add GPG key (idempotent)
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL "https://download.docker.com/linux/${ID}/gpg" | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    # Add repo (avoid duplicate)
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    sudo apt-get update
}

setup_repo_redhat() {
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
}

if [ "$OS" = "debian" ]; then
    setup_repo_debian
else
    setup_repo_redhat
fi

# --- Install Docker ---
log_step "Installing Docker Engine"

install_docker() {
    if [ "$OS" = "debian" ]; then
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
}
install_docker

# --- Start & Enable service ---
log_step "Starting and enabling Docker"
sudo systemctl enable docker
sudo systemctl start docker

# --- Post setup ---
log_step "Configuring user permissions"
if getent group docker &>/dev/null; then
    sudo usermod -aG docker "$USER"
    log_info "Added '$USER' to docker group (re-login required)"
fi

# --- Verify ---
log_step "Verifying Docker installation"

if command -v docker &>/dev/null; then
    docker --version
    sudo docker run --rm hello-world >/dev/null 2>&1 && \
        log_success "Docker is working correctly" || \
        log_error "Docker installed but test failed"
else
    log_error "Docker installation failed"
    exit 1
fi

log_success "Docker setup completed successfully 🚀"
