#!/usr/bin/env bash

set -e

read -p "Do you want to install Neomutt & Lynx? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S neomutt w3m
  mkdir -p $HOME/.cache/mutt/messages
  mkdir -p $HOME/.cache/mutt/temp
fi