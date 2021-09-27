#!/bin/sh

systemctl --user enable mpd
if ! command -v xterm &> /dev/null
then
    sudo ln -s /usr/bin/kitty /usr/bin/xterm
fi
