#!/usr/bin/env bash

set -e

read -p "Do you want to install Brave Browser? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S brave-bin
fi

read -p "Do you want to install NordVPN? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S nordvpn-bin
  sudo usermod -aG nordvpn $(whoami)
  sudo systemctl enable nordvpnd
fi

read -p "Do you want to install 1Password Manager? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S 1password
fi

read -p "Do you want to install Telegram Desktop? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm telegram-desktop
fi

read -p "Do you want to install FreeOffice? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S freeoffice
fi