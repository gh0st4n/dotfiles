#!/bin/bash
# Author: Gh0sT4n
# Script Main Menu Arch-Based(pacman) OS

#|| Color ||
RED='\033[0;031m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m;'

#|| Variabel ||
#PACMAN='$HOME/script/Pacman/pacman.sh'
#AUR='$HOME/script/Pacman/aur.sh'
#CLEAN='$HOME/script/Pacman/clean.sh'
#SCAN='$HOME/script/Pacman/scan.sh'

#Fetch='$HOME/script/fetch.sh'

header() {
  clear
  echo -e "${BLUE} |+| Main Menu Pacman |+|${NC}"
}

main_menu() {
  while true; do
    header
    echo -e " 1. Pacman(Update & Upgrade)"
    echo -e " 2. AUR(Update & Upgrade)"
    echo -e " 3. Clean"
    echo -e " 4. Scan"
    echo -e " 5. Exit (Press Enter or 5 to Exit)"

    read -p " Choice option [1-5] (Default): " menu_choice

    if [[ -z "$menu_choice" || "$menu_choice" == "4" ]]; then
      clear
      echo -e "\n${GREEN} Exiting Script...${NC}"
      if [ -f $Fetch ]; then
        $Fetch
      else
        echo -e "${RED} Not Found File Fetch!!!...(fetch.sh: ?)${NC}"
      fi
      exit 0
    fi

    case $menu_choice in
      1)
        $PACMAN
        ;;
      2)
        $AUR
        ;;
      3)
        $CLEAN
        ;;
      4)
        $SCAN
        ;;
      *)
        echo -e "\n${RED} Invalid Choice! Please Select Between 1-5${NC}"
        sleep 1
        continue
        ;;
      esac

      read -p " Press Enter To Return to Main Menu"
    done
}

#|| Running Program ||
main_menu
