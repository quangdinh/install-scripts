#!/usr/bin/env bash

. ./functions/base.sh

install_dockerinit() {
  echo 'dockerinit() {' >> $1
  echo '  docker_status=$(docker-machine status default)' >> $1
  echo '  if [[ $docker_status != "Running"  ]]; then' >> $1
  echo '    docker-machine start default' >> $1
  echo '  fi' >> $1
  echo '  eval $(docker-machine env default); export DOCKER_IP=$(docker-machine ip default)' >> $1
  echo '}' >> $1  
}

install_dockerstop() {
  echo 'dockerstop() {' >> $1
  echo '  docker_status=$(docker-machine status default)' >> $1
  echo '  if [[ $docker_status = "Running" ]]; then' >> $1
  echo '    docker-machine stop default' >> $1
  echo '  fi' >> $1
  echo '}' >> $1  
}

print_green "This script will install the required tools to run docker and docker-compose:\n"
print_bold "- Homebrew\n"
print_bold "- Virtualbox & Extension Pack\n"
print_bold "- Docker, Docker-machine & Docker-compose\n"
printf "You may be asked for your password.\n"
ask_to_continue

check_homebrew_install

# Virtualbox
print_bold "> Checking virtualbox: "
if [ -x "$(command -v virtualbox)" ]; then
  print_green "already installed\n"
else 
  print_yellow "not installed\n"
  print_bold "> Installing virtualbox & virtualbox-extension-pack\n"
  brew cask install virtualbox virtualbox-extension-pack
  if [ $? -eq 0 ]; then
      # Quick smoke test
    if [ -x "$(command -v virtualbox)" ]; then
      print_green "=> Virtualbox installed\n" 
    else
      print_red "=> Installation failed. Exiting..."
      exit 1
    fi
  else
      print_red "=> Failed, likely due to security settings on your Mac. Please allow it in the Settings - Security & Privacy\n"
      ask_to_continue
      open /System/Library/PreferencePanes/Security.prefPane
      print_bold "=> Please continue after allowing developer Oracle America, Inc.\n"
      ask_to_continue 
      brew cask install virtualbox virtualbox-extension-pack 
  fi
fi

# Docker
print_bold "> Checking docker: "
if [ -x "$(command -v docker)" ]; then
  print_green "already installed\n"
else 
  print_yellow "not installed\n" 
  print_bold "> Installing docker docker-machine & docker-compose\n" 
  brew install docker docker-machine docker-compose
  if [ -x "$(command -v docker)" ]; then
    print_green "=> Docker installed\n" 
  else
    print_red "=> Installation failed. Exiting..."
    exit 1
  fi
fi

# Creating default machine
print_bold "=> Creating default machine, if needed\n" 
docker-machine status default || docker-machine create --driver virtualbox --virtualbox-memory=4096 --virtualbox-cpu-count=4 --virtualbox-disk-size=50000 --engine-storage-driver=overlay2 --virtualbox-host-dns-resolver default
eval $(docker-machine env default)
export DOCKER_IP=$(docker-machine ip default)


# Dockerinit
if ! alias dockerinit 2>/dev/null; then 
  print_bold "=> Setting up docker ENV\n" 
  PROFILE_FILE="$HOME/.profile"
  if [[ $SHELL == *"zsh"* ]]; then
    PROFILE_FILE="$HOME/.zprofile"
  fi

  if [[ -f $PROFILE_FILE ]]; then
    grep -qF "dockerinit()" $PROFILE_FILE || install_dockerinit $PROFILE_FILE
  else
    install_dockerinit $PROFILE_FILE
  fi
fi

# Dockerstop
if ! alias dockerstop 2>/dev/null; then 
  PROFILE_FILE="$HOME/.profile"
  if [[ $SHELL == *"zsh"* ]]; then
    PROFILE_FILE="$HOME/.zprofile"
  fi

  if [[ -f $PROFILE_FILE ]]; then
    grep -qF "dockerstop()" $PROFILE_FILE || install_dockerstop $PROFILE_FILE
  else
    install_dockerstop $PROFILE_FILE
  fi
fi