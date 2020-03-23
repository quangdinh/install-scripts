#!/bin/sh

. $(pwd)/functions/base.sh

YARN_VERSION=${1:-"1.16.0"}

check_root_block

print_green "This script will install:\n"
print_bold "Yarn: Version $YARN_VERSION\n"
printf "You may be asked for your password.\n"
ask_to_continue

install_for_mac()
{
  print_red ">> MacOS currently not supported\n"
  exit 0
}

install_for_debian()
{
  print_bold ">> Installing build dependencies for Debian\n"
}

install_for_alpine()
{
  print_bold ">> Installing build dependencies for Alpine Linux\n"
#  print_bold ">>> Installing libstdc++\n"
#  apk add --no-cache libstdc++
  print_bold ">>> Installing as build-deps curl gnupg tar\n"
  print_bold "    *We will remove it later\n"
  apk add --no-cache --virtual .build-deps-yarn-deps curl gnupg tar
  print_bold ">> Adding gpg keys\n"      
  for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done
  print_bold ">> Downloading yarn-v$YARN_VERSION.tar.xz\n"
  curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz"
  curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc"
  print_bold ">>> Verifying yarn-v$YARN_VERSION.tar.xz: "
  if [ $(gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz) ]; then
    print_green "OK\n"
  else
    print_red "Failed\n"
    # exit
  fi
  print_bold ">> Installing yarn-v$YARN_VERSION\n"
  mkdir -p /opt
  tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/
  ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn
  ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg

  print_bold ">> Cleaning up building dependencies\n"
  apk del .build-deps-yarn

  print_bold ">> Cleaning up source files\n"
  rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz
  print_bold "> Verifying install: "
  yarn -v
}

print_bold "> Checking if Yarn is installed: "
if [ -x "$(command -v yarn)" ]; then
  print_green "Already installed at $(command -v yarn)\n"
  exit
else
  print_yellow "Not installed\n"
fi

print_bold "> Detecting OS: "
get_os_and_version sys_os sys_version
print_green "$sys_os version $sys_version\n"

if [ $(os_is_mac) = true ]; then
  install_for_mac
elif [ $(os_is_debian) = true ]; then
  install_for_debian
elif [ $(os_is_alpine) = true ]; then
  install_for_alpine
else
  print_red ">> $sys_os $sys_version currently not supported\n"
fi