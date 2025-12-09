#!/bin/bash
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color
# Header function
print_header() {
    clear
    echo -e "${BLUE}${BOLD}=================================================${NC}"
    echo -e "${BLUE}${BOLD}      Interactive System Information Tool        ${NC}"
    echo -e "${BLUE}${BOLD}=================================================${NC}"
    echo ""
}
# Pause function
pause() {
    echo ""
    read -p "Press [Enter] key to continue..."
}
# Function to check command availability
check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${YELLOW}Warning: Command '$1' not found. Some info might be missing.${NC}"
        return 1
    fi
    return 0
}
# 1. System Overview
system_overview() {
    echo -e "${GREEN}${BOLD}--- System Overview ---${NC}"
    echo -e "${BOLD}Hostname:${NC} $(hostname)"
    echo -e "${BOLD}Uptime:${NC} $(uptime -p)"
    echo -e "${BOLD}Current Time:${NC} $(date)"
    echo ""
    echo -e "${BOLD}OS Information:${NC}"
    if [ -f /etc/os-release ]; then
        cat /etc/os-release | grep -E '^(NAME|VERSION|ID|PRETTY_NAME)=' | sed 's/^/  /'
    else
        echo "  /etc/os-release not found."
    fi
    echo ""
    echo -e "${BOLD}Kernel Version:${NC} $(uname -sr)"
    echo -e "${BOLD}Architecture:${NC} $(uname -m)"
    echo ""
    echo -e "${BOLD}Logged in Users:${NC}"
    who
}
# 2. CPU & Memory
cpu_memory_info() {
    echo -e "${GREEN}${BOLD}--- CPU Information ---${NC}"
    if check_cmd lscpu; then
        lscpu | grep -E 'Architecture|CPU\(s\):|Model name|Thread\(s\) per core|Core\(s\) per socket|Socket\(s\)|MHz'
    else
        grep -m 1 'model name' /proc/cpuinfo
        grep -m 1 'cpu cores' /proc/cpuinfo
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}--- Memory Information ---${NC}"
    free -h
    echo ""
    echo -e "${BOLD}Top 5 Memory Consuming Processes:${NC}"
    # Formatted ps output: User, PID, CPU%, Mem%, Start Time, Command (truncated)
    ps -eo user:12,pid:8,%cpu:6,%mem:6,start:10,comm:25 --sort=-%mem | head -n 6
    
    echo ""
    echo -e "${CYAN}${BOLD}Legend:${NC}"
    echo -e "  ${BOLD}USER${NC}: Process Owner   ${BOLD}PID${NC}: Process ID"
    echo -e "  ${BOLD}%CPU${NC}: CPU Usage %     ${BOLD}%MEM${NC}: RAM Usage %"
    echo -e "  ${BOLD}START${NC}: Start Time     ${BOLD}COMMAND${NC}: Process Name"
}
# 3. Storage & Filesystems
storage_info() {
    echo -e "${GREEN}${BOLD}--- Block Devices ---${NC}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
    echo ""
    echo -e "${GREEN}${BOLD}--- Disk Usage ---${NC}"
    df -hT --exclude-type=tmpfs --exclude-type=devtmpfs
    echo ""
    echo -e "${GREEN}${BOLD}--- Mounted Filesystems ---${NC}"
    mount | column -t | head -n 10
    echo "... (truncated)"
}
# 4. Hardware Devices
hardware_info() {
    echo -e "${GREEN}${BOLD}--- PCI Devices ---${NC}"
    if check_cmd lspci; then
        lspci
    else
        echo "lspci not found."
    fi
    echo ""
    echo -e "${GREEN}${BOLD}--- USB Devices ---${NC}"
    if check_cmd lsusb; then
        lsusb
    else
        echo "lsusb not found."
    fi
    echo ""
    echo -e "${GREEN}${BOLD}--- Input Devices ---${NC}"
    grep -E 'Name|Handlers' /proc/bus/input/devices | paste - -
}
# 5. Network Information
network_info() {
    echo -e "${GREEN}${BOLD}--- IP Addresses ---${NC}"
    ip -c addr show
    echo ""
    echo -e "${GREEN}${BOLD}--- Routing Table ---${NC}"
    ip -c route show
    echo ""
    echo -e "${GREEN}${BOLD}--- DNS Configuration ---${NC}"
    cat /etc/resolv.conf | grep -v '^#'
    echo ""
    echo -e "${GREEN}${BOLD}--- Listening Ports (TCP) ---${NC}"
    ss -tulpn | head -n 10
    echo ""
    echo -e "${GREEN}${BOLD}--- Network Manager Status ---${NC}"
    if check_cmd nmcli; then
        nmcli general status
    fi
}
# 6. Low-Level / Kernel
kernel_info() {
    echo -e "${GREEN}${BOLD}--- Kernel Modules (Loaded) ---${NC}"
    lsmod | head -n 10
    echo "... (total: $(lsmod | wc -l))"
    echo ""
    echo -e "${GREEN}${BOLD}--- Interrupts (Top 10) ---${NC}"
    head -n 10 /proc/interrupts
    echo ""
    echo -e "${GREEN}${BOLD}--- Kernel Boot Parameters ---${NC}"
    cat /proc/cmdline
}
# 7. Container Information
container_info() {
    echo -e "${GREEN}${BOLD}--- Docker Containers ---${NC}"
    if check_cmd docker; then
        if docker ps >/dev/null 2>&1; then
            docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | head -n 10
        else
            echo "Docker daemon not running or permission denied."
        fi
    else
        echo "Docker not found."
    fi
    echo ""
    echo -e "${GREEN}${BOLD}--- Podman Containers ---${NC}"
    if check_cmd podman; then
        podman ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | head -n 10
    else
        echo "Podman not found."
    fi
}

