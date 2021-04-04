#!/usr/bin/env bash

echo Updating pacman
sudo pacman -Syu

sudo pacman -S --noconfirm ccid pam-u2f opensc

sudo systemctl enable pcscd.service
sudo systemctl start pcscd.service

echo "Edit /etc/pam.d/[service]:"
echo "Auth    required/sufficient    pam_u2f.so origin=pam://HOSTNAME appid=pam://HOSTNAME"