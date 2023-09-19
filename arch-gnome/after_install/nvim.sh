#!/usr/bin/env bash

set -e

sudo pacman -S --noconfirm python-neovim fd wget ripgrep python-pip
yarn global add neovim
gem install neovim
