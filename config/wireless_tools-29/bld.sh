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

PKG_URL="http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/"
PKG_ZIP="wireless_tools.29.tar.gz"
PKG_SUM=""

PKG_TAR="wireless_tools.29.tar"
PKG_DIR="wireless_tools.29"

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

PKG_STATUS="make error"

cd "${PKG_DIR}"
source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_set"

PATH="${XTOOL_BIN_PATH}:${PATH}" \
make iwmulticall \
	--jobs=${NJOBS} \
	AR="${BBLINUX_XTOOL_NAME}-ar" \
	CC="${BBLINUX_XTOOL_NAME}-cc --sysroot=${BBLINUX_SYSROOT_DIR}" \
	RANLIB="${BBLINUX_XTOOL_NAME}-ranlib" \
	CFLAGS="${BBLINUX_CFLAGS}" \
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

PATH="${XTOOL_BIN_PATH}:${PATH}" \
CC="${BBLINUX_XTOOL_NAME}-cc --sysroot=${BBLINUX_SYSROOT_DIR}" \
PREFIX="${BBLINUX_SYSROOT_DIR}" \
make install-iwmulticall \
	CROSS_COMPILE=${BBLINUX_XTOOL_NAME}- || return 0

source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_clr"
cd ..

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
