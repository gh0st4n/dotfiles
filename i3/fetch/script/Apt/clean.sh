#!/bin/bash
# Author: Mr-Yun1
# Script-Clean(APT-Package)

set -Eeuo pipefail
IFS=$'\n\t'

VERSION="1.0.0"

# ===== Colors =====
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"; RED="$(tput setaf 1)"
  CYAN="$(tput setaf 6)"; BOLD="$(tput bold)"; RESET="$(tput sgr0)"
else
  GREEN=""; YELLOW=""; RED=""; CYAN=""; BOLD=""; RESET=""
fi

log()  { printf "%s[*]%s %s\n" "$CYAN" "$RESET" "$*"; }
ok()   { printf "%s[+]%s %s\n" "$GREEN" "$RESET" "$*"; }
warn() { printf "%s[!]%s %s\n" "$YELLOW" "$RESET" "$*"; }
err()  { printf "%s[x]%s %s\n" "$RED" "$RESET" "$*"; }

on_error() { err " An Error Occurred in Line $BASH_LINENO (Exit Code: $?)"; }
trap on_error ERR

# ===== Globals =====
AUTO_YES=false
MODE=""
JOURNAL_DAYS="${JOURNAL_DAYS:-7}"
DO_TRIM=true
FETCH_SCRIPT="${FETCH_SCRIPT:-$HOME/.File-sh/scripts/minifetch.sh}"

# ===== Helpers =====
need_sudo() {
  if [[ $EUID -ne 0 ]]; then sudo "$@"; else "$@"; fi
}

cmd_exists() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  $AUTO_YES && return 0
  read -rp " Continue? [Y/n] " ans
  [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

usage() {
  cat <<EOF
${BOLD} clean-apt.sh${RESET} v$VERSION
 Bersihkan sistem Debian/Ubuntu dengan aman.

 Usage:
   $0 [--mode fast|light|full] [-y|--yes]
      [--journal-days N] [--no-trim]

 Opsi:
   --mode           fast (cache+log+tmp),
                    light (fast + orphan + TRIM),
                    full (light + deteksi service)
   -y, --yes        Non-interaktif (auto "Yes")
   --journal-days   Retensi journalctl (default: $JOURNAL_DAYS hari)
   --no-trim        Lewati TRIM SSD
   -h, --help       Tampilkan bantuan

 Tanpa --mode, akan muncul menu interaktif.
EOF
}

# ===== Parse Args =====
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-}"; shift 2 ;;
    -y|--yes) AUTO_YES=true; shift ;;
    --journal-days) JOURNAL_DAYS="${2:-7}"; shift 2 ;;
    --no-trim) DO_TRIM=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err " Unknown Argument: $1"; usage; exit 1 ;;
  esac
done

# ===== Validasi =====
if ! cmd_exists apt-get; then
  err " apt-get Not Found.This Script is Only for Debian,Ubuntu/APT-Package."
  exit 1
fi

# ===== Tasks =====
clean_cache_apt() {
  log " Cleaning Cache APT..."
  need_sudo apt-get clean -y
  need_sudo apt-get autoclean -y
  ok " APT Cache is Cleared."
}

remove_orphans() {
  log " Removing orphan Package(autoremove)..."
  need_sudo apt-get autoremove --purge -y
  ok " Package orphan/autoremove is Deleted!"
}

clean_journal() {
  if cmd_exists journalctl; then
    log " Cleaning log systemd (> ${JOURNAL_DAYS} Day)..."
    need_sudo journalctl --vacuum-time="${JOURNAL_DAYS}d"
  fi
  # hapus log rotasi lama
  need_sudo find /var/log -type f -name "*.gz" -delete
  need_sudo find /var/log -type f -name "*.old" -delete
  ok " Log is Cleaned!"
}

clean_tmp() {
  log " Cleaned /tmp dan ~/.cache..."
  need_sudo find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
  find "$HOME/.cache" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
  ok " Tempory Directory is Cleaned!"
}

run_trim() {
  $DO_TRIM || { warn "Skip TRIM."; return; }
  if ! cmd_exists fstrim; then
    warn " Not Found fstrim. Skip TRIM."
    return
  fi
  log " Running TRIM SSD..."
  need_sudo fstrim -av || warn " TRIM Failed (Ignore if HDD)."
  ok "  Finish TRIM."
}

detect_heavy_services() {
  log " Heavy Service Detection (Top 10)..."
  if ! cmd_exists systemctl; then
    warn " Not Available systemctl. Skip..."
    return
  fi
  mapfile -t services < <(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}')
  printf "%-45s %-8s %-8s\n" "SERVICE" "CPU(%)" "MEM(%)"
  printf "%s\n" "---------------------------------------------------------------"
  {
    for svc in "${services[@]}"; do
      pid="$(systemctl show -p MainPID "$svc" | cut -d= -f2)"
      [[ "$pid" =~ ^[0-9]+$ && "$pid" -gt 0 ]] || continue
      cpu="$(ps -p "$pid" -o %cpu= 2>/dev/null | awk '{print $1}')"
      mem="$(ps -p "$pid" -o %mem= 2>/dev/null | awk '{print $1}')"
      printf "%-45s %-8s %-8s\n" "$svc" "${cpu:-0}" "${mem:-0}"
    done
  } | sort -k2 -nr | head -n 10
  echo

  $AUTO_YES && return 0
  read -rp " Stop/Disable service? (Y/n) " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return 0

  read -rp " input service name (separate spaces): " to_handle
  [[ -z "${to_handle// }" ]] && { warn "No input."; return; }

  for svc in $to_handle; do
    if systemctl is-active --quiet "$svc"; then
      need_sudo systemctl stop "$svc" && ok " Service $svc Stopped."
    fi
    need_sudo systemctl disable "$svc" && ok " Service $svc Disabled."
  done
}

header() {
  clear
  printf "\n %s╔═════════════════════════════════════╗\n" "$GREEN"
  printf   " ║      Optimize APT-Package System     ║\n"
  printf   " ╚══════════════════════════════════════╝%s\n" "$RESET"
}

run_mode() {
  case "$1" in
    fast)
      clean_cache_apt
      clean_journal
      clean_tmp
      ok " FAST cleaning Finish."
      ;;
    light)
      clean_cache_apt
      clean_journal
      clean_tmp
      remove_orphans
      run_trim
      ok " LIGHT cleaning Finish."
      ;;
    full)
      clean_cache_apt
      clean_journal
      clean_tmp
      remove_orphans
      run_trim
      detect_heavy_services
      ok " FULL cleaning Finish."
      ;;
    *)
      err " Invalid Mode: $1"; exit 1 ;;
  esac
}

menu() {
  while true; do
    header
    echo " Chooice Mode:"
    echo " 1) FAST  (cache + log + tmp)"
    echo " 2) LIGHT (FAST + orphan + TRIM)"
    echo " 3) FULL  (LIGHT + service detection)"
    echo " 4) Exit"
    printf " Press Enter for Exit.\n"
    read -rp " Chooice [1-4]: " choice

    [[ -z "$choice" || "$choice" == "4" ]] && break
    case "$choice" in
      1) run_mode fast ;;
      2) run_mode light ;;
      3) run_mode full ;;
      *) warn " Invalid Chooice!" ;;
    esac
    read -rp " Press Enter for Back To Menu..." _
  done
}

# ===== Main =====
if [[ -n "$MODE" ]]; then
  run_mode "$MODE"
else
  menu
fi

# Opsional: tampilkan minifetch
if [[ -f "$FETCH_SCRIPT" ]]; then
  "$FETCH_SCRIPT" || true
fi

ok " Finish."
