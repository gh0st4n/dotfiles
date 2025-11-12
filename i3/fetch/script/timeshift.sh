#!/bin/bash
#================================================
# Timeshift Functions (check, snapshot, rollback)
# Author : Gh0sT4n
#================================================

#===============
#|| Warna     ||
#===============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#=================
#|| Animasi     ||
#=================
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

progress_bar() {
    local duration=${1}
    for ((i=0; i<=100; i++)); do
        sleep $duration
        printf "\r["
        for ((j=0; j<i; j++)); do printf "#"; done
        for ((j=i; j<100; j++)); do printf " "; done
        printf "] %d%%" $i
    done
    echo
}

scan_animation() {
    local msg="$1"
    echo -ne "${CYAN}${msg}${NC}"
    for i in {1..3}; do
        echo -n "."
        sleep 0.5
    done
    echo
}

#=======================
#|| Fungsi Timeshift  ||
#=======================

check_timeshift() {
    if ! command -v timeshift &>/dev/null; then
        echo -e "${RED}Timeshift Not Installed!${NC}"
        read -p "Install TimeShift? [y/N]: " install_ts
        if [[ "$install_ts" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            if [ -f /etc/debian_version ]; then
                sudo apt install timeshift -y
            elif [ -f /etc/arch-release ]; then
                if command -v yay &>/dev/null; then
                    yay -S timeshift --noconfirm
                elif command -v paru &>/dev/null; then
                    paru -S timeshift --noconfirm
                else
                    sudo pacman -S timeshift --noconfirm
                fi
            elif [ -f /etc/void-release ]; then
                sudo xbps-install -y timeshift
            elif [ -f /etc/fedora-release ]; then
                sudo dnf install timeshift -y
            else
                echo -e "${YELLOW}Unsupported distro, install manually.${NC}"
            fi
        else
            echo -e "${YELLOW}Continue Without Installation Timeshift${NC}"
            return 1
        fi
    fi
    return 0
}

create_snapshot() {
    echo -e "${CYAN}=== Create Timeshift Snapshot ===${NC}"

    # Pilih tipe snapshot
    echo -e "${YELLOW}1) RSYNC${NC}"
    echo -e "${YELLOW}2) BTRFS${NC}"
    read -p "Choose Snapshot Type [1-2]: " type_choice
    case $type_choice in
        1) SNAP_TYPE="RSYNC" ;;
        2) SNAP_TYPE="BTRFS" ;;
        *) SNAP_TYPE="RSYNC" ;;
    esac

    # Pilih lokasi penyimpanan
    read -p "Enter target device (default=/): " TARGET_DEV
    TARGET_DEV=${TARGET_DEV:-/}

    # Konfigurasi filter
    echo -e "${CYAN}Configure Filters:${NC}"
    echo "1) Include Root (/) ?"
    read -p "[Y/n]: " include_root
    echo "2) Include Home (/home) ?"
    read -p "[Y/n]: " include_home

    # Simpan config sementara
    echo "SNAP_TYPE=$SNAP_TYPE" > /tmp/ts_config
    echo "TARGET_DEV=$TARGET_DEV" >> /tmp/ts_config
    echo "ROOT=$include_root HOME=$include_home" >> /tmp/ts_config

    # Konfirmasi
    echo -e "${GREEN}=== Selected Config ===${NC}"
    cat /tmp/ts_config
    read -p "Continue create snapshot? [Y/n]: " confirm
    [[ "$confirm" =~ ^([nN][oO]|[nN])$ ]] && return 1

    # Eksekusi
    echo -e "${BLUE}Creating snapshot...${NC}"
    sudo timeshift --create --comments "Auto snapshot" --tags $SNAP_TYPE & spinner
    echo -e "${GREEN}Snapshot created!${NC}"

    # Tanya update config permanen
    read -p "Update timeshift config permanently? [y/N]: " update_conf
    if [[ "$update_conf" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        sudo cp /tmp/ts_config /etc/timeshift.conf
        echo -e "${GREEN}Config updated!${NC}"
    fi
}

list_snapshots() {
    echo -e "${CYAN}=== Available Snapshots ===${NC}"
    sudo timeshift --list | awk '
    BEGIN {print "-------------------------------------------------------------"}
    /Name/ {print "Name\t\tDate\t\t\tDevice\tTag"}
    /^[0-9]/ {printf "%s\t%s %s\t%s\t%s\n", $1, $2, $3, $4, $5}
    END {print "-------------------------------------------------------------"}'
}

timeshift_rollback() {
    echo -e "${CYAN}=== Timeshift Rollback ===${NC}"
    echo "1) Rollback to Latest Snapshot (default)"
    echo "2) Choose Snapshot"
    read -p "Choose [1-2]: " choice

    if [[ "$choice" == "2" ]]; then
        list_snapshots
        read -p "Enter snapshot name: " SNAP_NAME
        sudo timeshift --restore --snapshot "$SNAP_NAME" & spinner
    else
        sudo timeshift --restore --snapshot 'latest' & spinner
    fi

    echo -e "${GREEN}Rollback Done!${NC}"
    read -p "Reboot now? [Y/n]: " reboot_choice
    if [[ "$reboot_choice" =~ ^([yY][eE][sS]|[yY])$ || -z "$reboot_choice" ]]; then
        sudo reboot
    fi
}

timeshift_menu() {
    while true; do
        clear
        echo -e "${CYAN}==============================${NC}"
        echo -e "${GREEN}       Timeshift Manager       ${NC}"
        echo -e "${CYAN}==============================${NC}"
        echo "1. Check & Install Timeshift"
        echo "2. Create Snapshot"
        echo "3. List Snapshots"
        echo "4. Rollback Snapshot"
        echo "5. Exit"
        echo -e "${CYAN}==============================${NC}"
        read -rp "Choice [1-5]: " choice

        case $choice in
            1) check_timeshift ;;
            2) create_snapshot ;;
            3) list_snapshot ;;
            4) timeshift_rollback ;;
            5) echo -e "${YELLOW}Exiting Timeshift Manager...${NC}"; break ;;
            *) echo -e "${RED}Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

timeshift_menu

