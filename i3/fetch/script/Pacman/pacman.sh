#!/bin/bash
# Author: Gh0sT4n
# Script-Automation Pacman

#|| Color Config ||
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='0033[0;36m'
NC='\033[0m'

#|| Detect ||
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  elif type lsb_release >/dev/null 2>&1; then
    DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lowe:]' )
  elif [ -f /etc/arch-release ]; then
    DISTRO="arch"
  else
    DISTRO="unknown"
  fi

  case $DISTRO in
    "manjaro" | "endevouros" | "garuda")
      DISTRO="arch"
      ;;
  esac
  echo -e "${YELLOW} Detect Distro: $DISTRO${NC}"
}

clean_system() {
  echo -e "\n${YELLOW} Cleaning System....${NC}"
  case $DISTRO in
    "arch")
      sudo -S sh -c 'pacman -Sc --noconfirm && pacman -Rns $(pacman -Qtdq) 2>/dev/null || echo " No Orphan Packages to Remove'
      ;;
  esac
  echo -e "${GREEN} Cleaning Complete!..${NC}"
}

header() {
  clear
  echo -e "${GREEN}"
  echo -e " =<+>= Update Pacman =<+>="
  echo -e "${NC}"
}

#|| Upgrade Pacman ||
update_upgrade() {
  header
  while true; do
    echo -e "\n${CYAN} Menu Update & Upgrade System${NC}"

    read -p " Continue Update System [Y/n]? " response
    response=${response:-Y}

    if [[ "${response,,}" =~ ^(y|yes|ya|"")$ ]]; then
      case $DISTRO in
        "arch")
          echo -e "${GREEN} Using Pacman Packages Manager${NC}"
          sudo pacman -Syu --noconfirm
          ;;
      esac

      clean_system
      echo -e "\n${BLUE} Update Process Finished!..${NC}"

    else
      echo -e "\n${YELLOW} Canceled Update${NC}"
    fi

  done
}
