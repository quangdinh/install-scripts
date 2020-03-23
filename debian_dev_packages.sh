#!/usr/bin/env bash

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"
COL_BOLD=$ESC_SEQ"1m"

PACKAGES="ca-certificates \
    procps \
    curl \
    git \
    vim \
    libpq-dev \
    postgresql-client \
    patch \
    bzip2 \
    gawk \
    g++ \
    gcc \
    autoconf \
    automake \
    bison \
    libc6-dev \
    libffi-dev \
    libgdbm-dev \
    libncurses5-dev \
    libsqlite3-dev \
    libtool \
    libyaml-dev \
    make \
    pkg-config \
    sqlite3 \
    zlib1g-dev \
    libgmp-dev \
    libreadline-dev \
    libcurl4-openssl-dev \
    imagemagick \
    libmagickwand-dev \
    libpq-dev \
    libssl-dev"

CURRENT_USER=$(whoami)
if [ $CURRENT_USER == "root" ]; then
  ISROOT=true
else
  ISROOT=false
fi

printf "${COL_BOLD}> Current User: $CURRENT_USER$COL_RESET\n"
if [ $ISROOT != true ]; then
	printf "${COL_BOLD}> Current user is non-root, checking for sudo: $COL_RESET"
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

printf "${COL_BOLD}> Installing locales and generate for en_US.UTF-8$COL_RESET\n"
if [ $ISROOT = true ]; then
  apt-get install -y --no-install-recommends locales \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
  locale-gen
  echo "LC_ALL=en_US.UTF-8" > /etc/default/locale
  echo "LANG=en_US.UTF-8" >> /etc/default/locale
  echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale
else
  sudo apt-get install -y --no-install-recommends locales \
  sudo bash -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen'
  sudo locale-gen
  sudo bash -c 'echo "LC_ALL=en_US.UTF-8" > /etc/default/locale'
  sudo bash -c 'echo "LANG=en_US.UTF-8" >> /etc/default/locale'
  sudo bash -c 'echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale'
fi

printf "${COL_BOLD}> Installing essential packages $COL_RESET\n"
if [ $ISROOT = true ]; then
  mkdir -p /usr/share/man/man7
  mkdir -p /usr/share/man/man1
else
  sudo mkdir -p /usr/share/man/man7
  sudo mkdir -p /usr/share/man/man1
fi
if [ $ISROOT = true ]; then
  apt-get install --no-install-recommends -y $PACKAGES
else
  sudo apt-get install --no-install-recommends -y $PACKAGES
fi

printf "${COL_BOLD}> Setting TERM to xterm-256color$COL_RESET\n"
if [ $ISROOT = true ]; then
  echo "TERM=xterm-256color" >> /etc/profile
else
  sudo bash -c 'echo "TERM=xterm-256color" >> /etc/profile'
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
