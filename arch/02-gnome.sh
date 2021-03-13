#!/usr/bin/env bash

# echo Updating pacman
# pacman -Syu

# echo Installing X.Org Server
# pacman -S --noconfirm xorg-server xorg-xinit

# echo Detected graphics driver
# var_gpu=$(lspci | grep VGA | grep -o -m1 "NVIDIA\|Intel")
# if [ -e $var_gpu ]; then
#   echo "NVIDIA/Intel GPU not detected"
# else
#   echo Detected $var_gpu GPU
#   if [ $var_gpu == 'NVIDIA' ]; then
#     echo Installing nvidia drivers
#     pacman -S --noconfirm nvidia-lts
#     nvidia-xconfig
#   fi

#   if [ $var_gpu == 'Intel' ]; then
#     echo Installing Intel drivers
#     pacman -S --noconfirm xf86-video-intel
#   fi
# fi

echo Installing minimal Gnome
# pacman -S --noconfirm gnome-shell gdm gnome-menus tracker3 tracker3-miners xdg-user-dirs-gtk gnome-session gnome-settings-daemon gnome-color-manager gnome-control-center gnome-keyring

read -p "Do you want to install basic Gnome utilities? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo Installing basic Gnome utilities
  # pacman -S --noconfirm eog evince file-roller gedit gnome-backgrounds gnome-calendar gnome-disk-utility gnome-screenshot  gnome-shell-extensions gnome-system-monitor gnome-terminal gnome-themes-extra gvfs gvfs-smb gvfs-nfs gvfs-mtp gvfs-afc gvfs-goa gvfs-google mutter nautilus sushi gnome-tweaks ttf-droid gnome-calculator xf86-input-wacom vlc rhythmbox
fi
