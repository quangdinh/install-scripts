#!/usr/bin/env bash

read -p "Do you want to install Postman? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh install -y postman-bin
fi

read -p "Do you want to install Visual Studio Code? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh install -y visual-studio-code-bin
fi

read -p "Do you want to install Android Studio? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh install -y android-studio
fi

read -p "Do you want to install Nodejs? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm nodejs npm
fi


read -p "Do you want to install Docker & Docker Compose? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm docker docker-compose
  sudo usermod -aG docker $(whoami)
  sudo systemctl enable docker
fi


read -p "Do you want to install Golang? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm go
fi