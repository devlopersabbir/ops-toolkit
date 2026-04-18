#!/usr/bin/env bash

# Detect OS
detect_os() {
    if [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# Stop and disable a service
manage_service() {
    local action=$1
    local service=$2
    
    case $action in
        "stop")
            sudo systemctl stop "$service" 2>/dev/null || true
            sudo systemctl disable "$service" 2>/dev/null || true
            ;;
        "start")
            sudo systemctl start "$service" 2>/dev/null || true
            sudo systemctl enable "$service" 2>/dev/null || true
            ;;
    esac
}

# Clean systemd leftovers
clean_systemd() {
    local service=$2
    sudo rm -f "/etc/systemd/system/${service}.service" 2>/dev/null || true
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
}

# Remove packages based on OS
remove_packages() {
    local os=$1
    shift
    local packages=("$@")
    
    case $os in
        "debian")
            sudo apt-get purge -y "${packages[@]}" || true
            sudo apt-get autoremove -y
            ;;
        "redhat")
            sudo yum remove -y "${packages[@]}" || true
            ;;
    esac
}

# Remove directories if they exist
cleanup_dirs() {
    local dirs=("$@")
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            sudo rm -rf "$dir"
        fi
    done
}

# Remove user and group
remove_user_group() {
    local name=$1
    if id "$name" &>/dev/null; then
        sudo userdel -r "$name" || true
    fi
    if getent group "$name" &>/dev/null; then
        sudo groupdel "$name" || true
    fi
}
