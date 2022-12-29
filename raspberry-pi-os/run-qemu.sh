#!/usr/bin/env bash

###
# starts qemu to run arm64 binaries
###


exec qemu-system-aarch64 -machine virt \
  -smp 8 -m 4G -cpu cortex-a72 -serial stdio -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
  -drive if=none,file=./2022-09-22-raspios-bullseye-arm64-lite.img,format=raw,id=hd \
  -device qemu-xhci -device usb-storage,drive=hd -boot menu=on -device VGA
