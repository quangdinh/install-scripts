#!/usr/bin/env bash

set -e

  sudo pacman -S --noconfirm neomutt w3m
  mkdir -p $HOME/.cache/mutt/messages
  mkdir -p $HOME/.cache/mutt/temp
