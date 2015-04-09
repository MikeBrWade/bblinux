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

PKG_URL="http://www.uclibc.org/downloads/"
PKG_ZIP="uClibc-0.9.33.2.tar.xz"
PKG_SUM=""

PKG_TAR="uClibc-0.9.33.2.tar"
PKG_DIR="uClibc-0.9.33.2"

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

local kname=""
local tag=""

PKG_STATUS="install error"

# Get the linux kernel source tree and export the header files to a directory
# named "linux-headers".
#
if   [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tgz$      ]]; then tag=".tgz";
elif [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tar\.gz$  ]]; then tag=".tar.gz";
elif [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tbz$      ]]; then tag=".tbz";
elif [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tar\.bz2$ ]]; then tag=".tar.bz2";
elif [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tar\.xz$  ]]; then tag=".tar.xz";
fi
kname=${BASH_REMATCH[1]}
if   [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tar.xz"  ]]; then tag=".tar.xz";
elif [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tar.bz2" ]]; then tag=".tar.bz2";
elif [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tbz"     ]]; then tag=".tbz";
elif [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tar.gz"  ]]; then tag=".tar.gz";
elif [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tgz"     ]]; then tag=".tgz";
fi
export BBLINUX_LINUX_TAR="${kname}${tag}"
tar --extract --file="${BBLINUX_DLOAD_DIR}/${BBLINUX_LINUX_TAR}"
cd "${BBLINUX_LINUX_DIR}"
make ARCH=${BBLINUX_LINUX_ARCH} \
	INSTALL_HDR_PATH="../linux-headers" \
	headers_install
cd ..
rm --force --recursive "${BBLINUX_LINUX_DIR}"

# Get the uClibc config file and set KERNEL_HEADERS to the new directory of
# kernel header files just made in the step above.
#
_uclibcConfig="${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}/uclibc-0.9.33.2.config"
cp "${_uclibcConfig}" "${PKG_DIR}/.config"
unset _uclibcConfig
sed \
	-e "s|^KERNEL_HEADERS=.*|KERNEL_HEADERS=\"../linux-headers/include\"|" \
	-i "${PKG_DIR}/.config"

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
make utils \
	CC="${BBLINUX_XTOOL_NAME}-cc --sysroot=${BBLINUX_SYSROOT_DIR}" \
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

_install="install --mode=755 --owner=0 --group=0"
${_install} "${PKG_DIR}/utils/ldconfig" "${BBLINUX_SYSROOT_DIR}/sbin/"
${_install} "${PKG_DIR}/utils/getconf"  "${BBLINUX_SYSROOT_DIR}/usr/bin/"
${_install} "${PKG_DIR}/utils/ldd"      "${BBLINUX_SYSROOT_DIR}/usr/bin/"
unset _install

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

PKG_STATUS="clean error"

rm --force --recursive "linux-headers"

PKG_STATUS=""
return 0

}

# end of file
