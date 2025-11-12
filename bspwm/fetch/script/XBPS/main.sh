#!/bin/bash
# Author: Mr-Yun1
# Void-Based(xbps) OS

#|| Color ||
RED='033[0;31m'
GREEN='033[0;32m'
NC='\033[0m;'

#|| Variabel ||
#XBPS='$HOME/script/XBPS/xbps.sh'
#CLEAN='$HOME/script/XBPS/clean.sh'
#SCAN='$HOME/script/XBPS/scan.sh'

#Fetch='$HOME/script/fetch.sh'

header() {
  echo -e "${GREEN} |+| Main Menu XBPS |+|"
}

main_menu() {
  while true; do
    header
    echo -e " 1. XBPS(Update & Upgrade)"
    echo -e " 2. CLean"
    echo -e " 3. Scan"
    echo -e " 4. Exit (Press Enter or 4 to Exit)"

    read -p " Choose Option [1-4] (Default 4): " menu_choice

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

    case $main_menu in
      1)
        $XBPS
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

main_menu
