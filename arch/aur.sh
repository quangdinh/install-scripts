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
    u=false
    cd "$dir"
    git fetch
    git_status_sb=$(git status -sb 2>/dev/null)
    regex="behind ([0-9]+)"
    if [[ $git_status_sb =~ $regex ]]; then
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
  git reset HEAD >> /dev/null
  git pull >> /dev/null
  if [ $skip_confirm = true ]; then
    makepkg -si --noconfirm
  else
    makepkg -si
  fi
}

function doCheck() {
  local exists
  local update
  package=$1
  checkPackage exists update $package
  if [ $exists = true ]; then
    if [ $update = true ]; then
      echo "Update available for package $package"
    else
      echo "Package $package already up-to-date"
    fi
  else
    echo "Package $package not installed"
  fi
}


function check() {
  createAUR
  local packages
  parseInput packages "$@"


  if [ "${packages[0]}" = "all" ]; then
    echo "Checking all packages in $aurDir"
    cd "$aurDir"
    packages=()
    for file in *; do
      if [ -d "$file" ]; then
          packages+=( "$file" )
      fi
    done
  fi

  for package in "${packages[@]}"; do
    doCheck $package
  done
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
elif [ "$cmd" = "check" ]; then
  check $@
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