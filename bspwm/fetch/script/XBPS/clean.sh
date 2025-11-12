#!/bin/bash
# Script=Clean(XBPS-Package)
# Author: Mr-Yun1

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

on_error() { err "An Error Occurred in Line $BASH_LINENO (Exit Code: $?)"; }
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
${BOLD} clean-xbps.sh${RESET} v$VERSION
 Bersihkan sistem Void Linux dengan aman.

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
if ! cmd_exists xbps-remove; then
  err " xbps-remove Not Found. This Script is Only for Void/XBPS-Package."
  exit 1
fi

# ===== Tasks =====
clean_cache_xbps() {
  log " Cleaning cache XBPS..."
  need_sudo xbps-remove -o
  need_sudo xbps-remove -y
  ok " Cache XBPS Cleared."
}

remove_orphans() {
  log " Removing Package orphan (xbps-remove)"
  need_sudo xbps-remove -O || true
  ok " Package Orphan is Deleted"
}

clean_journal() {
  if cmd_exists journalctl; then
    log " Cleaning log systemd/runit (> ${JOURNAL_DAYS} Day)..."
    need_sudo journalctl --vacuum-time="${JOURNAL_DAYS}d"
  else
    log " Cleaning log di /var/log..."
    need_sudo find /var/log -type f -name "*.gz" -delete
    need_sudo find /var/log -type f -name "*.old" -delete
  fi
  ok " Log is Cleared."
}

clean_tmp() {
  log " Cleanning /tmp dan ~/.cache..."
  need_sudo find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
  find "$HOME/.cache" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
  ok " Tempory Directory is Cleared."
}

run_trim() {
  $DO_TRIM || { warn " Skip TRIM."; return; }
  if ! cmd_exists fstrim; then
    warn " Not Found fstrim. Skip TRIM."
    return
  fi
  log " Running TRIM SSD..."
  need_sudo fstrim -av || warn "Failed TRIM (Ignore if HDD)."
  ok "  Finish TRIM."
}

detect_heavy_services() {
  log " Heavy Service Detection (Top 10)..."
  if cmd_exists systemctl; then
    # Jika user pakai systemd
    mapfile -t services < <(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}')
    {
      for svc in "${services[@]}"; do
        pid="$(systemctl show -p MainPID "$svc" | cut -d= -f2)"
        [[ "$pid" =~ ^[0-9]+$ && "$pid" -gt 0 ]] || continue
        cpu="$(ps -p "$pid" -o %cpu= 2>/dev/null | awk '{print $1}')"
        mem="$(ps -p "$pid" -o %mem= 2>/dev/null | awk '{print $1}')"
        printf "%-45s %-8s %-8s\n" "$svc" "${cpu:-0}" "${mem:-0}"
      done
    } | sort -k2 -nr | head -n 10
  elif [[ -d /var/service ]]; then
    # Default Void: runit
    ls -1 /var/service
    warn " Void use runit. Manual Stop Service: sudo sv stop <service>"
  else
    warn " Can't Detection Service (Not systemd/runit)."
  fi
}

header() {
  clear
  printf "\n %s╔══════════════════════════════════════════╗\n" "$GREEN"
  printf   " ║         Optimize XBPS-Package System      ║\n"
  printf   " ╚═══════════════════════════════════════════╝%s\n" "$RESET"
}

run_mode() {
  case "$1" in
    fast)
      clean_cache_xbps
      clean_journal
      clean_tmp
      ok " FAST cleaning Finished."
      ;;
    light)
      clean_cache_xbps
      clean_journal
      clean_tmp
      remove_orphans
      run_trim
      ok " LIGHT cleaning Finished."
      ;;
    full)
      clean_cache_xbps
      clean_journal
      clean_tmp
      remove_orphans
      run_trim
      detect_heavy_services
      ok " FULL cleaning Finished."
      ;;
    *)
      err " Invalid Mode: $1"; exit 1 ;;
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
    printf " Press Enter To Exit.\n"
    read -rp " Choice [1-4]: " choice

    [[ -z "$choice" || "$choice" == "4" ]] && break
    case "$choice" in
      1) run_mode fast ;;
      2) run_mode light ;;
      3) run_mode full ;;
      *) warn "Invalis Choice." ;;
    esac
    read -rp "Press Enter to Back Menu..." _
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

ok "Finished."
