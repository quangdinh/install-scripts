#!/usr/bin/env bash

set -e

read -p "Do you want to install fcitx5-unikey? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm fcitx5-unikey fcitx5-im
fi
