#!/usr/bin/env bash

set -e

echo "Installing gnupg & pass"
yay -S docker-credential-pass-bin

if [ ! -f "$HOME/.docker/config.json" ]; then
  mkdir -p $HOME/.docker
  cat <<EOT > ~/.docker/config.json
{
  "credsStore": "pass"
}
EOT
fi