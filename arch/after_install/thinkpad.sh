#!/usr/bin/env bash

set -e


  sudo pacman -S --noconfirm tlp acpi_call-lts
  sudo systemctl enable tlp
  echo "options snd_hda_intel power_save=1" | sudo tee -a /etc/modprobe.d/audio_powersave.conf
