#!/usr/bin/env bash

set -ue

if [[ $# -ne 2 ]]; then
  cat <<END
  USAGE: $0 DISK_IMAGE LOOP_DEVICE
  example: $0 /dev/loop123 Manjaro-ARM-minimal-rpi4-20.12.1.img
END
  exit 1
fi

cd $(dirname "$0")
source ./functions

set -x

truncate --size=3G "$2"

map-image "$1" "$2"

resize-partition-2 "$1"
