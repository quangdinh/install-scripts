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

  cat <<EOF | sudo tee /usr/bin/startsway
#!/bin/sh

if command -v gnome-keyring-daemon &>/dev/null; then
  eval \$(gnome-keyring-daemon --start 2>/dev/null)
  export SSH_AUTH_SOCK
fi

export XDG_SESSION_TYPE=wayland
export DESKTOP_SESSION=sway
export XDG_SESSION_DESKTOP=sway
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export _JAVA_AWT_WM_NONREPARENTING=1

if [[ -f \$HOME/.xprofile ]]; then
	source \$HOME/.xprofile
fi

exec sway
EOF
  sudo chmod +x /usr/bin/startsway

  sudo systemctl enable greetd
fi
