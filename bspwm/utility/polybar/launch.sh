#!/bin/bash
# Config Polybar For Multi-Monitor with Auto-Detection

# ============================================
# SECTION 1: TERMINATE EXISTING POLYBAR
# ============================================

# Matikan semua polybar yang masih jalan
killall -q polybar

# Tunggu sampai proses polybar benar-benar mati
while pgrep -u $UID -x polybar >/dev/null; do 
    sleep 0.5
done

echo "✅ Semua instance Polybar telah dihentikan"

# ============================================
# SECTION 2: AUTO-DETECTION SYSTEM
# ============================================

POLYBAR_DIR="$HOME/.config/bspwm/utility/polybar"
AUTO_DETECT_SCRIPT="$POLYBAR_DIR/detection.sh"
SYSTEM_INI="$POLYBAR_DIR/system.ini"
CONFIG="$POLYBAR_DIR/config.ini"

echo "🔍 Menjalankan deteksi sistem otomatis..."

# Jalankan script deteksi jika ada
if [ -f "$AUTO_DETECT_SCRIPT" ] && [ -x "$AUTO_DETECT_SCRIPT" ]; then
    "$AUTO_DETECT_SCRIPT" --quick
    echo "✅ Deteksi sistem selesai"
else
    echo "⚠️  Script deteksi tidak ditemukan atau tidak executable"
    echo "   Jalankan: chmod +x $AUTO_DETECT_SCRIPT"
fi

# Verifikasi file system.ini
if [ ! -f "$SYSTEM_INI" ]; then
    echo "❌ ERROR: system.ini tidak ditemukan!"
    echo "   Buat file system.ini manual atau jalankan script deteksi"
    echo "   Contoh: $AUTO_DETECT_SCRIPT --force"
    exit 1
fi

# ============================================
# SECTION 3: MONITOR DETECTION & POLYBAR LAUNCH
# ============================================

echo "🖥️  Mendeteksi monitor..."

# Cek jika xrandr tersedia
if ! command -v xrandr &> /dev/null; then
    echo "⚠️  xrandr tidak ditemukan, menggunakan monitor default"
    polybar -c "$CONFIG" --reload main &
    echo "✅ Polybar dijalankan pada monitor default"
    exit 0
fi

# Deteksi monitor primary
PRIMARY=$(xrandr --query | grep " primary" | cut -d" " -f1)

if [ -n "$PRIMARY" ]; then
    echo "📺 Monitor primary: $PRIMARY"
    MONITOR=$PRIMARY polybar -c "$CONFIG" --reload main &
    echo "✅ Polybar dijalankan pada monitor primary: $PRIMARY"
    
    # Jalankan juga di monitor non-primary jika ada
    NON_PRIMARY=$(xrandr --query | grep " connected" | grep -v " primary" | cut -d" " -f1)
    for MON in $NON_PRIMARY; do
        echo "📺 Monitor tambahan: $MON"
        MONITOR=$MON polybar -c "$CONFIG" --reload secondary &
        sleep 0.3
    done
else
    # Fallback: gunakan monitor pertama yang terdeteksi
    FIRST=$(xrandr --query | grep " connected" | head -n1 | cut -d" " -f1)
    if [ -n "$FIRST" ]; then
        echo "📺 Monitor yang terdeteksi: $FIRST"
        MONITOR=$FIRST polybar -c "$CONFIG" --reload main &
        echo "✅ Polybar dijalankan pada monitor: $FIRST"
    else
        echo "❌ Tidak ada monitor yang terdeteksi!"
        echo "⚠️  Mencoba menjalankan tanpa setting monitor..."
        polybar -c "$CONFIG" --reload main &
    fi
fi

# ============================================
# SECTION 4: VERIFICATION
# ============================================

sleep 1
if pgrep -u $UID -x polybar >/dev/null; then
    echo ""
    echo "========================================"
    echo "✅ POLYBAR BERHASIL DILUNCHKAN!"
    echo "========================================"
    echo "Config file: $CONFIG"
    echo "System config: $SYSTEM_INI"
    echo ""
    echo "Untuk memeriksa log deteksi:"
    echo "  tail -f $POLYBAR_DIR/auto-detect.log"
    echo ""
    echo "Untuk deteksi ulang:"
    echo "  $AUTO_DETECT_SCRIPT --force"
else
    echo "❌ GAGAL menjalankan Polybar!"
    echo "   Periksa config.ini dan log Polybar"
fi
