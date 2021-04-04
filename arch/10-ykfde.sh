#!/usr/bin/env bash

echo Updating pacman
sudo pacman -Syu

sudo pacman -S --noconfirm yubikey-full-disk-encryption

echo "Enroll key: sudo ykfde-enroll -d [device] -s 2"
echo "Change Luks Key: sudo cryptsetup luksChangeKey [device]"