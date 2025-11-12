#!/bin/bash

# Installation
#-- BSPWM
bspwm():
sudo xbps-install -Su bspwm sxhkd picom polybar rofi dunst yay thunar xterm alacritty xfce4-terminal xorg-minimal

#-- i3 WM
i3():
sudo xbps-install -Su i3-gaps picom polybar rofi dunst yay thunar xterm alacritty xfce4-terminal xorg-minimal
