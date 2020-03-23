#!/bin/sh
YELLOW="\e[1;33m"

print_bold()
{
  printf "\e[1;1m$1\e[0m"
}

print_red()
{
  printf "\e[1;31m$1\e[0m"
}

print_green()
{
  printf "\e[1;32m$1\e[0m"
}

print_yellow()
{
  printf "\e[1;33m$1\e[0m"
}

print_blue()
{
  printf "\e[1;34m$1\e[0m"
}

print_magenta()
{
  printf "\e[1;35m$1\e[0m"
}

print_cyan()
{
  printf "\e[1;36m$1\e[0m"
}

is_root()
{
  __CURRENT_USER=$(whoami)
  if [ $__CURRENT_USER = "root" ]; then
    echo true
  else
    echo false
  fi
}

get_username()
{
  echo $(whoami) 
}

has_sudo()
{
  if [ -x "$(command -v sudo)" ]; then
    echo true
  else
    echo false
  fi
}

ask_to_continue()
{
  while true; do
      read -p "Do you wish to continue? " yn
      case $yn in
          [Yy]* ) break;;
          [Nn]* ) echo "Aborting..."; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done  
}

check_root_block()
{
  print_bold "> Detecting current user: "
  USER=$(get_username)
  if [ $(is_root) = true ]; then
    print_green "$USER\n"
  else
    print_red "Non root. You will need to run this as root\n"
    exit;
  fi  
}

check_root_or_sudo_block()
{
  print_bold "> Detecting current user: "
  USER=$(get_username)
  if [ $(is_root) = true ]; then
    print_green "$USER\n"
  else
    print_yellow "$USER\n"
    print_bold ">> Checking for sudo: "
    if [ $(has_sudo) = true ]; then
      print_green "OK\n"
      print_bold ">>> You are not root. You will need to have sudo permission to continue\n"
      ask_to_continue
    else
      print_red "Failed\n"
      exit;
    fi
  fi  
}

get_os_and_version()
{
  if [ -f /etc/os-release ]; then
      # freedesktop.org and systemd
      . /etc/os-release
      __OS=$NAME
      __OS_VERSION=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
      # linuxbase.org
      __OS=$(lsb_release -si)
      __OS_VERSION=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
      # For some versions of Debian/Ubuntu without lsb_release command
      . /etc/lsb-release
      __OS=$DISTRIB_ID
      __OS_VERSION=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
      # Older Debian/Ubuntu/etc.
      __OS=Debian
      __OS_VERSION=$(cat /etc/debian_version)
  else
      # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
      __OS=$(uname -s)
      __OS_VERSION=$(uname -r)
  fi
  __resultos=$1
  __resultversion=$2
  if [ $# = 2 ]; then
    eval $__resultos="'$__OS'"
    eval $__resultversion="'$__OS_VERSION'"
  else
    echo "$__OS: $__OS_VERSION"
  fi
}

get_os_short_name()
{
  get_os_and_version sys_os sys_version
  case $sys_os in 
    Alpine* ) echo "alpine";;
    Debian* ) echo "debian";;
    Darwin* ) echo "macos";;
    *) echo "unknown";;
  esac
}

os_is_debian()
{
  if [ "$(get_os_short_name)" = "debian" ]; then
    echo true
  else
    echo false
  fi
}

os_is_alpine()
{
  if [ "$(get_os_short_name)" = "alpine" ]; then
    echo true
  else
    echo false
  fi
}

os_is_mac()
{
  if [ "$(get_os_short_name)" = "macos" ]; then
    echo true
  else
    echo false
  fi
}

check_homebrew_install() {
    # Check if Homebrew is installed
  print_bold "> Checking if Homebrew is installed: "

  if ! [ -x "$(command -v brew)" ] ; then
    print_red "Not installed\n"
    print_bold "${YELLOW}=> Installing Homebrew\n"	
      ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  else
    print_green "Installed\n"
    print_bold "${YELLOW}=> Updating Homebrew\n"
    brew update
  fi

  if ! [ -x "$(command -v brew)" ] ; then
    print_red "Failed to install Homebrew\n"
    exit
  fi
}

check_git_install() {
  print_bold "> Checking if Git is installed: "
  if [ -x "$(command -v git)" ]; then
    print_green "installed\n"
  else
    print_red "not installed\n"
    brew install git
  fi
}

check_java_install() {
  print_bold "> Checking if java 8 is installed: "
  HAS_JAVA=0
  if [ -x "$(command -v javac)" ]; then
    JAVAVERSION=$(javac -version 2>&1)
    if [[ $JAVAVERSION == *"1.8"* ]]; then
      HAS_JAVA=1
    fi
  fi

  if [[ $HAS_JAVA == 0 ]]; then
    print_red "not installed\n"
    print_yellow "=> Installing adoptopenjdk8\n"
    brew tap adoptopenjdk/openjdk
    brew cask install adoptopenjdk8
  else
    print_green "installed\n"
  fi
}