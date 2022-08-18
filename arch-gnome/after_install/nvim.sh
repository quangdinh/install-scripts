#!/usr/bin/env bash

set -e

sudo pacman -S --noconfirm wget ripgrep python-pip
yarn global add neovim
python3 -m pip install --upgrade pip
pip3 install --user neovim
gem install neovim
