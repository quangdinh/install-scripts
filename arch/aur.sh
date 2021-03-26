#!/usr/bin/env bash


skip_confirm=false
aurDir="$HOME/.aur"

function createAUR() {
  if [ ! -d "$aurDir" ]; then
    mkdir $aurDir
  fi
}

function update() {
  createAUR
  local packages
  parseInput packages "$@"


  if [ "${packages[0]}" = "all" ]; then
    echo "Updating all packages in $aurDir"
    cd "$aurDir"
    packages=()
    for file in *; do
      if [ -d "$file" ]; then
          packages+=( "$file" )
      fi
    done
  fi

  for package in "${packages[@]}"; do
    doUpdate $package
  done
}

function doUpdate() {
  local exists
  local update
  package=$1
  checkPackage exists update $package
  if [ $exists = true ]; then
    if [ $update = true ]; then
      echo "Updating package $package"
      doInstall $package
    else
      echo "Package $package already up-to-date"
    fi
  else
    echo "Package $package not installed"
  fi
}


function checkPackage() {
  local -n e=$1
  shift
  local -n u=$1
  shift
  dir="$aurDir/$1"
  if [ -d "$dir" ]; then
    e=true
    cd "$dir"
    git reset HEAD --hard >> /dev/null
    h=$(git rev-parse --short HEAD)
    hn=$(git rev-parse --short HEAD)
    if [ "$h" = "$hn" ]; then 
      u=false
    else
      u=true
    fi
  else
    e=false
    u=false
  fi
}

function doInstall() {
  dir="$aurDir/$1"
  cd $dir
  if [ $skip_confirm = true ]; then
    makepkg -si --noconfirm
  else
    makepkg -si
  fi
}

function install() {
  createAUR
  local packages
  parseInput packages "$@"

  for package in "${packages[@]}"; do
    local exists
    local success
    checkout exists success $package
    if [ $exists = true ]; then
      echo "Package $package already exists"
    else
      if [ $success = true ]; then
        echo "Installing package $package"
        doInstall $package
      else
        echo "Package $package doesn't exist"
      fi
    fi
  done
}

function checkout() {
  local -n e=$1
  shift
  local -n s=$1
  shift
  dir="$aurDir/$1"
  if [ -d "$dir" ]; then
    e=true
    s=false
  else
    e=false
    cd $aurDir
    git clone --quiet https://aur.archlinux.org/$1.git >> /dev/null 2>&1
    if [ -f "$dir/PKGBUILD" ]; then
      s=true
    else
      s=false
      rm -rf $dir
    fi
  fi
}

function usage() {
  echo "Usage"
}

function parseInput() {
  local -n arr=$1
  shift
  IFS=' ' read -r -a inputs <<< "$@"
  for input in "${inputs[@]}"; do
    if [[ "$input" = -* ]]; then
      if [ "$input" = "-y" ]; then
        skip_confirm=true
      fi
    else
      arr+=( $input )
    fi
  done
}

cmd=$1
shift
if [ "$cmd" = "update" ]; then
  update $@
elif [ "$cmd" = "install" ]; then
  install $@
else
  echo $args
  usage
fi


# read -p "You are about to install $1 from AUR. Are you sure? " -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#   git clone https://aur.archlinux.org/$1.git
#   cd $1
#   makepkg -si
#   cd ..
#   rm -rf $1
# fi