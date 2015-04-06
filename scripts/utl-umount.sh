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
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #

# *****************************************************************************
# umount_initramfs
# *****************************************************************************

umount_initramfs() {

pushd "${BBLINUX_MNT_DIR}" >/dev/null 2>&1
rm --force "${BBLINUX_IRD_NAME}.gz"
find . | cpio           \
        --create        \
        --format=newc   \
        --absolute-filenames >${BBLINUX_IRD_NAME}
popd >/dev/null 2>&1

gzip "${BBLINUX_IRD_NAME}"

ROOT_FS_NAME="${BBLINUX_IRD_NAME}.gz"

rm --force --recursive "${BBLINUX_MNT_DIR}/"*

if [[ -n "${BBLINUX_ROOTFS_POST_OP:-}" ]]; then
	_path="${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}"
	_postop="${_path}/${BBLINUX_ROOTFS_POST_OP}"
	if [[ -x "${_postop}" ]]; then
		mv "${ROOT_FS_NAME}" "${ROOT_FS_NAME}-IN.gz"
		${_postop} "IN" "${ROOT_FS_NAME}-IN.gz" "${ROOT_FS_NAME}"
		rm --force "${ROOT_FS_NAME}-IN.gz"
	fi
	unset _path
	unset _postop
fi

}

# *****************************************************************************
# umount_initrd
# *****************************************************************************

umount_initrd() {
	:
}

# *****************************************************************************
# umount_tarball
# *****************************************************************************

umount_tarball() {
	:
}

# *************************************************************************** #
#                                                                             #
# M A I N   P R O G R A M                                                     #
#                                                                             #
# *************************************************************************** #

# *****************************************************************************
# Set up the shell functions and environment variables.
# *****************************************************************************

source ./bblinux-config.sh     # bblinux target build configuration
source ./bblinux-setenv.sh     # bblinux environment configuration
source ./scripts/_functions.sh # bblinux build support

bbl_root_check  || exit 1
bbl_dist_config || exit 1

# *****************************************************************************
# Get the cross-tool chain tarball, if needed.
# *****************************************************************************

if [[ ! -f "${BBLINUX_BUILD_DIR}/run/mount" ]]; then
	echo "e> Flag indicates nothing mounted."
	exit 1
fi

if [[ x"${BBLINUX_ROOTFS_INITRAMFS}" == x"y" ]]; then
	umount_initramfs
	rm --force "${BBLINUX_BUILD_DIR}/run/mount"
	exit 0
fi

if [[ x"${BBLINUX_ROOTFS_INITRD}" == x"y" ]]; then
	umount_initrd
	rm --force "${BBLINUX_BUILD_DIR}/run/mount"
	exit 0
fi

if [[ x"${BBLINUX_ROOTFS_TARBALL}" == x"y" ]]; then
	umount_tarball
	rm --force "${BBLINUX_BUILD_DIR}/run/mount"
	exit 0
fi

# *****************************************************************************
# Exit Error
# *****************************************************************************

exit 1

# end of file
