#!/usr/bin/env bash

set -e

echo "Installing gnupg & pass"
sudo pacman -S --noconfirm gnupg pass

echo "Generating new key"
gpg --gen-key


key=$(gpg --list-secret-keys | grep uid -B 1 | head -n 1 | sed 's/^ *//g')

echo "Initializing pass with key $key"
pass init $key
