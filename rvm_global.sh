#!/usr/bin/env bash

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"
COL_BOLD=$ESC_SEQ"1m"

# Save script's current directory
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT_USER=$(whoami)

if [ $CURRENT_USER == "root" ]; then
  ISROOT=true
else
  ISROOT=false
fi

# Check if sudo is installed
printf "${COL_BOLD}> Current User: $CURRENT_USER$COL_RESET\n"
if [ $CURRENT_USER != "root" ]; then
	printf "${COL_BOLD}> Current user is non-root, checking for sudo: $COL_RESET"
	if [ -x "$(command -v sudo)" ]; then
		printf "${COL_GREEN}Installed${COL_RESET}\n"
	else
	printf "${COL_RED}Sudo is required: please install sudo before running this script${COL_RESET}\n"	
	exit 127
	fi
fi

# Check if curl is installed
printf "${COL_BOLD}> Checking if curl is installed: $COL_RESET"
if [ -x "$(command -v curl)" ] ; then 
	printf "${COL_GREEN}Installed${COL_RESET}\n"
else
	printf "${COL_RED}curl is required: please install curl before running this script${COL_RESET}\n"	
	exit 127
fi

# Check if RVM is installed
printf "${COL_BOLD}> Checking if RVM is installed: $COL_RESET"
if ! [ -x "$(command -v rvm)" ] ; then
	printf "${COL_RED}Not installed${COL_RESET}\n"
	printf "${COL_BOLD}${COL_YELLOW}=> Installing RVM\n$COL_RESET"	

	if [ -x "$(command -v gpg)" ] ; then
		gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
	fi

	if [ $ISROOT = true ]; then
		curl -sSL https://get.rvm.io | bash -s stable
  else
		curl -sSL https://get.rvm.io | sudo bash -s stable
	fi

	if [ $ISROOT = true ]; then
		if [[ "$OSTYPE" == "darwin"* ]]; then
			dseditgroup -o edit -a "$CURRENT_USER" -t user rvm
		else
			usermod -a -G rvm "$CURRENT_USER"
		fi
	else
		if [[ "$OSTYPE" == "darwin"* ]]; then
			sudo dseditgroup -o edit -a "$CURRENT_USER" -t user rvm
		else
			sudo usermod -a -G rvm "$CURRENT_USER"
		fi
	fi
else
	printf "${COL_GREEN}Installed${COL_RESET}\n"
	printf "${COL_BOLD}${COL_YELLOW}=> Updating RVM\n$COL_RESET"	
	if [ $ISROOT = true ]; then
		rvm get stable 2>&1
	else
		rvmsudo rvm get stable 2>&1
	fi
fi
