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
    if [ -f "./$type/$file" ]; then
        source "./$type/$file"
    else
        source <(curl -fsSL "$REPO_BASE/$type/$file")
    fi
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
# Initialize states as 0 (not selected)
declare -a SELECTED_STATES
for i in "${!SERVICES[@]}"; do
    SELECTED_STATES[$i]=0
done

show_menu() {
    print_banner
    echo -e "${BOLD}Select services to remove:${NC}"
    echo -e "${BLUE}Tip: Enter numbers (e.g. '1 2'), then press Enter to confirm.${NC}\n"
    
    for i in "${!SERVICES[@]}"; do
        local name="${SERVICES[$i]%%|*}"
        local status=" "
        [ "${SELECTED_STATES[$i]}" -eq 1 ] && status="${GREEN}${CHECK}${NC}"
        echo -e "  $((i+1))) [$status] ${name}"
    done
    
    echo -e "\n  f) ${GREEN}${BOLD}Finish & Proceed${NC}"
    echo -e "  q) Quit"
    echo -e "\n--------------------------------------"
}

# --- Main Logic ---

check_dependencies

while true; do
    show_menu
    read -p "Your choice: " user_input < /dev/tty
    
    # Trim whitespace
    user_input=$(echo "$user_input" | xargs)
    
    # Handle empty input
    if [[ -z "$user_input" ]]; then
        # Check if anything selected to decide whether to proceed or warn
        SELECTED_COUNT=0
        for s in "${SELECTED_STATES[@]}"; do ((SELECTED_COUNT += s)); done
        
        if [ "$SELECTED_COUNT" -gt 0 ]; then
            break # Exit loop and proceed
        else
            log_warn "Please select at least one service by entering its number."
            sleep 1
            continue
        fi
    fi

    # Handle commands
    case $user_input in
        f|F|finish|FINISH)
            SELECTED_COUNT=0
            for s in "${SELECTED_STATES[@]}"; do ((SELECTED_COUNT += s)); done
            if [ "$SELECTED_COUNT" -gt 0 ]; then break; else log_warn "Select something first!"; sleep 1; continue; fi
            ;;
        q|Q|exit|quit)
            log_info "Bye 👋"
            exit 0
            ;;
    esac

    # Handle multiple selections (e.g. "1 2 3")
    VALID_INPUT=false
    for choice in $user_input; do
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            idx=$((choice - 1))
            if [ $idx -ge 0 ] && [ $idx -lt ${#SERVICES[@]} ]; then
                SELECTED_STATES[$idx]=$((1 - SELECTED_STATES[$idx]))
                VALID_INPUT=true
            fi
        fi
    done

    if [ "$VALID_INPUT" = false ]; then
        log_error "Invalid selection: $user_input"
        sleep 1
    fi
done

# --- Confirmation & Execution ---

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

if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    log_info "Operation cancelled."
    exit 0
fi

log_step "Starting removal process"

for target in "${FOR_EXECUTION[@]}"; do
    service_name="${target%%/*}"
    echo -e "\n${BLUE}---------- Processing ${service_name} ----------${NC}"
    
    # Execute the remote script
    if curl -fsSL "$REPO_BASE/services/$target" | REPO_BASE="$REPO_BASE" bash; then
        log_success "${service_name} removal completed."
    else
        log_error "Error removing ${service_name}."
        read -p "Continue with remaining tasks? (y/N): " cont < /dev/tty
        [[ ! "$cont" =~ ^[yY]$ ]] || exit 1
    fi
done

log_success "All selected tasks completed!"
