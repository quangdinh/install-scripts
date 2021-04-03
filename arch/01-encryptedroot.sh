#!/usr/bin/env bash

echo Enter efi partition
read encrypted_var
uuid=$(lsblk -no uuid $encrypted_var | sed -n '2 p')

if [ -z "$uuid" ]; then
  echo $encrypted_var is not an encrypted devices
else
  sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=$uuid:cryptroot root=/dev/mapper/cryptroot"/g' /etc/default/grub
  sed -i -e 's/HOOKS=(.*)/HOOKS=(base udev autodetect keyboard modconf block encrypt filesystems fsck)/g' /etc/mkinitcpio.conf
  mkinitcpio -P
  grub-mkconfig -o /boot/grub/grub.conf
fi