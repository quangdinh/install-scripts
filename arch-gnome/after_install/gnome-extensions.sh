#!/usr/bin/env bash

set -e

yay -S gnome-shell-extension-pop-shell-git gnome-shell-extension-topicons-plus gnome-shell-extension-sound-output-device-chooser gnome-shell-extension-espresso-git
curl -L https://raw.githubusercontent.com/pop-os/shell/master_jammy/scripts/configure.sh | sh