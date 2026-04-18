#!/usr/bin/env bash

# --- Application Constants ---
REPO_BASE="https://raw.githubusercontent.com/devlopersabbir/ops-toolkit/main"

# List of available services (Name|Path)
SERVICES=(
    "Nginx (Remove)|nginx/remove.sh"
    "Caddy (Remove)|caddy/remove.sh"
    "Docker (Remove)|docker/remove.sh"
    "Docker (Setup Official)|docker/setup.sh"
)
