#!/usr/bin/env bash

echo Updating pacman
sudo pacman -Syu

sudo pacman -S --noconfirm ccid pam-u2f

sudo systemctl enable pcscd.service
sudo systemctl start pcscd.service