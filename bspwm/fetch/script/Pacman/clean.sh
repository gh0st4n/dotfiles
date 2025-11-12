#!/bin/bash
# Author: Gh0sT4n
# Script-Clean(Pacman-Package)

set -Eeuo pipefail
IFS=$'\n\t'

VERSION="1.0.0"

# ===== Color & UI =====
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

# ===== Globals & Defaults =====
AUTO_YES=false
MODE=""
JOURNAL_DAYS="${JOURNAL_DAYS:-7}"
DO_TRIM=true
DO_AUR=true
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
${BOLD}clean-pacman.sh${RESET} v$VERSION
Bersihkan sistem Arch/derivatif dengan aman.

Usage:
  $0 [--mode fast|light|full] [-y|--yes]
     [--journal-days N] [--no-trim] [--no-aur]

Opsi:
  --mode           fast (cache+log+tmp),
                   light (fast + orphan + TRIM),
                   full (light + deteksi service)
  -y, --yes        Non-interaktif (auto "Yes")
  --journal-days   Retensi journalctl (default: $JOURNAL_DAYS hari)
  --no-trim        Lewati TRIM SSD
  --no-aur         Lewati bersih cache AUR helper
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
    --no-aur) DO_AUR=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err " Unknown Argument: $1"; usage; exit 1 ;;
  esac
done

# ===== Validasi =====
if ! cmd_exists pacman; then
  err " Pacman Not Found.This Script is Only for Arch/Pacman-Package."
  exit 1
fi

# ===== Tasks =====
clean_cache_pacman() {
  log " Cleaning Cache Pacman..."
  if cmd_exists paccache; then
    need_sudo paccache -rk1
  else
    warn " paccache Not Found (Package: pacman-contrib). Fallback to pacman -Sc."
    need_sudo pacman -Sc --noconfirm
  fi
  ok " Cache Pacman is Cleared."
}

clean_cache_aur() {
  $DO_AUR || { warn " Skip Clear Cache AUR."; return; }
  if cmd_exists yay; then
    log " Cleaning Cache AUR (yay)..."
    yay -Sc --noconfirm || warn " Failed Clean Cache yay(ignore)."
    ok " Cache yay is Cleared."
  elif cmd_exists paru; then
    log " Cleaning Cache AUR (paru)..."
    paru -Sc --noconfirm || warn " Failed Clean Cache paru(ignore)."
    ok "Cache paru is Cleared."
  else
    warn "AUR helper Not Found (yay/paru). Skip."
  fi
}

remove_orphans() {
  log " Scanning orphan packages..."
  mapfile -t orphans < <(pacman -Qtdq 2>/dev/null || true)
  if (( ${#orphans[@]} == 0 )); then
    ok " Not Found orphan packages."
    return
  fi
  printf " Found %d orphan:\n%s\n" "${#orphans[@]}" "${orphans[*]}"
  confirm || { warn " Cancel Delete orphan."; return; }
  need_sudo pacman -Rns --noconfirm "${orphans[@]}"
  ok " Orphan packages is Deleted."
}

clean_journal() {
  if ! cmd_exists journalctl; then
    warn " journalctl Not Found. Skip Clear log."
    return
  fi
  log " Cleaning log systemd (> ${JOURNAL_DAYS} hari)..."
  need_sudo journalctl --vacuum-time="${JOURNAL_DAYS}d"
  ok "Log systemd is Cleared."
}

clean_tmp() {
  log " Cleaning /tmp dan ~/.cache..."
  # /tmp: aman, tidak menyentuh mount points
  need_sudo find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
  # ~/.cache: milik user sekarang
  find "$HOME/.cache" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
  ok " Tempory Directory is Cleared."
}

run_trim() {
  $DO_TRIM || { warn " Skip TRIM."; return; }
  if ! cmd_exists fstrim; then
    warn " fstrim Not Found. Skip TRIM."
    return
  fi
  log " Running TRIM for SSD..."
  need_sudo fstrim -av || warn " Failed TRIM (ignnore if Not SSD/Support)."
  ok " Finished TRIM."
}

detect_heavy_services() {
  log " Heavy Detection Service (Top 10)..."
  if ! cmd_exists systemctl; then
    warn "Not Available systemctl. Skip."
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

  read -rp " input service name (separate space): " to_handle
  [[ -z "${to_handle// }" ]] && { warn " No input."; return; }

  for svc in $to_handle; do
    if systemctl is-active --quiet "$svc"; then
      need_sudo systemctl stop "$svc" && ok " Service $svc Stopped."
    fi
    need_sudo systemctl disable "$svc" && ok " Service $svc Disable (persistent)."
  done
}

header() {
  clear
  printf "\n %s╔════════════════════════════════════════╗\n" "$GREEN"
  printf   " ║         Optimize Arch System (PAC)     ║\n"
  printf   " ╚════════════════════════════════════════╝%s\n" "$RESET"
}

run_mode() {
  local m="$1"
  case "$m" in
    fast)
      clean_cache_pacman
      clean_cache_aur
      clean_journal
      clean_tmp
      ok " FAST cleaning Finished."
      ;;
    light)
      clean_cache_pacman
      clean_cache_aur
      clean_journal
      clean_tmp
      remove_orphans
      run_trim
      ok " LIGHT cleaning Finished."
      ;;
    full)
      clean_cache_pacman
      clean_cache_aur
      clean_journal
      clean_tmp
      remove_orphans
      run_trim
      detect_heavy_services
      ok " FULL cleaning Finished."
      ;;
    *)
      err " Invalid Mode: $m"; exit 1 ;;
  esac
}

menu() {
  while true; do
    header
    echo " Choice Mode:"
    echo " 1) FAST  (cache + log + tmp)"
    echo " 2) LIGHT (FAST + orphan + TRIM)"
    echo " 3) FULL  (LIGHT + deteksi service)"
    echo " 4) Exit"
    printf " Press Enter for Exit.\n"
    read -rp " Choice [1-4]: " choice

    [[ -z "$choice" || "$choice" == "4" ]] && break
    case "$choice" in
      1) run_mode fast ;;
      2) run_mode light ;;
      3) run_mode full ;;
      *) warn " Invalid Choice." ;;
    esac
    read -rp " Press Enter for Back to Menu..." _
  done
}

# ===== Main =====
if [[ -n "$MODE" ]]; then
  run_mode "$MODE"
else
  menu
fi

# Tampilkan minifetch (opsional)
if [[ -f "$FETCH_SCRIPT" ]]; then
  "$FETCH_SCRIPT" || true
fi

ok " Finished."
