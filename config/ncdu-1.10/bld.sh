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

PKG_URL="http://dev.yorhel.nl/download/"
PKG_ZIP="ncdu-1.10.tar.gz"
PKG_SUM=""

PKG_TAR="ncdu-1.10.tar"
PKG_DIR="ncdu-1.10"

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

PKG_STATUS="./configure error"

cd "${PKG_DIR}"
source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_set"

PATH="${XTOOL_BIN_PATH}:${PATH}" \
AR="${BBLINUX_XTOOL_NAME}-ar" \
AS="${BBLINUX_XTOOL_NAME}-as --sysroot=${BBLINUX_SYSROOT_DIR}" \
CC="${BBLINUX_XTOOL_NAME}-cc --sysroot=${BBLINUX_SYSROOT_DIR}" \
CXX="${BBLINUX_XTOOL_NAME}-c++ --sysroot=${BBLINUX_SYSROOT_DIR}" \
LD="${BBLINUX_XTOOL_NAME}-ld --sysroot=${BBLINUX_SYSROOT_DIR}" \
NM="${BBLINUX_XTOOL_NAME}-nm" \
OBJCOPY="${BBLINUX_XTOOL_NAME}-objcopy" \
RANLIB="${BBLINUX_XTOOL_NAME}-ranlib" \
SIZE="${BBLINUX_XTOOL_NAME}-size" \
STRIP="${BBLINUX_XTOOL_NAME}-strip" \
CFLAGS="${BBLINUX_CFLAGS}"
./configure \
	--build=${BBLINUX_BUILD} \
	--host=${BBLINUX_XTOOL_NAME} \
	--prefix=/usr \
	--with-ncurses || return 0

source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_clr"
cd ..

PKG_STATUS=""
return 0

}

# ******************************************************************************
# pkg_make
# ******************************************************************************

pkg_make() {

PKG_STATUS="make error"

cd "${PKG_DIR}"
source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_set"

PATH="${XTOOL_BIN_PATH}:${PATH}" make --jobs=${NJOBS} \
	CROSS_COMPILE=${BBLINUX_XTOOL_NAME}- || return 0

source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_clr"
cd ..

PKG_STATUS=""
return 0

}

# ******************************************************************************
# pkg_install
# ******************************************************************************

pkg_install() {

PKG_STATUS="install error"

cd "${PKG_DIR}"
source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_set"

CFLAGS="${BBLINUX_CFLAGS} --sysroot=${BBLINUX_SYSROOT_DIR}" \
PATH="${XTOOL_BIN_PATH}:${PATH}" make \
        CROSS_COMPILE="${BBLINUX_XTOOL_NAME}-" \
	DESTDIR="${BBLINUX_SYSROOT_DIR}" \
        install || return 1

source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_clr"
cd ..

if [[ -d "rootfs/" ]]; then
	find "rootfs/" ! -type d -exec touch {} \;
	cp --archive --force rootfs/* "${BBLINUX_SYSROOT_DIR}"
fi

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
