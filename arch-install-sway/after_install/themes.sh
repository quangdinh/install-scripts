#!/usr/bin/env bash
set -e
yay -S --noconfirm kora-icon-theme-git

find /usr/share/icons/kora -type f -name "*fcitx-unikey*" | xargs sudo rm -rf
sudo gtk-update-icon-cache /usr/share/icons/kora