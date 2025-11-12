#!/bin/bash
# Author : Gh0sT4n

#Color Config
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'

# Scan Animatin Config
scan_animation() {
local pid=$1
  local text=$2
  local delay=0.1
  local spin_chars= ('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  echo -ne "${CYAN}${text} ${spin_chars[0]${NC}}"

  while kill -0 $pid 2>/dev/null; do
    for char in "${spin_chars[@]}"; do
      echo -ne "\r${CYAN}${text} ${char}${NC}"
      sleep $delay
    done
  done
  echo -ne "\r${GREEN}${text} ✓${NC}"
}

full_system_scan() {
  echo -e "${RED} =<+>= FULL SYSTEM SCAN =<+>=${NC}"

  echo -e "${YELLOW} Maybe use long time for scanning${NC}"

  (sudo clamscan -r --bell -i /) &
  scan_animation $! " Running Full System Scan with ClamAV!..."

  echo -e "\n${GREEN} Full System Scanning Finish!!...${NC}"
}
