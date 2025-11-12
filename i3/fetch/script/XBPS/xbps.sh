#!/bin//bash
# Author: Mr-Yun1
# Script-Automation XBPS

#|| Color Config ||
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='033[0;34m'
CYAN='033[0;36m'
NC='\033[0m'

#|| Detect ||
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  elif type lsb_release >/dev/null 2>&1; then
    DISTRO="void"
  else
    DISTRO="unknown"
  fi

  case $DISTRO in
    "void")
      DISTRO="void"
  esac
  echo -e "${YELLOW} Detect Distro: $DISTRO${NC}"
}

clean_system() {
  echo -e "\n${YELLOW} Cleaning System...${NC}"
  case $DISTRO in
    "void")
      sudo -S sh -c 'xbps-remove -O'
      ;;
  esac
  echo -e "${GREEN} Cleaning Complete${NC}"
}

header() {
  clear
  echo -e "${GREEN}"
  echo -e " =<+>= Update XBPS Package =<+>="
  echo -e "${NC}"
}

#|| Upgrade XBPS ||
update_upgrade() {
  header
  while true; do
    echo -e "${CYAN} Menu Update & Upgrade System${NC}"

    read -p " Continue Update System [Y/n]? " response
    response=${response:-Y}

    if [[ "${response,,}" =~ ^(y|yes)$ ]]; then
      case $DISTRO in
        "void")
          echo -e "${GREEN} Using XBPS Package Manager${NC}"
          sudo xbps-install -Su
          ;;
        *)
          echo -e "${RED} Distro not recognized or Not Support!..${NC}"
          echo -e " Support Distro: Void(xbps)."
          exit 1
          ;;
      esac

      clean_system
      echo -e "\n${BLUE} Update Process Finished!..${NC}"

    else
       echo -e "${YELLOW} Canceled Update!${NC}"
    fi
  done
}
