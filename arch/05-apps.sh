#!/usr/bin/env bash

read -p "Do you want to install Brave Browser? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh install -y brave-bin
fi

read -p "Do you want to install NordVPN? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh install -y nordvpn-bin
  sudo usermod -aG nordvpn $(whoami)
  sudo systemctl enable nordvpnd
fi

read -p "Do you want to install OnlyOffice? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh install -y onlyoffice-bin
fi

read -p "Do you want to install Extreme Download Manager? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh install -y xdman
fi

read -p "Do you want to install 1Password Manager? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  gpg --keyserver keyserver.ubuntu.com --recv-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22
  sh aur.sh install -y 1password
fi

read -p "Do you want to install Telegram Desktop? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm telegram-desktop
fi