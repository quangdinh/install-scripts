#!/usr/bin/env bash

set -e

yay -S gnome-shell-extension-pop-shell-git gnome-shell-extension-sound-output-device-chooser gnome-shell-extension-espresso-git

curl -Lo configure.sh https://raw.githubusercontent.com/pop-os/shell/master_jammy/scripts/configure.sh
sh ./configure.sh

git clone https://github.com/pop-os/cosmic-workspaces.git
cd cosmic-workspaces
make
make install
cd ..