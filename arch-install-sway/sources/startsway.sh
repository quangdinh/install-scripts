#!/usr/bin/env bash

export XDG_SESSION_TYPE=wayland
export DESKTOP_SESSION=sway
export XDG_SESSION_DESKTOP=sway
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export _JAVA_AWT_WM_NONREPARENTING=1

if [[ -f $HOME/.xprofile ]]; then
	source $HOME/.xprofile
fi

exec sway