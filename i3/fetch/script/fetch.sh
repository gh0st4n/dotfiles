#!/bin/bash

#Color
CY='\033[0;36m'
BL='\e[1;32m'
GR='\e[38;5;242m'

#Color Base
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Get system information
OS=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
HOSTNAME=$(hostname)
KERNEL=$(uname -r)
UPTIME=$(uptime -p | sed 's/up //')
PKG_MANAGER=""
RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
RAM_USED=$(free -h | awk '/Mem:/ {print $3}')
CPU=$(grep 'model name' /proc/cpuinfo | head -n1 | cut -d':' -f2 | sed 's/^[ \t]*//')
GPU=$(lspci | grep -i 'vga\|3d\|2d' | cut -d':' -f3 | xargs | head -n1)
SHELL=$(basename "$SHELL")
BATTERY_HEALTH=$(battery_health)

# Detect package manager
if [ -x "$(command -v apt)" ]; then
    PKG_MANAGER="apt ($(apt list --installed 2>/dev/null | wc -l) packages)"
elif [ -x "$(command -v pacman)" ]; then
    PKG_MANAGER="pacman ($(pacman -Q | wc -l) packages)"
elif [ -x "$(command -v dnf)" ]; then
    PKG_MANAGER="dnf ($(dnf list installed | wc -l) packages)"
elif [ -x "$(command -v yum)" ]; then
    PKG_MANAGER="yum ($(yum list installed | wc -l) packages)"
elif [ -x "$(command -v zypper)" ]; then
    PKG_MANAGER="zypper ($(zypper se -i | wc -l) packages)"
else
    PKG_MANAGER="Unknown"
fi

# Detect WM/DE + Display Server
detect_wmde_display() {
    local DE="${XDG_CURRENT_DESKTOP:-$DESKTOP_SESSION}"
    DE="${DE:-$GDMSESSION}"

    # List DE & WM
    local DE_CANDIDATES="gnome-shell|plasmashell|xfce4-session|mate-session|cinnamon|lxsession|budgie-desktop|enlightenment"
    local WM_CANDIDATES="sway|hyprland|wayfire|i3|i3-gaps|bspwm|awesome|openbox|fluxbox|herbstluftwm|spectrwm|qtile|xmonad"

    local PROC_LIST
    PROC_LIST=$(ps -eo comm= | awk '{print tolower($0)}')

    # Display Server
    local DISPLAY_SERVER="Unknown"
    if [ -n "$WAYLAND_DISPLAY" ] || [ "${XDG_SESSION_TYPE,,}" = "wayland" ]; then
        DISPLAY_SERVER="Wayland"
    elif [ -n "$DISPLAY" ] || [ "${XDG_SESSION_TYPE,,}" = "x11" ]; then
        DISPLAY_SERVER="X11"
    fi

    # Check DE
    local found_de
    found_de=$(echo "$PROC_LIST" | grep -E -m1 "$DE_CANDIDATES")
    if [ -n "$found_de" ] || [[ "$DE" =~ (GNOME|KDE|XFCE|MATE|Cinnamon|LXDE|LXQt|Budgie) ]]; then
        echo "DE : ${DE:-$found_de} ($DISPLAY_SERVER)"
        return
    fi

    # if not DE → check WM
    local found_wm
    found_wm=$(echo "$PROC_LIST" | grep -E -m1 "$WM_CANDIDATES")
    if [ -n "$found_wm" ]; then
        echo "WM : $found_wm ($DISPLAY_SERVER)"
        return
    fi

    # Fallback
    echo "WM/DE : Unknown ($DISPLAY_SERVER)"
}

# Screen resolution detection
if [ -x "$(command -v xrandr)" ]; then
    RESOLUTION=$(xrandr | grep '*' | awk '{print $1}')
elif [ -x "$(command -v swaymsg)" ]; then
    RESOLUTION=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .current_mode.width + "x" + .current_mode.height')
else
    RESOLUTION="Unknown"
fi

