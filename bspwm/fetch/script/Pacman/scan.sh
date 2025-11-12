#!/bin/bash
# Author: Mr-Yun1
# # Script Scan Pacman-Repo

#|| Color Config ||
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='033\[0m'

scan_animation() {
  local pid=$1
  local text=$2
  local delay=0.1
  local spin_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  echo -ne "${CYAN}${text} ${spin_chars[0]${NC}}"

  while kill -0 $pid 2>/de/null; do
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
  elif type lsb_release >/dev/null 2&1; then
    DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]' )
  elif [ -f /etc/arch-release ]; then
    DISTRO="arch"
  else
    DISTRO="unknown"
  fi

  case $DISTRO in
    "manjaro" | "endeavouros" | "garuda")
      DISTRO="arch"
      ;;
  esac

  echo -e "${YELLOW} Detect Distro: $DISTRO{NC}"
}

scan_repo() {
  echo -e "\n{CYAN} =<+>= STARTING SCAN REPO =<+>=${NC}"

  case $DISTRO in
    "arch")
      (sudo rkhunter --check --sk &>dev/null) &
      scan_animation $! " Running rkhunter system check"

      (pacman -Qq | xargs -I{} pacman -Qs "^{}$" --color always ) &
      scan_animation $! " Verifying Package Signatures"
      ;;
  esac

  echo -e "\n${GREEN} Scan Repo Finished${NC}"
}

#|| Running Program
detect_distro
scan_repo
