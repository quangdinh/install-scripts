#!/usr/bin/env bash

set -e


  yay -S --noconfirm greetd greetd-tuigreet
  cat <<EOF | sudo tee /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "tuigreet -t --cmd /usr/bin/startsway.sh"
user = "greeter"
EOF
  sudo systemctl enable greetd


