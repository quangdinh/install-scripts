#!/bin/sh

if ! command -v xterm &> /dev/null
then
    sudo ln -s /usr/bin/kitty /usr/bin/xterm
fi

git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh-syntax-highlighting
