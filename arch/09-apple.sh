#!/usr/bin/env bash

file_name="/usr/local/bin/mounti"

read -p "Do you want to install Apple mount script? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh aur.sh ifuse
  sudo cp ./automount-iphone.sh $file_name
  sudo chmod +x $file_name
fi