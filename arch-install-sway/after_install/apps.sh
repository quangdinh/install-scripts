#!/usr/bin/env bash

set -e


read -p "Do you want to install Ymuse? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm ymuse-bin
fi

read -p "Do you want to install NordVPN? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm nordvpn-bin
  sudo usermod -aG nordvpn $(whoami)
fi

read -p "Do you want to install 1Password Manager? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm 1password
  sudo sed -i -e "s/Exec=\/opt\/1Password\/1password %U/Exec=\/opt\/1Password\/1password --enable-features=UseOzonePlatform --ozone-platform=wayland %U/g" /usr/share/applications/1password.desktop
fi

read -p "Do you want to install Telegram Desktop? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm telegram-desktop-bin
fi

read -p "Do you want to install LibreOffice? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm libreoffice-fresh
fi