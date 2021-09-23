#!/bin/sh

xfconf-query --channel thunar --property /misc-full-path-in-title --create --type bool --set true
systemctl --user enable mpd
if ! command -v xterm &> /dev/null
then
    sudo ln -s /usr/bin/alacritty /usr/bin/xterm
fi
