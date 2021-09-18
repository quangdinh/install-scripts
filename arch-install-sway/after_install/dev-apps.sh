#!/usr/bin/env bash
set -e

read -p "Do you want to install yadm? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S yadm
fi

read -p "Do you want to install Postman? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S postman-bin
fi

read -p "Do you want to install Visual Studio Code? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S visual-studio-code-bin
fi

read -p "Do you want to install Android Studio? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then

  yay -S jdk11-openjdk android-studio
fi