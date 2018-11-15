#!/bin/bash

#-------- network

sudo systemctl enable iwd
sudo systemctl start iwd

printf \
"[iwd]# device list
[iwd]# station <interface> scan
[iwd]# station <interface> get-networks
[iwd]# station <interface> connect network_name"

iwctl

#-------- git

mkdir ~/build/suckless

cd ~/build/suckless
git clone https://github.com/qurn/mydwm.git
cd mydwm
sudo make clean install

cd ~/build/suckless
git clone https://github.com/qurn/myslstatus.git
cd myslstatus
vim config.h
sudo make clean install

cd ~/build
git clone https://github.com/qurn/dotfiles.git
cd dotfiles
bash move_files.sh

#-------- aur helper

cd ~/build
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -sri

#-------- grafic

#check graficcard
lspci -k | grep -A 2 -E "(VGA|3D)"

#ati
#sudo pacman -S mesa xf86-video-ati
#Intel
#sudo pacman -S mesa xf86-video-intel libva-intel-driver

#nvidia
#sudo pacman -S nvidia

#-------- additional services
sudo pacman -S --noconfirm --needed cups system-config-printer
yay -S tor-browser preload epson-inkjet-printer-escpr

sudo systemctl start org.cups.cupsd.service
sudo systemctl enable org.cups.cupsd.service

sudo systemctl start tor.service
sudo systemctl enable tor.service

sudo systemctl start preload.service
sudo systemctl enable preload.service

#microcode https://wiki.archlinux.org/index.php/Microcode
