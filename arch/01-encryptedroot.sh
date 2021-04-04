#!/usr/bin/env bash

pacman -S --noconfirm lvm2

echo Enter encrypted partition
read encrypted_var
uuid=$(lsblk -no uuid $encrypted_var | tail -n 1)
if [ -z "$uuid" ]; then
  echo $encrypted_var is not an encrypted devices
else
  root_partition=$(findmnt / -o uuid | tail -n 1)
  sed -e "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=$uuid:cryptlvm root=UUID=$root_partition\"/g" /etc/default/grub > grub #/etc/default/grub
  sed -e 's/HOOKS=(.*)/HOOKS=(base udev autodetect keyboard modconf block encrypt lvm2 filesystems fsck)/g' /etc/mkinitcpio.conf > mkinitcpio.conf
  cp grub /etc/default/grub
  rm -rf grub
  cp mkinitcpio.conf /etc/mkinitcpio.conf
  rm -rf mkinitcpio.conf
  mkinitcpio -P
  grub-mkconfig -o /boot/grub/grub.conf
fi