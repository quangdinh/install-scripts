#!/usr/bin/env bash

set -e

sudo pacman -S --noconfirm reflector

cat <<EOF | sudo tee /etc/xdg/reflector/reflector.conf
# Select the country (--country).
# Consult the list of available countries with "reflector --list-countries" and
# select the countries nearest to you or the ones that you trust. For example:
# --country France,Germany
--country NL,DE,FR 
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 10
--sort rate
--age 12
EOF

sudo systemctl enable reflector.timer
sudo systemctl start reflector
