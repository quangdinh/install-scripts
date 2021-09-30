#!/usr/bin/env bash
set -e

read -p "Do you want to install Gitui? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm gitui
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
  sudo sed -i -e "s/Exec=\/opt\/visual-studio-code\/code --no-sandbox/Exec=\/opt\/visual-studio-code\/code --enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox/g" /usr/share/applications/visual-studio-code-url-handler.desktop
  sudo sed -i -e "s/Exec=\/opt\/visual-studio-code\/code --no-sandbox/Exec=\/opt\/visual-studio-code\/code --enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox/g" /usr/share/applications/visual-studio-code.desktop
fi

read -p "Do you want to install Android Studio? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm android-studio
fi