#!/usr/bin/env bash

set -e

sudo pacman -Syu --noconfirm imagemagick
yay -Syu --noconfirm ranger-git

xdg-mime default ranger.desktop inode/directory
