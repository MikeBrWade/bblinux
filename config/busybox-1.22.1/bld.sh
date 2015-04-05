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

PKG_URL="http://www.busybox.net/downloads/"
PKG_ZIP="busybox-1.22.1.tar.bz2"
PKG_SUM=""

PKG_TAR="busybox-1.22.1.tar"
PKG_DIR="busybox-1.22.1"

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

cp "${BBLINUX_CONFIG_DIR}/$1/_bbox.cfg" .config
CFLAGS="${BBLINUX_CFLAGS} --sysroot=${BBLINUX_SYSROOT_DIR}" \
PATH="${XTOOL_BIN_PATH}:${PATH}" make \
	--jobs=${NJOBS} \
	ARCH="${BBLINUX_CPU_ARCH}" \
	CROSS_COMPILE="${BBLINUX_XTOOL_NAME}-" \
	CONFIG_PREFIX=${BBLINUX_SYSROOT_DIR} \
	SKIP_STRIP=n \
	V=1 || return 1

source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_clr"
cd ..

PKG_STATUS=""
return 0

}

# ******************************************************************************
# pkg_install
# ******************************************************************************

pkg_install() {

PKG_STATUS="make install error"

cd "${PKG_DIR}"
source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_set"

# CFLAGS, ARCH and CROSS_COMPILE seem to be needed to make install.
# Change the location of awk.

CFLAGS="${BBLINUX_CFLAGS} --sysroot=${BBLINUX_SYSROOT_DIR}" \
PATH="${XTOOL_BIN_PATH}:${PATH}" make \
	ARCH="${BBLINUX_CPU_ARCH}" \
	CROSS_COMPILE="${BBLINUX_XTOOL_NAME}-" \
	CONFIG_PREFIX=${BBLINUX_SYSROOT_DIR} \
	install || return 1
rm "${BBLINUX_SYSROOT_DIR}/usr/bin/awk"
ln -s "busybox" "${BBLINUX_SYSROOT_DIR}/bin/awk"

source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_clr"
cd ..

if [[ -d "rootfs/" ]]; then
	find "rootfs/" ! -type d -exec touch {} \;
	cp --archive --force rootfs/* "${BBLINUX_SYSROOT_DIR}"
fi

ln -s sbin/init "${BBLINUX_SYSROOT_DIR}/init"

for f in ${BBLINUX_SYSROOT_DIR}/etc/issue*; do
	if [[ -f "${f}" ]]; then
		sedCmd="sed --in-place ${f}"
		nameStr="[${BBLINUX_DIST_NAME}]\nfile system build -- $(date)"
		${sedCmd} --expression="s/@@VERSION@@/${BBLINUX_DIST_VERS}/"
		${sedCmd} --expression="s/\[@@NAME@@]/${nameStr}/"
		${sedCmd} --expression="s/^[\\]m/${BBLINUX_CPU_ARCH}/"
		unset sedCmd
		unset nameStr
	fi
done
unset f

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
