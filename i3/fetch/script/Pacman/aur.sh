#!/bin/bash
# Author: Gh0sT4n
# Script-AUR(AUR Helper)

#|| Color Config ||
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='033[0;36m'
NC='033[0m'

aur_update() {
    echo -e "${CYAN} ==> Updating AUR packages...${NC}"

    # cek helper AUR
    if command -v yay >/dev/null 2>&1; then
        helper="yay"
    elif command -v paru >/dev/null 2>&1; then
        helper="paru"
    elif command -v trizen >/dev/null 2>&1; then
        helper="trizen"
    else
        echo -e "${YELLOW} You not have AUR helper, choice option:${NC}"
        echo " 1. yay (default)"
        echo " 2. paru"
        echo " 3. trizen"
        echo " 4. skip"
        read -rp " Choice: " choice

        case $choice in
            2) helper="paru" ;;
            3) helper="trizen" ;;
            4) echo -e "${RED}Skip AUR update.${NC}"; return ;;
            *) helper="yay" ;;
        esac

        echo -e "${CYAN} Installing $helper ...${NC}"
        sudo pacman -Sy --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/$helper.git /tmp/$helper
        (cd /tmp/$helper && makepkg -si --noconfirm)
        rm -rf /tmp/$helper
    fi

    # update
    echo -e "${CYAN} Using $helper for update...${NC}"
    $helper -Syu --noconfirm

    echo -e "${GREEN} AUR packages updated successfully!${NC}"
}

#|| Running Program ||
aur_update
