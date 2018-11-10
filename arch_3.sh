#!/bin/bash

###############
#Netwerk
###############

sudo systemctl enable iwd
sudo systemctl start iwd

printf \
"[iwd]# device list
[iwd]# station <interface> scan
[iwd]# station <interface> get-networks
[iwd]# station <interface> connect network_name"

iwctl

###############
#git
###############

cd ..
mkdir suckless
cd suckless
git clone https://github.com/qurn/mydwm
cd mydwm
sudo make clean install
cd ..
git clone https://github.com/qurn/myslstatus
cd myslstatus
vim config.h
sudo make clean install
cd ..
git clone https://github.com/qurn/dotfiles.git

################
#displaymanager
################
printf \
"[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources
setxkbmap de -option \"caps:escape\" &
slstatus &
dunst &
xset s noblank &
xset s off &
xset -dpms &
exec dwm" \
> ~/.xinitrc

printf \
"if [[ ! \$DISPLAY && \$XDG_VTNR -eq 1 ]]; then
	exec startx
fi" \
> ~/.bash_profile

mkdir /etc/systemd/system/getty@tty1.service.d
printf \
"[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %%I \$TERM" \
> /etc/systemd/system/getty@tty1.service.d/override.conf

################

printf "uncomment #Color"
sleep 2
sudo vim /etc/pacman.conf

#microcode https://wiki.archlinux.org/index.php/Microcode

################
#Grafik
################
#check graficcard
lspci -k | grep -A 2 -E "(VGA|3D)"

#ati
#sudo pacman -S mesa xf86-video-ati
#Intel
#sudo pacman -S mesa xf86-video-intel libva-intel-driver

#nvidia
#sudo pacman -S nvidia

######
#special
######
cd ~/build
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -sri

###############
#Cups
###############
sudo pacman -S cups system-config-printer
sudo systemctl start org.cups.cupsd.service
sudo systemctl enable org.cups.cupsd.service
yay -S epson-inkjet-printer-escpr

sudo systemctl enable tor.service
sudo systemctl start tor.service
yay -S tor-browser 

yay -S preload
sudo systemctl start preload.service
sudo systemctl enable preload.service
