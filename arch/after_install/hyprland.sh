#!/usr/bin/env bash

set -e


sudo pacman -S --noconfirm hyprland hyprpaper swaylock swayidle waybar wofi alacritty \
  imv zathura zathura-pdf-poppler mpv xdg-desktop-portal-hyprland mako 
sudo ./gnome_keyring.py
