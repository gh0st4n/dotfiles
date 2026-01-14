#!/usr/bin/bash

cd bspwm
chmod +x 00A

cd bspwm/utility/picom
chmod +x *.sh

cd bspwm/utility/polybar
chmod +x *.sh
cd bspwm/utility/polybar/scripts
chmod+x *

cd bspwm/utility/script
chmod +x *

cp -r alacritty ~/.config/
cp -r betterlockscreen ~/.config/
cp -r bspwm ~/.config/
cp -r dunst ~/.config/
cp -r fonts ~/
mv ~/fonst .fonts
cp -r themes ~/
mv ~/themes .themes