# 8. System Services
service_info() {
    echo -e "${GREEN}${BOLD}--- Failed Systemd Services ---${NC}"
    if check_cmd systemctl; then
        systemctl list-units --state=failed --no-pager
    else
        echo "systemctl not found."
    fi
}

# 9. Package Updates
package_info() {
    echo -e "${GREEN}${BOLD}--- Available Updates ---${NC}"
    echo "Checking for updates (this might take a moment)..."
    
    # Check for Nobara Logic
    if [ -f /etc/os-release ]; then
        # Run in a subshell to avoid polluting checks
        (
            . /etc/os-release
            if [[ "$ID" == "nobara" ]]; then
                echo -e "${YELLOW}Nobara Linux detected. Using 'nobara-sync cli'...${NC}"
                if command -v nobara-sync &> /dev/null; then
                     nobara-sync cli
                     exit 0
                else
                     echo -e "${RED}Error: 'nobara-sync' command not found.${NC}"
                     exit 1
                fi
            fi
            exit 2 # Not Nobara
        )
        # Check exit code of subshell
        ret=$?
        if [ $ret -eq 0 ]; then return; fi
        if [ $ret -eq 1 ]; then return; fi
        # If 2, continue to standard checks
    fi

    if check_cmd dnf; then
        dnf check-update --quiet | head -n 10
    elif check_cmd apt; then
        apt list --upgradable 2>/dev/null | head -n 10
    elif check_cmd pacman; then
        if check_cmd checkupdates; then
             checkupdates | head -n 10
        else
             echo "checkupdates command not found (install pacman-contrib)."
        fi
    else
        echo "No supported package manager found for update check."
    fi
}

# 10. JSON Export
generate_json() {
    JSON_FILE="system_info_$(date +%Y%m%d_%H%M%S).json"
    echo "Exporting system info to $JSON_FILE..."
    
    # Simple JSON construction
    cat <<EOF > "$JSON_FILE"
{
  "hostname": "$(hostname)",
  "uptime": "$(uptime -p)",
  "date": "$(date)",
  "kernel": "$(uname -sr)",
  "architecture": "$(uname -m)",
  "cpu_model": "$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)",
  "memory_total": "$(free -h | grep Mem | awk '{print $2}')",
  "disk_usage_root": "$(df -h / | tail -1 | awk '{print $5}')"
}
EOF
    echo -e "${GREEN}JSON export saved to $JSON_FILE${NC}"
    pause
}

