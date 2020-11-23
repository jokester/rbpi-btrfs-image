#!/usr/bin/env bash

set -ue

if [[ $# -ne 2 ]]; then
  cat <<END
  USAGE: $0 DISK_IMAGE LOOP_DEVICE
  example: $0 20201112_raspi_4.img /dev/loop123
END
  exit 1
fi

set -x

###
## setup a loop device for disk image file
###
losetup -P "$2" "$1"
cd $(dirname "$0")

###
## convert ext4 partition to btrfs
###
btrfs-convert "$2p2"

## prepare mountpoints
# rbpi-root: real filesystem root, for subvol=/
# rbpi: subvolume for rootfs, for subvol=/live
FS_ROOT=/media/rbpi-root
LIVE_ROOT=/media/rbpi
mkdir -pv $FS_ROOT $LIVE_ROOT
mount "$2p2" $FS_ROOT -o compress=zstd

## mount root volume and remove unnecessary files
# backup subvolume created by btrfs-convert
btrfs subvolume delete $FS_ROOT/ext2_saved
# script to resize (ext4) filesystem on boot
rm -v $FS_ROOT/etc/systemd/system/rpi-resizerootfs.service

## compress files with zstd
btrfs filesystem df $FS_ROOT
btrfs filesystem defragment -r -czstd $FS_ROOT
btrfs filesystem df $FS_ROOT

## move everything into subvol=/live-initial
# subvol=/live-initial is an readonly snapshot of the original image. we can keep it for future reference.
btrfs subvolume snapshot -r $FS_ROOT $FS_ROOT/live-initial
rm -rf $FS_ROOT 2>/dev/null && true

## create  subvol=/live , it will become root of live system.
btrfs subvolume snapshot $FS_ROOT/live-initial $FS_ROOT/live

## unmount subvol=/ , mount subvol=/live
mount "$2p2" $LIVE_ROOT -o compress=zstd,subvol=/live
mount "$2p1" $LIVE_ROOT/boot/firmware

## modify fstab / kernel cmdline
sed -i.bak-initial                                                   \
  's# root=.* rw # root=LABEL=RASPIROOT rootflags=subvol=/live rw #' \
    $LIVE_ROOT/boot/firmware/cmdline.txt

sed -i.bak-initial                                                                                               \
  "s#^LABEL=RASPIROOT.*#LABEL=RASPIROOT / btrfs defaults,ssd,noatime,nodiratime,compress=zstd,subvol=/live 0 1#" \
  $LIVE_ROOT/etc/fstab

## install our initramfs/kernel hooks
# existed hooks would break our kernel parameters
# see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=971883 for detail
cp -v z51-fix-cmdline $LIVE_ROOT/etc/kernel/postinst.d
cp -v z51-fix-cmdline $LIVE_ROOT/etc/kernel/postrm.d
cp -v z51-fix-cmdline $LIVE_ROOT/etc/initramfs/post-update.d

## unmount all
sync
umount $LIVE_ROOT/boot/firmware
sleep 1
umount $LIVE_ROOT
sleep 1
umount $FS_ROOT
sleep 1
losetup --detach "$2"

cat <<END
FINISHED
END
