#!/bin/bash
# Author: Gh0sT4n
# Script-Automation APT

#|| Color Config ||
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='033[0;33m'
BLUE='\0333[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#|| Detect ||
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  elif type lsb_release >/dev/null 2>&1; then
    DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
  elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
  else
    DISTRO="unknown"
  fi

  case $DISTRO in
    "ubuntu" | "linuxmint" | "pop" | "elementary" | "neon" | "zorin")
      DISTRO="debian"
      ;;
  esac
  echo -e "${YELLOW} Detect Distro: $DISTRO${NC}"
}

clean_system() {
  echo -e "\n${YELLOW} Cleaning System...${NC}"
  case $DISTRO in
    "debian")
      sudo -S sh -c 'apt autoremove -y && apt clean'
      ;;
  esac
  echo -e "${GREEN} Cleaning Complete!...${NC}"
}

#|| Header ||
header() {
  clear
  echo -e "${GREEN}"
  echo -e " =<+>= Update APT Package =<+>="
  echo -e "${NC}"
}

#|| Upgrade APT ||
update_upgrade() {
  header
  while true; do
    echo -e "\n${CYAN} Menu Update & Upgrade System${NC}"

    read -p " Continue Update System [Y/n]? " response
    response=${response:-Y}

    if [[ "${response,,}" =~ ^(y|yes)$ ]]; then
      case $DISTRO in
        "debian")
          echo -e "${GREEN} Using APT Package Manager${NC}"
          sudo apt update && sudo apt upgrade -y
          echo -e "\n${BLUE} Offers distro upgrade (if available)${NC}"
          read -p " Do a Distro Update[Y/n]? " dist_upgrade
          if [[ "$dist_upgrade" =~ ^(y|yes|ya|"")$ ]]; then
            sudo apt dist-upgrade -y
          fi
          ;;
        *)
          echo -e "${RED} Distro not recognized or Not Support!..${NC}"
          echo -e " Support Distro: Debian/Ubuntu(apt)."
          exit 1
          ;;
      esac

      clean_system
      echo -e "\n${BLUE} Update Process Finised!..${NC}"

    else
      echo -e "${YELLOW} Canceled Update${NC}"
    fi

  done
}

#|| Runing Program
detect_distro
update_upgrade
