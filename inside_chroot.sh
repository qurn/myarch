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

DRIVENAME_REPLACE
re='[0-9]'
if ! [[ ${DRIVE: -1} =~ $re ]] ; then
    PARTBOOT=$DRIVE\1
    PARTROOT=$DRIVE\2
else
    PARTBOOT=$DRIVE\p1
    PARTROOT=$DRIVE\p2
fi

printf \
"en_US ISO-8859-1
en_US.UTF-8 UTF-8
de_DE ISO-8859-1
de_DE@euro ISO-8859-15" \
> /etc/locale.gen

echo LANG=en_US.UTF-8 > /etc/locale.conf
locale-gen

printf \
"echo KEYMAP=de-latin1
echo FONT=lat9w-16" \
> /etc/vconsole.conf

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

echo $HOSTNAME > /etc/hostname
echo "127.0.0.1	$HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts


#-------- bootloader
echo "What bootloader?"
select bs in "bootctl" "syslinux"; do
    case $bs in
        bootctl ) 
            bootctl --path=/boot install
            
            cp /etc/mkinitcpio.conf /etc/mkinitcpio.confBAK
            
            printf \
            "timeout 0
            default arch" \
            > /boot/loader/loader.conf
            
            CRYPTUUID="$(blkid -o value -s UUID $PARTROOT)"

            pacman -Sy --noconfirm intel-ucode
	    
            printf \
            "title Archlinux
            linux /vmlinuz-linux
            initrd /intel-ucode.img
            initrd /initramfs-linux.img
            options cryptdevice=UUID=$CRYPTUUID:cryptroot root=/dev/mapper/cryptroot quiet rw" \
            > /boot/loader/entries/arch.conf

            break;;
        syslinux ) 
            pacman -Sy --noconfirm syslinux
            
            printf \
            "* BIOS: /boot/syslinux/syslinux.cfg
            * UEFI: esp/EFI/syslinux/syslinux.cfg
            
            PROMPT 0
            TIMEOUT 50
            DEFAULT arch
            
            LABEL arch
            	LINUX ../vmlinuz-linux
            	APPEND root=$PARTROOT rw
                APPEND root=/dev/mapper/cryptroot cryptdevice=/dev/sda2:cryptroot
            	INITRD ../initramfs-linux.img" \
            > /boot/syslinux/syslinux.cfg
            
            syslinux-install_update -iam
            break;;
    esac
done

#-------- add encrypt for syslinux and bootctl
printf \
"MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block filesystems keyboard encrypt fsck)" \
> /etc/mkinitcpio.conf

mkinitcpio -p linux

#-------- users
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


echo -e \
"%wheel ALL=(ALL) ALL\\n%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/yay,/usr/bin/pacman -Syyuw --noconfirm" \
>> /etc/sudoers

#-------- sound for slstatus
printf \
"snd-seq-oss
snd-pcm-oss
snd-mixer-oss" \
> /etc/modules-load.d/alsaoss.conf

sed -i "s/^#Color/Color/g" /etc/pacman.conf

#-------- git
cd /tmp
git clone https://github.com/qurn/mydwm.git
cd mydwm
make clean install

cd ..
git clone https://github.com/qurn/myslstatus.git
cd myslstatus
vim config.h
make clean install

cd ..
git clone https://github.com/qurn/dotfiles.git
cd dotfiles
sudo -u $USERNAME bash move_files.sh

#-------- timesynchonisation
systemctl enable systemd-timesyncd.service

##-------- additional services
while true; do
    read -p $'Add big software? Y/N\n' yn
    case $yn in
        [Yy]* ) 
            pacman -Sy --needed --noconfirm adwaita-icon-theme alsa-oss alsa-utils \
                android-tools arduino cups eog faenza-icon-theme fd flake8 firefox \
                gnome-disk-utility gnome-screenshot go gparted gzip hunspell-de \
                intel-ucode imagemagick kolourpaint libreoffice-fresh libreoffice-fresh-de \
                llpp lxappearance mpv nemo nemo-fileroller newsboat octave okular \
                orage pavucontrol pidgin pidgin-libnotify pidgin-otr poppler \
                poppler-data poppler-glib poppler-qt5 pkgfile pygtk pyqt5-common \
                python python-matplotlib python-dbus python-dbus-common python-pep517 \
		        python-pip qutebrowser ripgrep sane system-config-printer slock tor vlc \
		        xfce4-appfinder xorg-xbacklight youtube-dl

            systemctl enable org.cups.cupsd.service
            systemctl enable tor.service
            gsettings set org.nemo.desktop show-desktop-icons false
            pkgfile -u
            printf "[Unit]\nDescription=Lock X session using slock for user %i\nBefore=sleep.target\n\n[Service]\nUser=%i\nEnvironment=DISPLAY=:0\nExecStartPre=/usr/bin/xset dpms force suspend\nExecStart=/usr/bin/slock\n\n[Install]\nWantedBy=sleep.target" > /etc/systemd/system/slock@.service
            systemctl enable slock@$USERNAME\.service

            #-------- aur helper
            cd /tmp
            git clone https://aur.archlinux.org/yay.git
            cd yay
            sudo -u $USERNAME makepkg -sri --noconfirm
            sudo -u $USERNAME yay -S --noconfirm epson-inkjet-printer-escpr imagescan preload task-spooler urxvt-resize-font-git xbanish
            systemctl enable preload.service
            break;;
        [Nn]* ) 
            break;;
        * ) echo "Please answer yes or no.";;
    esac
done

#-------- grafic
lspci -k | grep -A 2 -E "(VGA|3D)"

echo "What grafic card?"
select aind in "ati" "intel" "nvidia" "dont"; do
    case $aind in
        ati ) 
            pacman -Sy --needed --noconfirm mesa xf86-video-ati;
            break;;
        intel ) 
            pacman -Sy --needed --noconfirm mesa xf86-video-intel libva-intel-driver
            break;;
        nvidia ) 
            pacman -Sy --needed --noconfirm nvidia
            break;;
        dont ) 
            break;;
    esac
done

echo "What kind of machine is this?"
select vlt in "virtualbox" "laptop" "tower" ; do
    case $vlt in
        virtualbox ) 
            pacman -Sy --needed --noconfirm virtualbox-guest-modules-arch virtualbox-guest-utils
            systemctl enable vboxservice.service
            systemctl enable dhcpcd.service
            systemctl enable vboxservice.service
            gpasswd -a $USERNAME vboxsf
            break;;
        laptop ) 
            echo "IWD or netctl?"
            select IN in "iwd" "netctl" ; do
                case $IN in
                    iwd )
                        pacman -Sy --needed --noconfirm iwd
                        systemctl enable iwd.service
                        break;;
                    netctl )
                        pacman -Sy --needed --noconfirm dialog wpa_supplicant wireless_tools
                        #systemctl enable netctl-auto@wlp2s0.service
                        break;;
                esac
            done
            break;;
        tower ) 
            systemctl enable dhcpcd.service
            break;;
    esac
done

while true; do
    read -p $'Rank mirrors? Y/N\n' yn
    case $yn in
        [Yy]* ) 
            pacman -Sy --noconfirm pacman-contrib
            curl -s "https://www.archlinux.org/mirrorlist/?country=FR&country=GB&country=DE&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 10 - > /etc/pacman.d/mirrorlist
            break;;
        [Nn]* ) 
            break;;
        * ) echo "Please answer yes or no.";;
    esac
done

#
##microcode https://wiki.archlinux.org/index.php/Microcode
