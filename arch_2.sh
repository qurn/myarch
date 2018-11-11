#!/bin/bash

printf \
"
Enter username:
"
read USERNAME

printf \
"
Enter hostname:
"
read HOSTNAME

lsblk
printf \
"
Enter drive: (e.g.: /dev/sda )
"
read DRIVE

printf \
"de_DE.UTF-8 UTF-8
de_DE ISO-8859-1
de_DE@euro ISO-8859-15" \
> /etc/locale.gen

echo LANG=de_DE.UTF-8 > /etc/locale.conf
locale-gen

printf \
"echo KEYMAP=de-latin1
echo FONT=lat9w-16" \
> /etc/vconsole.conf

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

echo $HOSTNAME > /etc/hostname
echo "127.0.0.1	$HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

#wired
systemctl enable dhcpcd.service

pacman -Syu
pacman -S --noconfirm --needed dunst git intel-ucode iw ranger rxvt-unicode \
    ttf-dejavu urxvt-perls wget xorg-server xorg-xinit \
    alsa-oss alsa-utils dmenu \
    tor ttf-hannom gptfdisk gvfs-mtp libmtp mtools 

pacman -S --needed firefox \
    adwaita-icon-theme alsa-oss alsa-utils arduino \
    android-tools eog faenza-icon-theme gnome-disk-utility gnome-screenshot \
    go gparted hunspell-de kolourpaint libreoffice-fresh \
    libreoffice-fresh-de llpp lxappearance nemo nemo-fileroller \
    newsboat octave okular orage pavucontrol pidgin pidgin-otr pidgin-libnotify \
    pkgfile qutebrowser slock vlc xfce4-appfinder \
    xorg-xbacklight youtube-dl
gsettings set org.nemo.desktop show-desktop-icons false

pkgfile -u

###############
#bootloader
###############

###############
#bootctl
###############

#bootctl --path=/boot install
#
#cp /etc/mkinitcpio.conf /etc/mkinitcpio.confBAK
#
#printf \
#"timeout 0
#default arch" \
#> /boot/loader/loader.conf
#
#CRYPTUUID="$(blkid $DRIVE\2 | sed -r -n 's:.*\ UUID="([a-f0-9-]*).*:\1:p')"
#
#printf \
#"title Archlinux
#linux /vmlinuz-linux
#initrd /intel-ucode.img
#initrd /initramfs-linux.img
#options cryptdevice=UUID=$CRYPTUUID:cryptroot root=/dev/mapper/cryptroot quiet rw" \
#> /boot/loader/entries/arch.conf

###############
#syslinux
###############

pacman -S --noconfirm syslinux

printf \
"* BIOS: /boot/syslinux/syslinux.cfg
* UEFI: esp/EFI/syslinux/syslinux.cfg

PROMPT 0
TIMEOUT 50
DEFAULT arch

LABEL arch
	LINUX ../vmlinuz-linux
	APPEND root=/dev/sda2 rw
    APPEND root=/dev/mapper/cryptroot cryptdevice=/dev/sda2:cryptroot
	INITRD ../initramfs-linux.img" \
> /boot/syslinux/syslinux.cfg

syslinux-install_update -iam

###############
#syslinux and bootctl
###############

printf \
"MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block filesystems keyboard encrypt fsck)" \
> /etc/mkinitcpio.conf

mkinitcpio -p linux

###############
#users
###############

printf \
"
Enter root pw:
"
passwd
printf \
"
Enter pw for user $USERNAME:
"
useradd -m -g users -G wheel,audio,video -s /bin/bash $USERNAME
passwd $USERNAME

mkdir /etc/systemd/system/getty@tty1.service.d
printf \
"[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USERNAME --noclear %%I \$TERM" \
> /etc/systemd/system/getty@tty1.service.d/override.conf

printf \
"
uncomment wheel
"
sleep 2
visudo #wheel


################
#Sound
################
printf \
"snd-seq-oss
snd-pcm-oss
snd-mixer-oss" \
> /etc/modules-load.d/alsaoss.conf
