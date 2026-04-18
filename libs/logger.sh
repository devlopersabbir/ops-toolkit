#!/usr/bin/env bash

# --- Load Constants ---
REPO_BASE="${REPO_BASE:-https://raw.githubusercontent.com/devlopersabbir/ops-toolkit/main}"

load_const() {
    local file=$1
    if [ -f "../constants/$file" ]; then source "../constants/$file";
    elif [ -f "./constants/$file" ]; then source "./constants/$file";
    else source <(curl -fsSL "$REPO_BASE/constants/$file"); fi
}

load_const "colors.sh"

# --- Logger Functions ---

log_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

log_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}${WARN} $1${NC}"
}

log_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

log_header() {
    echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}"
}

log_step() {
    echo -e "${CYAN}${GEAR} $1...${NC}"
}
