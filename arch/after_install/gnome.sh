#!/usr/bin/env bash

set -e

sudo pacman -S --noconfirm gnome-shell gnome-backgrounds gdm xdg-utils xdg-user-dirs-gtk kitty gnome-control-center gnome-keyring mutter gnome-menus gnome-themes-extra wl-clipboard lipappindicator-gtk3 xdg-desktop-portal-gnome xdg-desktop-portal
sudo pacman -S --noconfirm ego gnome-calendar evince file-roller gnome-screenshot gnome-shell-extensions gnome-system-monitor nautilus sushi gnome-tweaks noto-fonts noto-fonts-emoji gnome-calculator gvfs gvfs-smb gvfs-nfs gvfs-mtp gvfs-afc
sudo pacman -S --noconfirm xvidcore x264 ffmpeg gst-libav totem rythmbox
sudo systemctl enable gdm 
sudo ./hide_system_apps.sh
./nautilus.sh
./gnome-extensions.sh
