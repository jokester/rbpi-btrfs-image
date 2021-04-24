#!/usr/bin/env bash

set -ue

if [[ $# -ne 2 ]]; then
  cat <<END
  USAGE: $0 DISK_IMAGE LOOP_DEVICE
  example: $0 /dev/loop123 20201112_raspi_4.img
END
  exit 1
fi

cd $(dirname "$0")
source ./functions

prepare-mountpoints

set -x

map-image "$1" "$2"

convert-partition "$1"

debian-patch-boot "$1"

cleanup "$1"