# Detect GTK/Qt Theme
detect_theme() {
    local THEME="Unknown"

    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        THEME=$(grep -i "gtk-theme-name" "$HOME/.config/gtk-3.0/settings.ini" | cut -d= -f2)
    elif [ -f "$HOME/.gtkrc-2.0" ]; then
        THEME=$(grep -i "gtk-theme-name" "$HOME/.gtkrc-2.0" | cut -d\" -f2)
    elif command -v lookandfeeltool &>/dev/null; then
        THEME=$(lookandfeeltool -l | head -n1)
    fi

    echo "${THEME:-Unknown}"
}

# Detect Icon Theme
detect_icons() {
    local ICON="Unknown"

    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        ICON=$(grep -i "gtk-icon-theme-name" "$HOME/.config/gtk-3.0/settings.ini" | cut -d= -f2)
    elif [ -f "$HOME/.gtkrc-2.0" ]; then
        ICON=$(grep -i "gtk-icon-theme-name" "$HOME/.gtkrc-2.0" | cut -d\" -f2)
    fi

    echo "${ICON:-Unknown}"
}

# Detect Font
detect_font() {
    local FONT="Unknown"

    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        FONT=$(grep -i "gtk-font-name" "$HOME/.config/gtk-3.0/settings.ini" | cut -d= -f2)
    elif [ -f "$HOME/.gtkrc-2.0" ]; then
        FONT=$(grep -i "gtk-font-name" "$HOME/.gtkrc-2.0" | cut -d\" -f2)
    fi

    echo "${FONT:-Unknown}"
}

# Detect Terminal Emulator
detect_terminal() {
    local TERM_NAME="Unknown"

    # Check environment variable
    if [ -n "$TERM_PROGRAM" ]; then
        TERM_NAME="$TERM_PROGRAM"
    elif [ -n "$TERMINAL_EMULATOR" ]; then
        TERM_NAME="$TERMINAL_EMULATOR"
    else
        # try found process parent
        local parent
        parent=$(ps -o comm= -p $(ps -o ppid= -p $$))
        TERM_NAME="$parent"
    fi

    echo "Terminal : $TERM_NAME"
}

# Storage Information
get_storage() {
    local mount_point=$1
    df -h $mount_point 2>/dev/null | awk 'NR==2 {print $3"/"$2" ("$5")"}'
}

ROOT_STORAGE=$(get_storage /)
HOME_STORAGE=$(get_storage /home)
EXTEND_STORAGE=$(get_storage /home/Extend)

# Detect Swap
detect_swap() {
    local SWAP_TOTAL=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
    if [ "$SWAP_TOTAL" -gt 0 ]; then
        awk -v s=$SWAP_TOTAL 'BEGIN{printf "%.2f GiB\n", s/1024/1024}'
    else
        echo "0 GiB"
    fi
}

# Detect Battery / AC Power
detect_power() {
    local POWER_PATH="/sys/class/power_supply"
    local BATTERY=""
    local AC=""
    local STATUS=""
    local CAPACITY=""

    # Check device
    [ -d "$POWER_PATH" ] || { echo "Power: Unknown"; return; }
    BATTERY=$(ls "$POWER_PATH" | grep -i 'BAT' | head -n1)
    AC=$(ls "$POWER_PATH" | grep -i 'AC' | head -n1)

    # if battery
    if [ -n "$BATTERY" ]; then
        STATUS=$(cat "$POWER_PATH/$BATTERY/status" 2>/dev/null)
        CAPACITY=$(cat "$POWER_PATH/$BATTERY/capacity" 2>/dev/null)

        if [ -n "$STATUS" ] && [ -n "$CAPACITY" ]; then
            echo "Battery : ${CAPACITY}% [${STATUS}]"
            return
        fi
    fi

    # if not battery but AC
    if [ -n "$AC" ]; then
        local AC_STATUS=$(cat "$POWER_PATH/$AC/online" 2>/dev/null)
        if [ "$AC_STATUS" = "1" ]; then
            echo "Power : AC Connected"
            return
        fi
    fi

    # Fallback
    echo "Power : Unknown"
}


# IP Detection
IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
if [ -z "$IP" ]; then
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
if [ -z "$IP" ]; then
    IP="Not connected"
fi

# Detect Locale
detect_locale() {
    echo "${LANG:-$(locale | grep LANG= | cut -d= -f2)}"
}

# Clear screen before show on display
echo -e "                                            ╭─────────────────────╮"
echo -e "                                 ${GR}@@    ${CY}@${NC}    │${CY}     "SYSTEM INFO"${NC}     │"
echo -e "                               ${GR}@%%    ${CY}@@${NC}    ╰─────────────────────╯"
echo -e "                           ${GR}@---%%   ${CY}%@@@      ${BL}[+] OS : $OS"
echo -e "                         ${GR}@----%   ${CY}%%---%      ${BL}[+] Hostname : $HOSTNAME"
echo -e "                      ${GR}@===-*%   ${CY}%-----%       ${BL}[+] Kernel : $KERNEL"
echo -e "                   ${GR}@=====%    ${CY}%==---%         ${BL}[+] Packages : $PKG_MANAGER"
echo -e "                ${GR}+%%%==%    ${CY}%==--*%            ${BL}[+] Shell : $SHELL"
echo -e "             ${GR}+%%%%%%=%   ${CY}%====+%%             ${BL}[+] Resolution : $RESOLUTION"
echo -e "         ${GR}%#@@%%%%%%%#%  ${CY}======%               ${BL}[+] $(detect_wmde_display)"
echo -e "        ${GR}@@@@@@@  @@%#%  ${CY}===%@                 ${BL}[+] Theme : $detect_theme"
echo -e "    ${GR}%#@@@@@@     @@@#%  ${CY}+++%                  ${BL}[+] Icons : $detect_icons"
echo -e "   ${GR}%#@@@@        @@+#%  ${CY}+++%                  ${BL}[+] Font : $detect_font"
echo -e "  ${GR}%#@@           \%*#%  ${CY}+++%                  ${BL}[+] $(detect_terminal)"
echo -e " ${GR}@@@               @#%  ${CY}+++%                  ${BL}[+] CPU : $CPU"
echo -e " ${GR}@@              @%%%%  ${CY}+++%                  ${BL}[+] GPU : $GPU"
echo -e " ${GR}@               \@@%%  ${CY}**+%                  ${BL}[+] Ram : $RAM_USED/$RAM_TOTAL"
echo -e "                  ${GR}@@#%  ${CY}***%                  ${BL}[+] Swap : $detect_swap"
echo -e "                  ${GR}@@#%  ${CY}***%                  ${BL}[+] Root-Storage : ${ROOT_STORAGE:-Not available}"
echo -e "                  ${GR}@@#%  ${CY}***%                  ${BL}[+] Home-Storage : ${HOME_STORAGE:-Not available}"
echo -e "                  ${GR}@@#%#  ${CY}**%                  ${BL}[+] Extend-Storage : ${EXTEND_STORAGE:-Not available}"
echo -e "                   ${GR}*#%##  ${CY}*%                  ${BL}[+] IP : $IP"
echo -e "                     ${GR}%=##  ${CY}%                  ${BL}[+] $(detect_power)"
echo -e "                       ${GR}@%  ${CY}%                  ${BL}[+] Locale : $(detect_locale)"
echo -e "                         ${GR}@ ${CY}@                  ${BL}[!] I USE $OS BTW"
echo -e "                           ${CY}@                ╰────────────────────────────────────────────╯${NC}"
echo -e " "


# Logo T4n OS
#                                  @@    @
#                                @-%%   @@
#                            @----%%  %@@@
#                          @----%   %%---%
#                       @===--*%  %-----%
#                    @======%   %==---%
#                 +%%%====%   %==--*%
#              +%%%%%%=%%  %====+%%
#          %#@@%%%%%%%#%  ======%
#         @@@@@@@  @@%#%  ===%@
#     %#@@@@@@     @@@#%  +++%
#    %#@@@@        @@+#%  +++%
#   %#@@           \%*#%  +++%
#  @@@               @#%  +++%
#  @@              @%%%%  +++%
#  @               \@@%%  **+%
#                   @@#%  ***%
#                   @@#%  ***%
#                   @@#%  ***%
#                   @@#%#  **%
#                    *#%##  *%
#                      %=##  %
#                        @%  %
#                          @ @
#                            @

