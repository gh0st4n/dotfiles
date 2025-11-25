#!/bin/bash

set -euo pipefail

#=====================
echo "Pilih DISTRO :"
echo "  1) ARCH Linux"
echo "  2) VOID Linux"
read -rp "Masukkan pilihan (1/2): " OS

case "$OS" in
    1)
        OS="arch"
        ;;
    2)
        OS="void"
        ;;
    *)
        echo "[!] Pilihan salah."
        exit 1
        ;;
esac

if [[ "$OS" == "arch" ]]; then
    # Arch Linux
    echo "[+] Git Clone USER:Gh0sT4n Branch arch..."
    git clone -b arch https://github.com/gh0st4n/dotfiles.git
else
    # Void Linux
    echo "[+] Git Clone USER:Gh0sT4n Branch arch..."
    git clone -b void https://github.com/gh0st4n/dotfiles.git
fi
