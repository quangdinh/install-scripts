#!/usr/bin/env bash

set -e

read -p "Do you want to install Brave? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S brave-bin
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
fi

read -p "Do you want to install Telegram Desktop? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm telegram-desktop-bin
fi

read -p "Do you want to install Gimp? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm gimp
fi

read -p "Do you want to install Obsidian? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S obsidian
fi