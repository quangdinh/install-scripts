#!/usr/bin/env bash

set -e

read -p "Do you want to setup Power saving for Thinkpad? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo pacman -S --noconfirm tlp acpi_call-lts
  sudo systemctl enable tlp
  echo "options snd_hda_intel power_save=1" | sudo tee -a /etc/modprobe.d/audio_powersave.conf
fi
