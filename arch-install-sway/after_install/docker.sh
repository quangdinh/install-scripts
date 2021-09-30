#!/usr/bin/env bash

set -e





  echo "Installing gnupg & pass"
  sudo pacman -S --noconfirm gnupg pass

  echo "Generating new key"
  gpg --gen-key

  key=$(gpg --list-secret-keys | grep uid -B 1 | head -n 1 | sed 's/^ *//g')

  echo "Initializing pass with key $key"
  pass init $key

  echo "Installing gnupg & pass"
  yay -S --noconfirm docker-credential-pass-bin

  if [ ! -f "$HOME/.docker/config.json" ]; then
    mkdir -p $HOME/.docker
    cat <<EOT > ~/.docker/config.json
{
  "credsStore": "pass"
}
EOT
  fi
  sudo pacman -S --noconfirm docker docker-compose
  sudo usermod -aG docker $(whoami)


