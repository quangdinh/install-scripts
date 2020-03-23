#!/usr/bin/env bash

. ./functions/base.sh

# tmux
if [ -x "$(command -v tmux)" ]; then
  print_bold "tmux is already installed\n"
  exit 0
fi

print_green "This script will install tmux, .tmux & dependencies add-on:\n"
print_bold "- Homebrew\n"
print_bold "- git\n"
print_bold "- tmux\n"
printf "You may be asked for your password.\n"
ask_to_continue

check_homebrew_install
check_git_install

print_bold "> Installing tmux\n"
brew install tmux

print_bold "> Installing tmux add on: .tmux"
if [ -d "$HOME/.tmux" ]; then
  print_yellow "=> $HOME/.tmux folder exists; moved to $HOME/.tmux.old"
  mv "$HOME/.tmux" "$HOME/.tmux.old"
fi

if [ -f "$HOME/.tmux.conf" ]; then
  print_yellow "=> $HOME/.tmux.conf exists; moved to $HOME/.tmux.conf.old"
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.old"
fi

print_bold "=> Cloning https://github.com/gpakosz/.tmux.git to $HOME.tmux\n"
git clone --depth 1 https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
ln -s -f $HOME/.tmux/.tmux.conf $HOME/.tmux.conf
cp $HOME/.tmux/.tmux.conf.local $HOME/.