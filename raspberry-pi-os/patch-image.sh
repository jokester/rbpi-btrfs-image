#!/usr/bin/env bash

set -uex

LOOP_DEVICE_PATH=/dev/loop123
TEMP_MNT=/mnt

function map-image () {
  losetup -P $LOOP_DEVICE_PATH "$1"
}

function unmap-image () {
  losetup --detach $LOOP_DEVICE_PATH
}

function convert-fs () {
  btrfs-convert "${LOOP_DEVICE_PATH}p2"
  mount "${LOOP_DEVICE_PATH}p2" $TEMP_MNT -t btrfs -o noatime,nodiratime,compress=zstd,space_cache=v2

  btrfs subvolume delete "$TEMP_MNT/ext2_saved"
  sync
  sleep 30
  btrfs balance start -dusage=70 -musage=70 "$TEMP_MNT" 
  sleep 30
  btrfs filesystem defrag -czstd -r $TEMP_MNT
  sleep 30
  btrfs subvolume snapshot -r $TEMP_MNT "$TEMP_MNT/raw"

  rm -rf "$TEMP_MNT" || true # this would skip /raw readonly subvolume

  btrfs subvolume snapshot "$TEMP_MNT/raw" "$TEMP_MNT/live"
  umount $TEMP_MNT
}

function mount-fs () {
  mount "${LOOP_DEVICE_PATH}p2" $TEMP_MNT -t btrfs -o noatime,nodiratime,compress=zstd,subvol=/live,space_cache=v2
  mount "${LOOP_DEVICE_PATH}p1" $TEMP_MNT/boot
}

function unmount-fs () {
  sync
  umount $TEMP_MNT/boot
  umount $TEMP_MNT
}

patch-files () {
  # a initramfs with btrfs kernel module (NOT WORKING)
  install -v "$(dirname "$0")/initramfs.gz" "$TEMP_MNT/boot/initramfs.gz"
  install --backup=numbered -v "$(dirname "$0")/cmdline.txt" "$TEMP_MNT/boot/cmdline.txt"
  install --backup=numbered -v "$(dirname "$0")/z999-revert-cmdline" $TEMP_MNT/etc/kernel/postinst.d/z999-revert-cmdline
  install --backup=numbered -v "$(dirname "$0")/z999-revert-cmdline" $TEMP_MNT/etc/kernel/postrm.d/z999-revert-cmdline
  install --backup=numbered -v -D "$(dirname "$0")/z999-revert-cmdline" $TEMP_MNT/etc/initramfs/post-update.d/z999-revert-cmdline
  install --backup=numbered -v "$(dirname "$0")/fstab" "$TEMP_MNT/etc/fstab"
}

if [[ $# -ne 1 ]] ; then
  echo "USAGE: $0 IMG_FILE"
  exit 1
fi

map-image "$1"

lsblk -o+fstype,uuid,partuuid,label

convert-fs

lsblk -o+fstype,uuid,partuuid,label

mount-fs

patch-files

unmount-fs

unmap-image
