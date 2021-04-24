#!/usr/bin/bash

set -uex
set -o pipefail

BTRFS_MOUNT_OPTIONS="defaults,ssd,compress=zstd,noatime,nodiratime"

check_precondition () {
  if [[ ! -e "${DISK}p1" || ! -e "${DISK}p2" ]]; then
    echo "FAIL: disk expected at $DISK"
    exit 1
  fi

  if [[ -e "$WORKDIR" ]]; then
    echo "FAIL: WORKDIR $WORKDIR already exists"
    exit 1
  fi

}

prepare_disk () {
  mkfs.vfat "${DISK}p1"
  mkfs.btrfs -f "${DISK}p2"
}

prepare_workdir () {
  mkdir -pv "$WORKDIR"/{disk,live}
  mount -o "$BTRFS_MOUNT_OPTIONS,subvol=/" "${DISK}p2" "$WORKDIR/disk"
  btrfs subvolume create "$WORKDIR/disk/live"
  mount -o "$BTRFS_MOUNT_OPTIONS,subvol=/live" "${DISK}p2" "$WORKDIR/live"
  mkdir -pv "$WORKDIR"/live/boot "$WORKDIR"/live/media/sdcard
  mount -t vfat "${DISK}p1" "$WORKDIR/live/boot"
  mount -o "$BTRFS_MOUNT_OPTIONS,subvol=/" "${DISK}p2" "$WORKDIR/live/media/sdcard"
}

clearup_all () {
  umount "$WORKDIR/live/media/sdcard"
  umount "$WORKDIR/live/boot"
  umount "$WORKDIR/live"
  umount "$WORKDIR/disk"
  rm -rvf "$WORKDIR"
}

# =========
install_packages () {
  local ARCH_PACKAGES=$(grep -v '^#' < "$(dirname "$0")/manjaro_packages_rbpi.txt" )

  pacstrap -G -c -M "$WORKDIR/live" $ARCH_PACKAGES
  # FIXME: are these files required? what are valid ways to install them?
  # cp -v /boot/{pieeprom.upd,pieeprom.sig,vl805.bin,vl805.sig} "$WORKDIR/live/boot"
}

generate_configs () {
  genfstab -U -p "$WORKDIR/live" >> "$WORKDIR/live/etc/fstab"
  cp -v "$(dirname "$0" )/TEMPLATE-manjaro-cmdline.txt" "$WORKDIR/live/boot/cmdline.txt"
  cp -v "$(dirname "$0" )/TEMPLATE-manjaro-eth0.network" "$WORKDIR/live/etc/systemd/network/eth0.network"
  cp -v "$(dirname "$0" )/TEMPLATE-btrbk.conf" "$WORKDIR/live/root"

  cat "$(dirname "$0")/manjaro_init_script.sh" | arch-chroot "$WORKDIR/live" bash -uex -

  cat <<END
  REMAINED TASKS:
  arch-chroot $WORKDIR/live  ; AND
  - set hostname (\$EDITOR /etc/hostname)
  - revise /boot/cmdline.txt and set disk UUID
  - revise /etc/fstab
  - revise network config in /etc/systemd/network/eth0.network
  - change password
  - create more users as needed
END
}

# $1: loop disk, must already exist
# $2: workground directory, must not already exist
DISK="$1"
WORKDIR="$2"

check_precondition
prepare_disk
prepare_workdir
install_packages
generate_configs
# clearup_all
