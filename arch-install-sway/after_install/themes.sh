#!/usr/bin/env bash
set -e
yay -S --noconfirm kora-icon-theme-git

find -type f -name "*fcitx-unikey*" | xargs sudo rm -rf