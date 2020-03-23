#!/usr/bin/env bash

. ./functions/base.sh

if [ -x "$(command -v zsh)" ]; then
  print_bold "> zsh already installed: $(command -v zsh)\n"
  exit 0
fi

CURRENT_USER=$(whoami)
if [ $CURRENT_USER == "root" ]; then
  ISROOT=true
else
  ISROOT=false
fi

print_bold "Current User: $CURRENT_USER$"
if [ $ISROOT != true ]; then
  print_bold "> Current user is non-root, checking for sudo:"
	if [ -x "$(command -v sudo)" ]; then
		printf "${COL_GREEN}Installed${COL_RESET}\n"
	else
		printf "${COL_RED}Not installed${COL_RESET}\n"
		exit 127
	fi
fi

printf "${COL_BOLD}> Updating apt repository $COL_RESET\n"
if [ $ISROOT = true ]; then
  apt-get update
else
  sudo apt-get update
fi

printf "${COL_BOLD}> Installing zsh $COL_RESET\n"
if [ $ISROOT = true ]; then
  apt-get install --no-install-recommends -y zsh
else
  sudo apt-get install --no-install-recommends -y zsh
fi

printf "${COL_BOLD}> Setting TERM to xterm-256color$COL_RESET\n"
if [ $ISROOT = true ]; then
  echo "export TERM=xterm-256color" >> /etc/zsh/zshenv
else
  sudo bash -c 'echo "export TERM=xterm-256color" >> /etc/zsh/zshenv'
fi

printf "${COL_BOLD}> Changing shell to zsh$COL_RESET\n"
chsh -s /usr/bin/zsh

printf "${COL_BOLD}> Installing oh-my-zsh $COL_RESET\n"

if ! [ -x "$(command -v git)" ]; then
  printf "${COL_YELLOW}Skipping: Git not installed${COL_RESET}\n"
else
  git clone --depth 1 git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh 
  plugins=(rails z git xcode rake docker docker-compose osx)
  export ZSH="$HOME/.oh-my-zsh"
  source $ZSH/oh-my-zsh.sh
  echo "export ZSH=\"$HOME/.oh-my-zsh\"" > ~/.zshrc
  echo 'ZSH_THEME="agnoster"' >> ~/.zshrc
  echo 'plugins=(z git)' >> ~/.zshrc
  echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc
  touch ~/.z
fi

printf "${COL_BOLD}> Cleaning up $COL_RESET\n"
if [ $ISROOT = true ]; then
  apt-get autoremove
  apt-get clean
  apt-get autoclean
  rm -rf /var/lib/apt/lists/*
  rm -rf /tmp/*
else
  sudo apt-get autoremove
  sudo apt-get clean
  sudo apt-get autoclean
  sudo rm -rf /var/lib/apt/lists/*
  sudo rm -rf /tmp/*
fi
