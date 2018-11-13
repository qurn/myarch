#!/bin/bash

###############
#Prepare
###############

#loadkeys de-latin1
#wifi-menu
#vim /etc/pacman.d/mirrorlist
#pacman -Syu
#pacman -S git
#git clone https://github.com/qurn/myarch.git
#cd myarch
#bash arch_1.sh

###############
#Disk
###############

lsblk
printf \
"
Enter drive: (e.g.: /dev/sda ) 
"
read DRIVE

sgdisk --zap-all $DRIVE
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
       --new=2:0:0       --typecode=2:8300 --change-name=2:cryptroot \
         $DRIVE
mkfs.fat -F32 -n EFI $DRIVE\1

printf \
"
PW for setting up encryption
"
cryptsetup -y -v luksFormat $DRIVE\2
printf \
"
PW for opening encrypted dirve
"
cryptsetup open $DRIVE\2 cryptroot

mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
cd /mnt
mkdir boot
mount $DRIVE\1 boot

###############
#Install
###############
pacman -S pacman-contrib
rankmirrors -n 10 /etc/pacman.d/mirrorlist > /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel gvim git \
    iwd

###############
#Setup
###############

genfstab -L -p /mnt >> /mnt/etc/fstab

arch-chroot /mnt

#now in skript 2

umount -R /mnt
reboot
