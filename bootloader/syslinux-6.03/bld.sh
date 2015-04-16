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


# ******************************************************************************
# Definitions
# ******************************************************************************

PKG_URL="http://www.kernel.org/pub/linux/utils/boot/syslinux/"
PKG_ZIP="syslinux-6.03.tar.xz"
PKG_SUM=""

PKG_TAR="syslinux-6.03.tar"
PKG_DIR="syslinux-6.03"

# Function Arguments:
#      $1 ... Package name, like "glibc-2.19".

# ******************************************************************************
# pkg_patch
# ******************************************************************************

pkg_patch() {
PKG_STATUS=""
return 0
}

# ******************************************************************************
# pkg_configure
# ******************************************************************************

pkg_configure() {
PKG_STATUS=""
return 0
}

# ******************************************************************************
# pkg_make
# ******************************************************************************

pkg_make() {
PKG_STATUS=""
return 0
}

# ******************************************************************************
# pkg_install
# ******************************************************************************

pkg_install() {

PKG_STATUS="install error"

_dst="${BBLINUX_TARGET_DIR}/loader"

cp "${PKG_DIR}/bios/extlinux/extlinux"                 "${_dst}/extlinux"
cp "${PKG_DIR}/bios/linux/syslinux"                    "${_dst}/syslinux"
cp "${PKG_DIR}/bios/core/isolinux.bin"                 "${_dst}/isolinux.bin"
cp "${PKG_DIR}/bios/com32/elflink/ldlinux/ldlinux.c32" "${_dst}/ldlinux.c32"

cp "${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}/"loader*.msg "${_dst}/"
cp "${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}/"loader*.cfg "${_dst}/"

chmod 644 "${_dst}/"loader*.msg
chmod 644 "${_dst}/"loader*.cfg

unset _dst

PKG_STATUS=""
return 0

}

# ******************************************************************************
# pkg_clean
# ******************************************************************************

pkg_clean() {
PKG_STATUS=""
return 0
}

# end of file
