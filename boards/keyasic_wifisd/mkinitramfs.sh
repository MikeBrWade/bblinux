#!/bin/bash

# $1 ... This is the file system image file that was created; it needs to be
#        changed.  It is not compressed.
#
# $2 ... This is the root name of file system that this script must make.

# This script is should be run after making a standard cpio root file system
# image "initramfs".  This script makes a keyasic wifisd compatible cpio
# root file system image "initramfs".
#
# Pre-pend 0x4b41475aXXXXXXXX to the initramfs file, where 0x4b41475a is a
# magic number and XXXXXXXX is the size of rootfs.cpio.gz in bytes.
#
# TODO This might not be needed if the kernel is built differently from the
#      supplied keyasic wifisd kernel.
#
# FIXME The following printf probably doesn't work on big endian systems.

echo "keyasic_wifisd/mkinitramfs.sh operating ..."

gzip "${1}"
printf "0: 4b41475a%.8x" $(wc -c < "${1}.gz") |
	xxd -r -g0 |
	cat - "${1}.gz" > "${2}.gz"
gunzip "${1}.gz"

## /etc workaround: https://github.com/dankrause/kcard-buildroot/issues/4
#cp -an $TARGET_DIR/usr/share/mtd/etc/* $TARGET_DIR/etc

echo "keyasic_wifisd/mkinitramfs.sh DONE"

# *****************************************************************************
# # This script is automatically run just before image building.
# # Use it to modify the rootfs before everything is assembled into an image.
# # $1 is the path to the rootfs that's about to be built into an image.
# cd "$1"
# # Move /root to /usr/share/mtd/root so it ends up in /mnt/mtd/root
# mv root usr/share/mtd/
# ln -s /mnt/mtd/root root
# # Move /etc to /usr/share/mtd/etc so it ends up in /mnt/mtd/etc
# rm -rf etc/network
# mv etc usr/share/mtd/
# mkdir etc
# cp usr/share/mtd/etc/inittab etc
# cp usr/share/mtd/etc/fstab etc
# *****************************************************************************
