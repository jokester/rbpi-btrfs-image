#!/usr/bin/env bash

set -uex

# locales
echo 'en_US.UTF-8 UTF-8' > "/etc/locale.gen"
locale-gen

# initcpio
# cp "/etc/mkinitcpio.conf" "/tmp/mkinitcpio.conf.bak"
sed -e 's!^MODULES=.*!MODULES=(btrfs)!' -e 's!^#COMPRESSION="zstd"!COMPRESSION="zstd"!' -i.bak /etc/mkinitcpio.conf
mkinitcpio -p linux-rpi4

# journald: use volative
sed -e 's!^#Storage=.*!Storage=volatile!' -i.bak /etc/systemd/journald.conf

# hostname
echo 'CHANGE_ME' > "/etc/hostname"

# pacman keys
pacman-key --init
pacman-key --populate archlinux manjaro archlinuxarm

# services
systemctl enable iscsid cpupower systemd-networkd systemd-resolved systemd-timesyncd cronie tlp sshd

# initial user
useradd -m pi
gpasswd -a pi wheel
chpasswd <<END
root:CHANGE_ME
pi:CHANGE_ME
END
