#!/usr/bin/env bash

. ./functions/base.sh

# zsh
if [ -x "$(command -v zsdh)" ]; then
  print_bold "zsh is already installed\n"
  exit 0
fi

print_green "This script will install zsh, ohmyzsh & dependencies add-on:\n"
print_bold "- Homebrew\n"
print_bold "- Git\n"
print_bold "- Zsh\n"
print_bold "- Ohmyzsh\n"
printf "You may be asked for your password.\n"
ask_to_continue

check_homebrew_install
check_git_install

print_bold "> Installing zsh\n"
brew install zsh

print_bold "> Installing ohmyzsh\n"

if [ -x "$(command -v wget)" ]; then
  sh -c "$(wget -O- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
elif [ -x "$(command -v curl)" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
else
  print_yellow "=> Skipped. curl/wget not installed\n"
fi