#!/usr/bin/env bash

set -e

read -p "Do you want to install fcitx-unikey? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm fcitx-unikey fcitx-configtool
fi
