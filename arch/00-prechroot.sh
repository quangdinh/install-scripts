#!/usr/bin/env bash
echo Enter device
read var_dev

read -p "Are you sure you want to format $var_dev? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  nvme format -f $var_dev
  gdisk $var_dev

  echo Enter boot partition
  read var_boot

  mkfs.ext4 $var_boot

  echo Enter EFI partition
  read var_efi
  mkfs.fat -F32 $var_efi

  echo Enter LVM on Luks partition
  read var_luks

  cryptsetup -y -v luksFormat $var_luks
  cryptsetup luksOpen $var_luks cryptlvm

  pvcreate /dev/mapper/cryptlvm
  vgcreate VolGroup0 /dev/mapper/cryptlvm

  echo "Enter swap size (0 for no swap)"
  read var_swap_size
  if [ $var_swap_size != "0" ]; then
    lvcreate -L $var_swap_size VolGroup0 lvSwap
    mkswap /dev/VolGroup0/lvSwap
    swapon /dev/VolGroup0/lvSwap
  fi

  lvcreate -l 100%FREE VolGroup0 lvRoot
  mkfs.ext4 /dev/VolGroup0/lvRoot
  mount /dev/VolGroup0/lvRoot /mnt
  mkdir -p /mnt/boot
  mount $var_boot /mnt/boot
  pacstrap /mnt base
  genfstab -U /mnt >> /mnt/etc/fstab
  mkdir /mnt/install
  cp ./* /mnt/install
  arch-chroot /mnt
fi