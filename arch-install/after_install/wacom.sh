#!/usr/bin/env bash
set -e

file_name="/usr/local/bin/configure-wacom.sh"

read -p "Do you want to setup Wacom? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo cp ./99-wacom.rules /etc/udev/rules.d
  sudo cp ./configure-wacom.sh $file_name
  sudo chmod +x $file_name
  mkdir -p ~/.config/systemd/user
  cat <<EOT > ~/.config/systemd/user/wacom.service
[Unit]
Description=Configure my Wacom tablet
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=oneshot
ExecStart=$file_name

[Install]
WantedBy=graphical-session.target
EOT

  systemctl --user enable wacom

fi