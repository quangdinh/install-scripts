#!/usr/bin/env bash
set -e

read -p "Do you want to install yadm? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm yadms
fi

read -p "Do you want to install Postman? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm postman-bin
fi

read -p "Do you want to install Visual Studio Code? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm visual-studio-code-bin
fi

read -p "Do you want to install Android Studio? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm android-studio
fi