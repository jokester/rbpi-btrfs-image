# debian-rbpi-btrfs-image

Scripts to convert Debian's Raspberry Pi disk images to btrfs.

The reason behind this:
I generally prefer btrfs over ext for Raspberry Pi.
Its transparent compression and subvolume snapshot/send/receive makes huge
difference with less durable and less performant storage like SD card.

## Disclaimer

This script is written for, and only tested on, Raspberry Pi 4B. I don't own other Pi-s to try on.

Glad to hear how it works for other models.

<!--
(It *likely* work on other images: all images are build with [similar configurations](https://salsa.debian.org/raspi-team/image-specs))
-->

## How to run

(Linux required)

1. Download and uncompress disk image from https://raspi.debian.net/
2. As `root`, run `patch-image.sh IMAGE_FILE LOOP_DEVICE`
    - example: `./patch-image.sh 20201112_raspi_4.img /dev/loop123`
3. After the script succeeds, write updated image file to SD card

## What this script do

1. Convert `ext4` partition to a btrfs subvolume.
    - Old script to resize ext4 partition is removed. To resize partition you will need to `fdisk` and `btrfs filesystem resize` manually.
2. Move all files into a btrfs subvolume. This enables easier snapshot / backup.
3. Mount `/` from the new subvolume.

## License

BSD 2-Clause License. See [LICENSE](LICENSE)
