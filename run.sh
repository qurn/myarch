#!/bin/bash

#-------- Prepare
#loadkeys de-latin1
#wifi-menu
#vim /etc/pacman.d/mirrorlist
#pacman -Sy git
#git clone https://github.com/qurn/myarch.git
#cd myarch
#bash arch_1.sh

#-------- Disk
lsblk
printf \
"
Enter drive: (e.g.: /dev/sda ) 
"
read DRIVE

#tell inside_chroot the drivename
sed -i "s#DRIVENAME_REPLACE#DRIVE=\"$DRIVE\"#" inside_chroot.sh

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
mkdir /mnt/boot
mount $DRIVE\1 /mnt/boot

#-------- Install
pacstrap /mnt alsa-oss alsa-utils base base-devel dmenu dunst git gptfdisk \
gvfs-mtp gvim iw iwd libmtp mtools ranger rxvt-unicode ttf-dejavu ttf-hannom \
urxvt-perls wget xorg-server xorg-xinit

#-------- Setup
genfstab -L -p /mnt >> /mnt/etc/fstab

mkdir /mnt/etc/myarch
cp inside_chroot.sh /mnt/etc/myarch/

chmod +x /mnt/etc/myarch/inside_chroot.sh

arch-chroot /mnt /bin/bash -c "su - -c /etc/myarch/inside_chroot.sh"

#now in skript 2

umount -R /mnt
printf "unmounted /mnt

you can reboot or poweroff"
