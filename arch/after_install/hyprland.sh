#!/usr/bin/env bash

set -e


sudo pacman -S --noconfirm hyprland hyprpaper swaylock swayidle waybar wofi kitty \
  xdg-user-dirs-gtk imv zathura zathura-pdf-poppler mpv xdg-desktop-portal-gtk \
  xdg-desktop-portal-hyprland mako ly slurp grim wl-clipboard libnotify
sudo ./gnome_keyring.py
sudo systemctl enable ly.service
sudo ./hide_system_apps.sh
./ranger.sh
