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
# mount_initramfs
# *****************************************************************************

mount_initramfs() {

local ROOT_FS="${BBLINUX_IRD_NAME}.gz"
local TMP_RFS="${BBLINUX_IRD_NAME}-OUT.gz"

if [[ -n "${BBLINUX_ROOTFS_POST_OP:-}" ]]; then
        _path="${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}"
        _postop="${_path}/${BBLINUX_ROOTFS_POST_OP}"
        if [[ -x "${_postop}" ]]; then
		_inName="${BBLINUX_IRD_NAME}-IN.gz"
                cp "${ROOT_FS}" "${_inName}"
                ${_postop} "OUT" "${_inName}" "${TMP_RFS}"
                rm --force "${_inName}"
		unset _inName
        fi
        unset _path
        unset _postop
else
	cp "${ROOT_FS}" "${TMP_RFS}"
fi

pushd "${BBLINUX_MNT_DIR}" >/dev/null 2>&1

gunzip -c "${TMP_RFS}" | cpio -i
chmod -R go-w . # fix permissions

popd >/dev/null 2>&1

rm --force "${TMP_RFS}"

}

# *****************************************************************************
# mount_initrd
# *****************************************************************************

mount_initrd() {
	:
}

# *****************************************************************************
# mount_tarball
# *****************************************************************************

mount_tarball() {
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

if [[ -f "${BBLINUX_BUILD_DIR}/run/mount" ]]; then
	echo "E> Flag indicates already mounted. Run 'make ummount'."
	exit 1
fi

if [[ x"${BBLINUX_ROOTFS_INITRAMFS}" == x"y" ]]; then
	if [[ ! -f "${BBLINUX_IRD_NAME}.gz" ]]; then
		echo "i> Nothing to mount"
		exit1
	fi
	mount_initramfs
	touch "${BBLINUX_BUILD_DIR}/run/mount"
	exit 0
fi

if [[ x"${BBLINUX_ROOTFS_INITRD}" == x"y" ]]; then
	if [[ ! -f "${BBLINUX_IMG_NAME}" ]]; then
		echo "i> Nothing to mount"
		exit1
	fi
	mount_initrd
	touch "${BBLINUX_BUILD_DIR}/run/mount"
	exit 0
fi

if [[ x"${BBLINUX_ROOTFS_TARBALL}" == x"y" ]]; then
	if [[ ! -f "${BBLINUX_TAR_NAME}" ]]; then
		echo "i> Nothing to mount"
		exit1
	fi
	mount_tarball
	touch "${BBLINUX_BUILD_DIR}/run/mount"
	exit 0
fi

# *****************************************************************************
# Exit Error
# *****************************************************************************

exit 1

# end of file
