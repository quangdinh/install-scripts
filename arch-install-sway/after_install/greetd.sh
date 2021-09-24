#!/usr/bin/env bash

set -e

read -p "Do you want to setup greetd with tuigreet " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  yay -S --noconfirm greetd greetd-tuigreet
  cat <<EOF | sudo tee /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "tuigreet -t --cmd /usr/bin/startsway"
user = "greeter"
EOF
  sudo systemctl enable greetd
fi
