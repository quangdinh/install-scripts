#!/usr/bin/env bash

. ./functions/base.sh

check_go_install() {
  print_bold "> Checking Go: "
  if [ -x "$(command -v go)" ]; then
    print_green "already installed\n"
  else 
    print_yellow "not installed\n" 
    print_bold "> Installing Go\n" 
    brew install go
    if [ -x "$(command -v go)" ]; then
      print_green "=> Go installed\n" 
    else
      print_red "=> Installation failed. Exiting..."
      exit 1
    fi
  fi
}

check_env_install() {
  PROFILE_FILE="$HOME/.profile"
  if [[ $SHELL == *"zsh"* ]]; then
    PROFILE_FILE="$HOME/.zprofile"
  fi

  if [ -z "$GOPATH" ]; then
    echo 'export GOPATH="$HOME/go"' >> $PROFILE_FILE
    echo 'export PATH=$PATH:$GOPATH/bin' >> $PROFILE_FILE
  fi

  if [ -z "$GOROOT" ]; then
    echo "export GOROOT=\"$(brew --prefix golang)/libexec\"" >> $PROFILE_FILE 
    echo 'export PATH=$PATH:$GOROOT/bin' >> $PROFILE_FILE
  fi
}

print_green "This script will install the required tools to develop with Go:\n"
print_bold "- Git\n"
print_bold "- Go\n"
printf "You may be asked for your password.\n"
ask_to_continue

check_homebrew_install
check_git_install
check_env_install
check_go_install