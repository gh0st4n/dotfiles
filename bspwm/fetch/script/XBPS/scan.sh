#!/bin/bash
# Author: Mr-Yun1
# Script Scan XBPS-Repo

#|| Color Config ||
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

scan_animation() {
  local pid=$1
  local text=$2
  local delay=0.1
  local spin_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  echo -ne "${CYAN}${text} ${spin_chars[0]${NC}}"

  while kill -0 $pid 2>/dev/null; do
    for char in "${spin_chars[@]}"; do
      echo -ne "\r${CYAN}${text} ${char}${NC}"
      sleep $delay
    done
  done
  echo -ne "\r${GREEN}${text} ✓${NC}"
}

detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  elif type lsb_release >/dev/null 2>&1; then
    DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
  elif [ -f /etc/void-release ]; then
    DISTRO="void"
  else
    DISTRO="unknown"
  fi

  case $DISTRO in
    "void")
      DISTRO="void"
      ;;
  esac

  echo -e "${YELLOW} Detect Distro: $DISTRO${NC}"
}

scan_repo() {
  echo -e "${CYAN} =<+>= STARTING SCAN REPO =<+>="

  case $DISTRO in
    "void")
      echo -e "${GREEN} Checking Package Checksum${NC}"
      (sudo xbps-pkgdb -a $>/de/null) &
      scan_animation $! "Checking Packages Checksum"
      ;;
  esac

  echo -e "\n${GREEN} Scan Repo Finished"
}

#|| Running Program ||
detect_distro
scan_repo