# 11. Tech Glossary
glossary_info() {
    echo -e "${GREEN}${BOLD}--- Tech Glossary & Cheat Sheet ---${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}1. Storage & Memory${NC}"
    echo -e "   - ${BOLD}GB vs GiB${NC}: GB=1000^3 (Marketing), GiB=1024^3 (Real Size). 500GB = 465GiB."
    echo -e "   - ${BOLD}RAM${NC}: Fast, temporary workspace. Wiped on restart."
    echo -e "   - ${BOLD}Swap${NC}: Emergency RAM on your hard drive. Slow, prevents crashes."
    echo -e "   - ${BOLD}Filesystem${NC}: How data is organized (e.g., ext4, ntfs)."
    echo ""

    echo -e "${CYAN}${BOLD}2. CPU & Architecture${NC}"
    echo -e "   - ${BOLD}x64 / amd64${NC}: Modern 64-bit chips. Standard for desktops/laptops."
    echo -e "   - ${BOLD}ARM / aarch64${NC}: Power-efficient chips (Phones, Macs, Raspberry Pi)."
    echo -e "   - ${BOLD}Load Avg${NC}: CPU busyness. 1.0 = 1 core 100% busy."
    echo ""

    echo -e "${CYAN}${BOLD}3. Network Lingo${NC}"
    echo -e "   - ${BOLD}IP Address${NC}: Your computer's ID card on the network."
    echo -e "   - ${BOLD}DNS${NC}: Internet phonebook (google.com -> 142.250...)."
    echo -e "   - ${BOLD}TCP vs UDP${NC}: TCP = Receipt required (Web). UDP = Throw it (Gaming)."
    echo ""

    echo -e "${CYAN}${BOLD}4. System Jargon${NC}"
    echo -e "   - ${BOLD}PID${NC}: Process ID. Unique number for every running program."
    echo -e "   - ${BOLD}Kernel${NC}: The core of the OS. Controls hardware."
    echo -e "   - ${BOLD}Daemon${NC}: A background service (invisible worker)."
    echo -e "   - ${BOLD}Root${NC}: The Superuser/Administrator (God mode)."
    echo -e "   - ${BOLD}Distro${NC}: Flavor of Linux (Ubuntu, Fedora, Arch, etc.)."
    echo ""
}

# 12. Setup Shell
setup_shell() {
    echo -e "${GREEN}${BOLD}--- Setup Shell (Zsh + Syntax Highlighting) ---${NC}"
    
    if [ ! -f /etc/os-release ]; then
        echo -e "${RED}Error: Cannot detect OS (no /etc/os-release). Aborting.${NC}"
        pause
        return
    fi
    
    # Source os-release to get ID
    . /etc/os-release
    
    echo "Detected OS: $NAME ($ID)"
    echo "This will install 'zsh' and 'zsh-syntax-highlighting' using your package manager."
    echo -e "${YELLOW}Administrator privileges (sudo) may be required.${NC}"
    echo ""
    read -p "Do you want to proceed? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted."
        pause
        return
    fi
    
    echo ""
    case "$ID" in
        ubuntu|debian|kali|pop|linuxmint)
            echo "Using apt..."
            sudo apt update
            if sudo apt install -y zsh zsh-syntax-highlighting; then
                 echo -e "${GREEN}Installation complete!${NC}"
            else
                 echo -e "${RED}Installation failed.${NC}"
            fi
            ;;
        fedora|rhel|centos|nobara)
            echo "Using dnf..."
            if sudo dnf install -y zsh zsh-syntax-highlighting; then
                 echo -e "${GREEN}Installation complete!${NC}"
            else
                 echo -e "${RED}Installation failed.${NC}"
            fi
            ;;
        arch|manjaro|endeavouros)
            echo "Using pacman..."
            if sudo pacman -S --noconfirm zsh zsh-syntax-highlighting; then
                 echo -e "${GREEN}Installation complete!${NC}"
            else
                 echo -e "${RED}Installation failed.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Unsupported OS distribution: $ID${NC}"
            echo "Please install 'zsh' and 'zsh-syntax-highlighting' manually."
            ;;
    esac
    
    # Check if zsh is installed
    if command -v zsh &> /dev/null; then
        echo -e "Zsh version: $(zsh --version)"
    fi
    
    pause
}

