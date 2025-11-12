#!/bin/bash
# Author: Mr-Yun1
# Script Main Menu Debian-Based(APT) OS

#|| Color ||
RED='\033[0;031m'
GREEN='\033[o;32m'
NC='\033[0m;'

#|| Variabel ||
#APT='$HOME/script/Apt/apt.sh'
#CLEAN='$HOME/script/Apt/clean.sh'
#SCAN='$HOME/script/Apt/scan.sh'

#Fetch='$HOME/script/fetch.sh'

header() {
  clear
  echo -e "${RED} |+| Main Menu APT |+|${NC}"
}

main_menu() {
  while true; do
    header
    echo -e " 1. APT(Update & Upgrade)"
    echo -e " 2. Clean"
    echo -e " 3. Scan"
    echo -e " 4. Exit (Press Enter or 4 to Exit)"

    read -p " Choice option [1-4] (Default 4): " menu_choice

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
        $APT
        ;;
      2)
        $CLEAN
        ;;
      3)
        $SCAN
        ;;
      *)
        echo -e "\n${RED} Invalid Choice! Please Select Between 1-4${NC}"
        sleep 1
        continue
        ;;
      esac

      read -p " Press Enter to Return to Main Menu"
    done
}

#|| Running Program ||
main_menu
