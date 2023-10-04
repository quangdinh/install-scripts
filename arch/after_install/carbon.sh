#!/usr/bin/env bash

set -e
./reflector.sh
./thinkpad.sh
./firewall.sh
./hyprland.sh
yay -Syu --noconfirm rbenv ruby-build nvm 1password mongodb-compass \
  libfreoffice-fresh postman-bin slack-desktop-wayland google-chrome \
  gita
