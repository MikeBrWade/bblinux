#!/bin/bash

# The license which this software falls under is GPLv2 as follows:
#
# Copyright (C) 2015-2015 Big Palooka <bpalooka@palooka.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA  02111-1307  USA

# *************************************************************************** #
#                                                                             #
# M A I N   P R O G R A M                                                     #
#                                                                             #
# *************************************************************************** #

# *****************************************************************************
# Set up the shell functions and environment variables.
# *****************************************************************************

K_PKGLIST="$1"

source ./bblinux-config.sh     # bblinux target build configuration
source ./bblinux-setenv.sh     # bblinux environment configuration
source ./scripts/_functions.sh # bblinux build support

# *****************************************************************************
# Get the cross-tool chain tarball, if needed.
# *****************************************************************************

echo "##### START making the CD-ROM staging area."
echo ""

echo -n "i> Recreating ISO directory .......................... "
rm --force --recursive cdrom/
mkdir --mode=755 cdrom/
mkdir --mode=755 cdrom/boot/
mkdir --mode=755 cdrom/boot/isolinux/
echo "DONE"

echo -n "i> Gathering boot files .............................. "
_dest=cdrom/boot/isolinux/
cp "${BBLINUX_TARGET_DIR}/loader/isolinux.bin" ${_dest}
cp "${BBLINUX_TARGET_DIR}/loader/loader.cfg"   ${_dest}
cp "${BBLINUX_TARGET_DIR}/loader/loader.msg"   ${_dest}
cp "${BBLINUX_TARGET_DIR}/loader/loader_2.msg" ${_dest}
cp "${BBLINUX_TARGET_DIR}/loader/loader_3.msg" ${_dest}
cp "${BBLINUX_TARGET_DIR}/loader/loader_4.msg" ${_dest}
unset _dest
chmod 644 cdrom/boot/isolinux/*
cp "${BBLINUX_TARGET_DIR}/image/initramfs.gz" cdrom/boot/initramfs.gz
cp "${BBLINUX_TARGET_DIR}/kroot/boot/bzImage" cdrom/boot/vmlinuz
echo "DONE"

echo ""
echo "##### DONE making the CD-ROM staging area."

# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0

# end of file
