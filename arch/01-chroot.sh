!/usr/bin/env bash

echo Updating pacman
pacman -Syu

echo Installing kernel
pacman -S --noconfirm linux-lts linux-firmware


echo Installing NetworkManager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

echo Installing vim and sudo
pacman -S --noconfirm vim sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers


echo Enter hostname
read var_hostname

echo $var_hostname > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t$var_hostname.local $var_hostname" > /etc/hosts

echo Setup locale
echo -e "en_US.UTF-8 UTF-8\nen_US ISO-8859-1\nen_GB.UTF-8 UTF-8\nen_GB ISO-8859-1" > /etc/locale.gen
echo -e "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

echo Enter time zone info
read var_timezone
ln -sf /usr/share/zoneinfo/$var_timezone /etc/localtime

echo Installing CPU Microcode
var_cpu=$(cat /proc/cpuinfo | grep -o -m1 "AuthenticAMD\|GenuineIntel")
if [ -e $var_cpu ]; then
  echo AMD/Intel CPU not detected
else
  echo Detected $var_cpu Processor
  if [ $var_cpu == 'AuthenticAMD' ]; then
    echo Installing AMD Microcode
    pacman -S --noconfirm amd-ucode
  fi
  if [ $var_cpu == 'GenuineIntel' ]; then
    echo Installing Intel Microcode
    pacman -S --noconfirm intel-ucode
  fi
fi

echo Installing boot manager
echo Enter efi partition
read var_efi
mkdir -p /boot/efi
mount $var_efi /boot/efi
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo Updating root password
passwd