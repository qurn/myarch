#!/bin/bash

#Neustart im system
#mkdir build
#cd build
#git clone https://github.com/qurn/myarch.git

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
> ~/.xinitrx

printf \n
"[[ -f ~/.bashrc ]] && . ~/.bashrc
if [ -z "\$DISPLAY" ] && [ -n "\$XDG_VTNR" ] && [ "\$XDG_VTNR" -eq 1 ]; then
  exec startx
fi" \
> ~/.bash_profile

mkdir /etc/systemd/system/getty@tty1.service.d
printf \
"[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin username --noclear \%I \$TERM" \
> /etc/systemd/system/getty@tty1.service.d/override.conf
################

sudo vim /etc/pacman.conf
Color

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

###############
#Netwerk
###############

ls /etc/netctl
sudo systemctl enable netctl-auto@<interf>.service

cd /etc/netctl/
netctl start wlp2s0-FRITZ\!Box\ 7362\ SLDFER 
sudo netctl enable wlp2s0-FRITZ\!Box\ 7362\ SLDFER 
sudo systemctl start netctl-ifplugd@wlp2s0.service
sudo systemctl enable netctl-ifplugd@wlp2s0.service

######
#special
######
cd build
git clone https://aur.archlinux.org/yay.git
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


sudo systemctl start preload.service
sudo systemctl enable preload.service
