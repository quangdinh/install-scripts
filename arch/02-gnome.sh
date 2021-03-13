#!/usr/bin/env bash

# echo Updating pacman
# pacman -Syu

# echo Installing X.Org Server
# pacman -S --noconfirm xorg-server xorg-xinit

echo Detected graphics driver
var_gpu=$(lspci | grep VGA | grep -o -m1 "NVIDIA\|Intel")
if [ -e $var_gpu ]; then
  echo "NVIDIA/Intel GPU not detected"
else
  echo Detected $var_gpu GPU
  if [ $var_gpu == 'NVIDIA' ]; then
    echo Installing nvidia drivers
    # pacman -S --noconfirm nvidia-lts
  fi

  if [ $var_gpu == 'Intel' ]; then
    echo Installing Intel drivers
    # pacman -S --noconfirm xf86-video-intel
  fi
fi