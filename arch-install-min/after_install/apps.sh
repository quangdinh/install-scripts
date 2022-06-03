#!/usr/bin/env bash

set -e

read -p "Do you want to install NordVPN? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S nordvpn-bin
  sudo usermod -aG nordvpn $(whoami)
fi

read -p "Do you want to install 1Password Manager? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S 1password
fi

read -p "Do you want to install Telegram Desktop? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S telegram-desktop-bin
fi

read -p "Do you want to install Gnome Text Editor? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S gnome-text-editor
fi

read -p "Do you want to install Simplenote? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S simplenote-electron-bin
fi