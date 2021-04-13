#!/usr/bin/env bash

echo Updating pacman
pacman -Syu

echo Installing X.Org Server
pacman -S --noconfirm xorg-server xorg-xinit usbutils pciutils

echo Detected graphics driver
var_gpu=$(lspci | grep VGA | grep -o -m1 "NVIDIA\|Intel")
if [ -e $var_gpu ]; then
  echo "NVIDIA/Intel GPU not detected"
else
  echo Detected $var_gpu GPU
  if [ $var_gpu == 'NVIDIA' ]; then
    echo Installing nvidia drivers
    pacman -S --noconfirm nvidia-lts
    nvidia-xconfig
  fi

  if [ $var_gpu == 'Intel' ]; then
    echo Installing Intel drivers
    pacman -S --noconfirm xf86-video-intel
  fi
fi

echo Installing minimal Gnome with GDM
pacman -S --noconfirm gnome-shell gdm gnome-menus tracker3 tracker3-miners xdg-user-dirs-gtk gnome-control-center gnome-keyring mutter sof-firmware

systemctl enable gdm

read -p "Do you want to install basic Gnome utilities? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo Installing basic Gnome utilities
  pacman -S --noconfirm eog evince file-roller gedit gnome-screenshot gnome-shell-extensions gnome-system-monitor gnome-terminal nautilus sushi gnome-tweaks ttf-droid gnome-calculator xf86-input-wacom
fi

read -p "Do you want to install GVFS? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  pacman -S --noconfirm gvfs gvfs-smb gvfs-nfs gvfs-mtp gvfs-afc gvfs-goa gvfs-google
fi

read -p "Do you want to install Evolution (Email Client)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  pacman -S --noconfirm evolution
fi

read -p "Do you want to install Totem? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  pacman -S --noconfirm xvidcore x264 ffmpeg gst-libav totem
fi

read -p "Do you want to install Rhythmbox? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  pacman -S --noconfirm rhythmbox
fi

read -p "Do you have fingerprint reader? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  pacman -S --noconfirm fprintd
fi