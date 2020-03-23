#!/bin/sh

. $(pwd)/functions/base.sh

NODE_VERSION=${1:-"10.16.0"}

check_root_block

print_green "This script will install:\n"
print_bold "Node: Version $NODE_VERSION\n"
printf "You may be asked for your password.\n"
ask_to_continue

install_for_mac()
{
  print_bold ">> Downloading official Node macOS Installer\n"
  curl -fsSLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.pkg"
  print_bold ">> Running Node macOS Installer\n"
  open node-v$NODE_VERSION.pkg
}

install_for_debian()
{
  print_bold ">> Installing build dependencies for Debian\n"
}

install_for_alpine()
{
  print_bold ">> Installing build dependencies for Alpine Linux\n"
  print_bold ">>> Installing libstdc++ build-base python\n"
  apk add --no-cache libstdc++ build-base python
  print_bold ">>> Installing as build-deps binutils-gold curl g++ gcc gnupg libgcc linux-headers make python\n"
  print_bold "    *We will remove it later\n"
  apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python
  print_bold ">> Adding gpg keys\n"      
  for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done
  print_bold ">> Downloading node-v$NODE_VERSION.tar.xz\n"
  curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz"
  curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc"

  if [ -f "SHASUMS256.txt" ]; then
    rm -rf SHASUMS256.txt
  fi
  gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc

  print_bold ">>> Verifying node-v$NODE_VERSION.tar.xz: "
  __SHA_RESULT=$(grep "node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c -)
  if ! [ __SHA_RESULT = "NODE_VERSION.tar.xz: OK" ]; then
    print_green "OK\n"
  else
    print_red "Failed\n"
    exit
  fi;

  print_bold ">> Extracting node-v$NODE_VERSION.tar.xz\n"
  tar -xf "node-v$NODE_VERSION.tar.xz"
  
  print_bold ">> Configuring node-v$NODE_VERSION\n"
  cd "node-v$NODE_VERSION"
  ./configure

  print_bold ">> Compiling node-v$NODE_VERSION\n"
  make -j$(getconf _NPROCESSORS_ONLN) V=

  print_bold ">> Installing node-v$NODE_VERSION\n"
  make install

  print_bold ">> Cleaning up building dependencies\n"
  apk del .build-deps

  print_bold ">> Cleaning up source files\n"
  cd ..
  rm -Rf "node-v$NODE_VERSION"
  rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

  print_bold "> Verifying install: $(node -v)\n"
}

print_bold "> Checking if Node is installed: "
if [ -x "$(command -v node)" ]; then
  print_green "Already installed at $(command -v node)\n"
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