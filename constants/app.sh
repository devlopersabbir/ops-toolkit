#!/usr/bin/env bash

# --- Application Constants ---
REPO_BASE="https://raw.githubusercontent.com/devlopersabbir/ops-toolkit/main"

# List of available services (Name|Path)
SERVICES=(
    "Nginx|nginx/remove.sh"
    "Caddy|caddy/remove.sh"
    "Docker|docker/remove.sh"
)
