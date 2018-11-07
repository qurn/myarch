#!/bin/bash

###############
#Prepare
###############

loadkeys de-latin1
#wifi-menu

echo "Enter username: "
read USERNAME
echo "Enter hostname: "
read HOSTNAME
###############
#Disk
###############

lsblk
echo "Enter drive: (e.g.: /dev/sdb ) "
read DRIVE

sgdisk --zap-all $DRIVE
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
       --new=2:0:0       --typecode=2:8300 --change-name=2:cryptroot \
         $DRIVE
mkfs.fat -F32 -n EFI $DRIVE\1

cryptsetup -y -v luksFormat $DRIVE\2
cryptsetup open $DRIVE\2 cryptroot

mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
cd /mnt
mkdir boot
mount $DRIVE\1 boot

###############
#Install
###############

vim /etc/pacman.d/mirrorlist

#minimal
pacstrap /mnt base base-devel gvim 

#usual
pacstrap /mnt dunst firefox git gptfdisk intel-ucode iw ranger rxvt-unicode \
    terminus-font ttf-dejavu urxvt-perls wget xorg-server xorg-xinit xorg-utils \
    xorg-server-utils

#wireless
pacstrap /mnt dialog netctl wireless_tools wpa_actiond wpa_supplicant

#extra
pacstrap /mnt adwaita-icon-theme alsa-oss alsa-utils arduino \
    android-tools dmenu eog faenza-icon-theme gnome-disk-utility gnome-screenshot \
    go gparted gvfs-mtp hunspell-de kolourpaint libreoffice-fresh \
    libreoffice-fresh-de libmtp llpp lxappearance mtools nemo nemo-fileroller \
    newsboat octave okular orage pavucontrol pidgin pidgin-otr pidgin-libnotify \
    pkgfile qutebrowser slock tor ttf-hannom vlc xfce4-appfinder \
    xorg-xbacklight youtube-dl

#vbox
#pacman -S virtualbox-guest-utils

###############
#Setup
###############

genfstab -L -p /mnt >> /mnt/etc/fstab

arch-chroot /mnt

#now in skript 2

umount -R /mnt
reboot
