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
# Make a tarball for installing onto some disk partition(s).
# *****************************************************************************

rootfs_tarball() {

echo -n "i> Making a bzip'd tarball of the root file system ... "
rm --force "${BBLINUX_TAR_NAME}"
tar	--directory="${BBLINUX_MNT_DIR}"	\
        --create				\
        --file="${BBLINUX_TAR_NAME%.bz2}" .
bzip2 "${BBLINUX_TAR_NAME%.bz2}"
echo "DONE"
ls -hl ${BBLINUX_TAR_NAME} | sed --expression="s|${BBLINUX_DIR}/||"
echo "i> File system tarball ${BBLINUX_TAR_NAME##*/} is ready."

ROOT_FS_NAME="${BBLINUX_TAR_NAME}"

}

# *****************************************************************************
# Build a root file system image to use for an init RAM Disk.
# *****************************************************************************

rootfs_initrd() {

local -i nblocks=$((${BBLINUX_ROOTFS_SIZE_MB} * 1024))

echo -n "i> Making root file system image for an init RAM Disk ... "
>${BBLINUX_MNT_DIR}/etc/.norootfsck
rm --force "${BBLINUX_IMG_NAME}"
genext2fs				\
	--reserved-percentage 0		\
	--root "${BBLINUX_MNT_DIR}"	\
	--size-in-blocks ${nblocks}	\
	"${BBLINUX_IMG_NAME}"
echo "DONE"
ls -hl ${BBLINUX_IMG_NAME} | sed --expression="s|${BBLINUX_DIR}/||"
echo "i> Root file system image ${BBLINUX_IMG_NAME##*/} is ready."

ROOT_FS_NAME="${BBLINUX_IMG_NAME}"

}

# *****************************************************************************
# Make a CPIO archive to use for an initramfs.
# *****************************************************************************

rootfs_initramfs() {

echo "i> Making a CPIO Archive for an initramfs ... "
>${BBLINUX_MNT_DIR}/etc/.norootfsck
pushd "${BBLINUX_MNT_DIR}" >/dev/null 2>&1
rm --force "${BBLINUX_IRD_NAME}.gz"
find . | cpio           \
        --create        \
        --format=newc   \
        --absolute-filenames >${BBLINUX_IRD_NAME}
popd >/dev/null 2>&1
gzip "${BBLINUX_IRD_NAME}"

echo "DONE"
ls -hl "${BBLINUX_IRD_NAME}.gz" | sed --expression="s|${BBLINUX_DIR}/||"
echo "i> File system CPIO archive ${BBLINUX_IRD_NAME##*/}.gz is ready."

ROOT_FS_NAME="${BBLINUX_IRD_NAME}.gz"

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
source ./bblinux-dnames.sh     # bblinux distribution name and revision
source ./bblinux-setenv.sh     # bblinux environment configuration
source ./scripts/_functions.sh # bblinux build support

bbl_root_check  || exit 1
bbl_dist_config || exit 1

PACKAGE_LIST=""
ROOT_FS_NAME=""

# *****************************************************************************
# Make a package list.
# *****************************************************************************

echo -n "i> Making package list ... "
for _p in $(ls "${BBLINUX_TARGET_DIR}/pkgbin"); do
	if [[ x"${_p:0:15}" == x"bblinux-basefs-" ]]; then
		PACKAGE_LIST="${_p} ${PACKAGE_LIST}"
	else
		PACKAGE_LIST="${PACKAGE_LIST} ${_p}"
	fi
done; unset _p
echo "DONE"

# *****************************************************************************
# Install packages into file system staging area ${BBLINUX_MNT_DIR}.
# *****************************************************************************

pushd "${BBLINUX_BUILD_DIR}/bld" >/dev/null 2>&1
echo "i> Installing packages."
for _p in ${PACKAGE_LIST}; do
	_b=${_p%-${BBLINUX_CPU}.tbz}
	echo "=> ${_b}"
	cp "${BBLINUX_TARGET_DIR}/pkgbin/${_p}" "${_b}.tar.bz2"
	bunzip2 --force "${_b}.tar.bz2"
	tar --extract --file="${_b}.tar" --directory=${BBLINUX_MNT_DIR}
	rm --force "${_b}.tar"
done; unset _p; unset _b
popd >/dev/null 2>&1

# *****************************************************************************
# Adjust the root file system as needed.
# *****************************************************************************

rm --force "${BBLINUX_BUILD_DIR}/bld/TIME_STAMP"
>"${BBLINUX_BUILD_DIR}/bld/TIME_STAMP"

echo -n "i> Applying rootfs overlay ... "
if [[ -n "${BBLINUX_ROOTFS_OVERLAY}:-" ]]; then
	_f="${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}/${BBLINUX_ROOTFS_OVERLAY}"
	tar --extract --file="${_f}" --directory=${BBLINUX_MNT_DIR}
	unset _f
fi
echo "DONE"

echo -n "i> mklost+found .............. "
(cd "${BBLINUX_MNT_DIR}"; mklost+found >/dev/null 2>&1)
echo "DONE"

echo -n "i> Updating birthdays ........ "
find "${BBLINUX_MNT_DIR}" -type d -o -type f \
	-exec touch --reference="${BBLINUX_BUILD_DIR}/bld/TIME_STAMP" {} \;
echo "DONE"

rm --force "${BBLINUX_BUILD_DIR}/bld/TIME_STAMP"

# *****************************************************************************
# Show the root system usage.
# *****************************************************************************

_msg=""
if [[ -n "${CONFIG_ROOTFS_SIZE_MB:-}" ]]; then
	_msg=" [file system size=${CONFIG_ROOTFS_SIZE_MB}MB]"
fi
echo "File system usage${_msg}:"
du -sh ${BBLINUX_MNT_DIR}
unset _msg

# *****************************************************************************
# Make the root file system image file.
# *****************************************************************************

if [[ x"${BBLINUX_ROOTFS_TARBALL:-}"   == x"y" ]]; then rootfs_tarball;   fi
if [[ x"${BBLINUX_ROOTFS_INITRD:-}"    == x"y" ]]; then rootfs_initrd;    fi
if [[ x"${BBLINUX_ROOTFS_INITRAMFS:-}" == x"y" ]]; then rootfs_initramfs; fi

# *****************************************************************************
# Clean the root file system staging area ${BBLINUX_MNT_DIR}.
# *****************************************************************************

rm --force --recursive "${BBLINUX_MNT_DIR}/"*

# *****************************************************************************
# Maybe do a post-operation on the generated root file system image file.
# *****************************************************************************

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

# *****************************************************************************
# Exit OK
# *****************************************************************************

unset PACKAGE_LIST
unset ROOT_FS_NAME

exit 0

# end of file
