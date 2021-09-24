#!/usr/bin/env bash

set -e

read -p "Do you want to install Ymuse? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S neomutt lynx
  mkdir $HOME/.cache/mutt
fi