# Generate Full Report
generate_report() {
    REPORT_FILE="system_report_$(date +%Y%m%d_%H%M%S).txt"
    echo "Generating full report to $REPORT_FILE..."
    
    {
        echo "========================================="
        echo "      FULL SYSTEM INFORMATION REPORT     "
        echo "========================================="
        echo "Generated on: $(date)"
        echo ""
        
        echo "=== SYSTEM OVERVIEW ==="
        system_overview
        echo ""
        
        echo "=== CPU & MEMORY ==="
        cpu_memory_info
        echo ""
        
        echo "=== STORAGE ==="
        storage_info
        echo ""
        
        echo "=== HARDWARE ==="
        hardware_info
        echo ""
        
        echo "=== NETWORK ==="
        network_info
        echo ""
        
        echo "=== KERNEL ==="
        kernel_info
        echo ""

        echo "=== CONTAINERS ==="
        container_info
        echo ""

        echo "=== FAILED SERVICES ==="
        service_info
        echo ""
        
    } > "$REPORT_FILE"
    
    # Remove color codes from the report file for better readability in text editors
    sed -i 's/\x1b\[[0-9;]*m//g' "$REPORT_FILE"
    
    echo -e "${GREEN}Report saved successfully to $REPORT_FILE${NC}"
    pause
}
# Main Menu Loop
# Generic Interactive Menu
# Arguments: title, options_array_name
# Returns: selected index in global variable 'MENU_SELECTED_INDEX'
interactive_menu() {
    local title="$1"
    local -n opts=$2
    local selected=0
    
    # Internal loop for this specific menu
    while true; do
        clear
        echo -e "${BLUE}${BOLD}=================================================${NC}"
        echo -e "${BLUE}${BOLD}      Interactive System Information Tool        ${NC}"
        echo -e "${BLUE}${BOLD}=================================================${NC}"
        echo ""
        echo -e "${YELLOW}${BOLD}:: $title ::${NC}"
        echo "Use ${BOLD}Up/Down${NC} to navigate, ${BOLD}Enter${NC} to select."
        echo ""

        for i in "${!opts[@]}"; do
            if [[ "$i" == "$selected" ]]; then
                echo -e "${GREEN}${BOLD}> ${opts[$i]} <${NC}"
            else
                echo -e "  ${opts[$i]}"
            fi
        done
        echo ""

        # Input handling
        read -rsn1 input
        if [[ "$input" == $'\x1b' ]]; then
            read -rsn2 -t 0.1 input
            if [[ "$input" == "[A" ]]; then # Up
                ((selected--))
                if ((selected < 0)); then selected=$((${#opts[@]} - 1)); fi
            elif [[ "$input" == "[B" ]]; then # Down
                ((selected++))
                if ((selected >= ${#opts[@]})); then selected=0; fi
            fi
        elif [[ "$input" == "" ]]; then # Enter
            MENU_SELECTED_INDEX=$selected
            return 0
        fi
    done
}

# --- Submenus ---

submenu_hardware() {
    local options=(
        "System Overview"
        "CPU & Memory Information"
        "Storage & Filesystems"
        "Hardware Devices (PCI/USB)"
        "Low-Level / Kernel Info"
        "Back to Main Menu"
    )
    while true; do
        interactive_menu "Hardware & Core Info" options
        case $MENU_SELECTED_INDEX in
            0) clear; system_overview; pause ;;
            1) clear; cpu_memory_info; pause ;;
            2) clear; storage_info; pause ;;
            3) clear; hardware_info; pause ;;
            4) clear; kernel_info; pause ;;
            5) return ;;
        esac
    done
}

submenu_network() {
    local options=(
        "Network Information"
        "Container Information"
        "Failed System Services"
        "Back to Main Menu"
    )
    while true; do
        interactive_menu "Network & Services" options
        case $MENU_SELECTED_INDEX in
            0) clear; network_info; pause ;;
            1) clear; container_info; pause ;;
            2) clear; service_info; pause ;;
            3) return ;;
        esac
    done
}

submenu_tools() {
    local options=(
        "Check Package Updates"
        "Setup Shell (Install Zsh + Syntax Highlighting)"
        "Launch Live Dashboard (TUI)"
        "Back to Main Menu"
    )
    while true; do
        interactive_menu "Tools & Maintenance" options
        case $MENU_SELECTED_INDEX in
            0) clear; package_info; pause ;;
            1) clear; setup_shell ;;
            2) ./dashboard.sh ;;
            3) return ;;
        esac
    done
}

submenu_reports() {
    local options=(
        "Generate Full Report (Save to file)"
        "Export to JSON"
        "Tech Glossary (What do these terms mean?)"
        "Back to Main Menu"
    )
    while true; do
        interactive_menu "Reports & Help" options
        case $MENU_SELECTED_INDEX in
            0) generate_report ;;
            1) generate_json ;;
            2) clear; glossary_info; pause ;;
            3) return ;;
        esac
    done
}

# Main Menu Loop
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_options=(
        "Hardware & Core Info"
        "Network & Services"
        "Tools & Maintenance"
        "Reports & Help"
        "Exit"
    )

    while true; do
        interactive_menu "Main Menu" main_options
        case $MENU_SELECTED_INDEX in
            0) submenu_hardware ;;
            1) submenu_network ;;
            2) submenu_tools ;;
            3) submenu_reports ;;
            4) echo "Exiting..."; exit 0 ;;
        esac
    done
fi