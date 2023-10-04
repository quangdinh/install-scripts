#!/usr/bin/env bash
set -e

  sudo pacman -S --noconfirm ufw 
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw enable
  sudo systemctl enable ufw
