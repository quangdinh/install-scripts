#!/usr/bin/env bash

read -p "Do you want to install Brave Browser? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh brave-bin
fi

read -p "Do you want to install NordVPN? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh nordvpn-bin
  sudo usermod -aG nordvpn $(whoami)
  sudo systemctl enable nordvpnd
fi

read -p "Do you want to install OnlyOffice? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh onlyoffice-bin-bin
fi

read -p "Do you want to install Postman? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh postman-bin
fi

read -p "Do you want to install Visual Studio Code? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh visual-studio-code-bin
fi

read -p "Do you want to install Extreme Download Manager? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh xdman
fi

read -p "Do you want to install Android Studio? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh android-studio
fi

read -p "Do you want to install 1Password Manager? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  gpg --keyserver keyserver.ubuntu.com --recv-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22
  sh aur.sh 1password
fi

read -p "Do you want to install Nodejs? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm nodejs npm
fi

read -p "Do you want to install Telegram Desktop? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm telegram-desktop
fi