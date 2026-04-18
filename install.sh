#!/usr/bin/env bash

# ==============================================================================
# 🚀 DevOps Toolkit - Interactive Installer/Uninstaller
# ==============================================================================

set -e

# --- Initial Bootstrapping ---
LOCAL_REPO_BASE="https://raw.githubusercontent.com/devlopersabbir/ops-toolkit/main"
REPO_BASE="${REPO_BASE:-$LOCAL_REPO_BASE}"

# Helper to load components (constants or libs)
load_component() {
    local type=$1 # constants or libs
    local file=$2
    if [ -f "./$type/$file" ]; then source "./$type/$file";
    else source <(curl -fsSL "$REPO_BASE/$type/$file"); fi
}

# --- Load Infrastructure ---
load_component "constants" "app.sh"
load_component "constants" "colors.sh"
load_component "libs" "logger.sh"
load_component "libs" "utils.sh"

# --- Functions ---

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}======================================"
    echo -e "   ${ROCKET}  DevOps Cleanup Toolkit"
    echo -e "======================================${NC}\n"
}

check_dependencies() {
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed. Please install it first."
        exit 1
    fi
}

# --- State ---
SELECTED_STATES=($(for _ in "${SERVICES[@]}"; do echo 0; done))

show_menu() {
    print_banner
    echo -e "${BOLD}Select services to remove (Toggle with numbers, Enter to confirm, 'q' to quit):${NC}\n"
    for i in "${!SERVICES[@]}"; do
        local name="${SERVICES[$i]%%|*}"
        local status=" "
        [ "${SELECTED_STATES[$i]}" -eq 1 ] && status="${GREEN}${CHECK}${NC}"
        echo -e "  $((i+1))) [$status] ${name}"
    done
    echo -e "\n  q) Quit\n--------------------------------------"
}

# --- Main Logic ---

check_dependencies

while true; do
    show_menu
    read -p "Enter selection: " choice < /dev/tty
    case $choice in
        [1-9]*)
            idx=$((choice - 1))
            if [ $idx -lt ${#SERVICES[@]} ]; then
                SELECTED_STATES[$idx]=$((1 - SELECTED_STATES[$idx]))
            else
                log_error "Invalid option" && sleep 0.5
            fi
            ;;
        "")
            SELECTED_COUNT=$(echo "${SELECTED_STATES[@]}" | tr ' ' '\n' | grep -c 1 || true)
            if [ "$SELECTED_COUNT" -eq 0 ]; then
                log_warn "Please select at least one service." && sleep 1
                continue
            fi
            break
            ;;
        q|Q) log_info "Bye 👋" && exit 0 ;;
        *) log_error "Invalid option" && sleep 0.5 ;;
    esac
done

# --- Confirmation ---

print_banner
log_header "SELECTED SERVICES FOR REMOVAL"
FOR_EXECUTION=()
for i in "${!SERVICES[@]}"; do
    if [ "${SELECTED_STATES[$i]}" -eq 1 ]; then
        echo -e "  - ${YELLOW}${SERVICES[$i]%%|*}${NC}"
        FOR_EXECUTION+=("${SERVICES[$i]##*|}")
    fi
done

echo -e "\n${RED}${BOLD}${WARN} WARNING: This action is irreversible!${NC}"
read -p "Are you sure you want to proceed? (y/N): " confirm < /dev/tty
[[ ! "$confirm" =~ ^[yY]$ ]] && log_info "Operation cancelled." && exit 0

log_step "Starting removal process"

for target in "${FOR_EXECUTION[@]}"; do
    service_name="${target%%/*}"
    echo -e "${BLUE}---------- Processing ${service_name} ----------${NC}"
    if curl -fsSL "$REPO_BASE/services/$target" | REPO_BASE="$REPO_BASE" bash; then
        log_success "${service_name} removal completed."
    else
        log_error "Error removing ${service_name}."
        read -p "Continue with remaining? (y/N): " cont < /dev/tty
        [[ ! "$cont" =~ ^[yY]$ ]] && exit 1
    fi
done

log_success "All tasks completed!"
