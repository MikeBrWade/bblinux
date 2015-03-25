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
# bbl_get_file
# *****************************************************************************

# Usage: bbl_get_file <file_root_name> <file_name_extension> <url> [url ...]
#
#      Example:
#      <file_root_name> ........ something like "cloog-0.16.1"
#      <file_name_extension> ... something like ".tar.gz"
#      for downloading cloog-0.16.1.tar.gz from <url> [url ...]

bbl_get_file() {

local fileName=""
local fileExtn=""
local haveFile="no"
local loadedDn="no"
local url

[[ -z "${1}" ]] && return 0 || true # must have file_root_name
[[ -z "${2}" ]] && return 0 || true # must have file_name_extension
[[ -z "${3}" ]] && return 0 || true # must have url

fileName="$1"
fileExtn="$2"

# Go to the urls.
#
shift
shift

pushd "${BBLINUX_DLOAD_DIR}" >/dev/null 2>&1

echo -n "i> Checking ${fileName} "
for ((i=(25-${#fileName}) ; i > 0 ; i--)); do echo -n "."; done

rm -f "${fileName}.download.log"

# Maybe the file doesn't get downloaded.  Check $1 which is the first URL.
#
if [[ x"$1" == x"(x-tools)" ]]; then
	echo " (comes from x-tools)" 
	return 0
fi
if [[ x"$1" == x"(local)" ]]; then
	echo " (local)" 
	return 0
fi

# If the file is already in ${BBLINUX_DLOAD_DIR} then return.
#
[[ -f "${fileName}${fileExtn}" ]] && haveFile="yes" || true
if [[ "${haveFile}" == "yes" ]]; then
	echo " have it"
	popd >/dev/null 2>&1
	return 0
fi

echo -n " downloading ..... "

# See if there is a local copy of the file.
#
if [[ -f ${BBLINUX_CACHE_DIR}/${fileName}${fileExtn} ]]; then
	cp ${BBLINUX_CACHE_DIR}/${fileName}${fileExtn} .
	[[ -f "${fileName}${fileExtn}" ]] && loadedDn="yes" || true
fi
if [[ "${loadedDn}" == "yes" ]]; then
	echo "(got from local cache)"
	popd >/dev/null 2>&1
	return 0
fi

# See if there is a program to use to download the file.
#
_wget=$(which wget 2>/dev/null || true)
if [[ -z "${_wget}" ]]; then
	echo "cannot find wget-- no download."
	popd >/dev/null 2>&1
	unset _wget
	return 0
fi
_wget="${_wget} -T 10 -nc --progress=dot:binary --tries=3"
_file=""

# Try to download the file from the urls.
#
rm -f "${fileName}.download.log"
>"${fileName}.download.log"
for url in "$@"; do
	_file="${url}/${fileName}${fileExtn}"
	if [[ "${loadedDn}" == "no" ]]; then
		(					\
		${_wget} --passive-ftp "${_file}" ||	\
		${_wget} "${_file}" ||			\
		true					\
		) >>"${fileName}.download.log" 2>&1
		[[ -f "${fileName}${fileExtn}" ]] && loadedDn="yes" || true
	fi
done
unset _wget
unset _file

if [[ "${loadedDn}" == "yes" ]]; then
	echo "done."
	rm -f "${fileName}.download.log"
else
	echo "FAILED."
	G_MISSED_PKG[${G_NMISSING}]="${fileName}${fileExtn}"
	G_MISSED_URL[${G_NMISSING}]="${url}"
	G_NMISSING=$((${G_NMISSING} + 1))
fi

popd >/dev/null 2>&1
return 0

}

# *****************************************************************************
# Check for being root.
# *****************************************************************************

bbl_root_check() {

if [[ $(id -u) -ne 0 ]]; then
	echo "E> Only root can do this (scary)." >&2
	return 1
fi

if [[ $(id -g) -ne 0 ]]; then
	echo "E> Must be in the root group, not the $(id -gn) group." >&2
	echo "E> Try using 'newgrp - root'." >&2
	return 1
fi

return 0

}

# *****************************************************************************
# Check the distribution specifications.
# *****************************************************************************

bbl_dist_config() {

BBLINUX_CPU=${BBLINUX_XTOOL_NAME%%-*}

_path="${BBLINUX_TARGET_DIR}/image"
BBLINUX_IMG_NAME="${_path}/${BBLINUX_ROOTFS_BASE_NAME}"
BBLINUX_IRD_NAME="${_path}/${BBLINUX_ROOTFS_BASE_NAME}"
BBLINUX_TAR_NAME="${_path}/${BBLINUX_ROOTFS_BASE_NAME}.tar.bz2"
unset _path

XTOOL_BIN_PATH="${BBLINUX_XTOOLS_DIR}/${BBLINUX_XTOOL_NAME}/bin"

return 0

}


# *****************************************************************************
# Mount the target filesystem.
# *****************************************************************************

build_spec_show() {

# Report on what we think we are doing.
#
echo "=> ttylinux project directory:"
echo "   ${TTYLINUX_DIR}"
echo "=> ttylinux-${BBLINUX_DIST_VERS} [${TTYLINUX_NAME}]"
echo "=> with ${TTYLINUX_XBT} cross-tool chain"
echo "=> with ${TTYLINUX_CPU} cross-building Binutils ${XBT_XBINUTILS_VER}"
echo "=> with ${TTYLINUX_CPU} cross-building GCC ${XBT_XGCC_VER}"
echo "=> with libc ${XBT_LIBC_VER}, kernel interface:"
echo "        libc interface to Linux kernel ${XBT_LINUX_ARCH} architecture"
echo "        libc interface to Linux kernel ${XBT_LINUX_VER}"
echo "=> for ${TTYLINUX_RAMDISK_SIZE} MB target file system image size"

return 0

}


# *****************************************************************************
# Mount the target filesystem.
# *****************************************************************************

ttylinux_target_mount() {

if [[ -n "$(mount | grep \"${TTYLINUX_IMG_NAME}\")" ]]; then
        echo "E> Already mounted." >&2
        echo "E> ${TTYLINUX_IMG_NAME}" >&2
        return 0
fi

set +e
echo -n "Mounting ..... "
mount -t ext2 -o loop ${TTYLINUX_IMG_NAME} ${TTYLINUX_MNT_DIR}
[[ $? -eq 0 ]] && echo "OK" || echo "FAILED"
set -e

return 0

}


# *****************************************************************************
# Unmount the target filesystem.
# *****************************************************************************

ttylinux_target_umount() {

set +e
echo -n "Unmounting ... "
umount -d ${TTYLINUX_MNT_DIR} 2>/dev/null
[[ $? -eq 0 ]] && echo "OK" || echo "FAILED"
set -e

return 0

}


# *****************************************************************************
# Make a comment.
# *****************************************************************************

ttylinux_build_comment() {

echo "#; $1"

}


# *****************************************************************************
# Make a comment; then execute it.
# *****************************************************************************

ttylinux_build_command() {

echo "#+ $1"
eval $1

}


# *****************************************************************************
# Get the ttylinux kernel source and config file.
# *****************************************************************************

ttylinux_kernel_get() {

local kver="${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}"
local srcd="${TTYLINUX_KERNEL_SRCDIR}"
local kcfg="${TTYLINUX_KERNEL_CONFIG}"

ttylinux_build_comment ""
ttylinux_build_comment "kernel source"
ttylinux_build_comment "=> ${srcd}/linux-${kver}.tar.bz2"

# Look for the linux kernel tarball.
#
if [[ ! -f "${srcd}/linux-${kver}.tar.bz2" ]]; then
	echo "E> Linux kernel source tarball not found." >&2
	echo "=> ${srcd}/linux-${kver}.tar.bz2" >&2
	exit 1
fi

ttylinux_build_comment ""
ttylinux_build_comment "kernel config"
ttylinux_build_comment "=> ${kcfg}"

# Look for the linux kernel configuration file.
#
if [[ ! -f "${kcfg}" ]]; then
	echo "E> Linux kernel configuration file not found." >&2
	echo "=> ${kcfg}" >&2
	exit 1
fi

# Cleanup any previous left-over build results.
#
rm --force --recursive linux-${kver}*/
rm --force --recursive linux/

# Uncompress, untarr then remove linux-${kver}.tar.bz2 and put the kernel
# configuration file in place.
#
ttylinux_build_comment ""
ttylinux_build_command "cp ${srcd}/linux-${kver}.tar.bz2 linux-${kver}.tar.bz2"
ttylinux_build_command "bunzip2 --force linux-${kver}.tar.bz2"
ttylinux_build_command "tar --extract --file=linux-${kver}.tar"
ttylinux_build_command "rm --force linux-${kver}.tar"
ttylinux_build_command "cp ${kcfg} linux-${kver}/.config"

}


# *****************************************************************************
# Add any add-ins and patches.
# *****************************************************************************

ttylinux_kernel_addin_and_patch() {

local kver="${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}"

# Do nothing herein for custom kernels.
#
if [[ -n "${TTYLINUX_USER_KERNEL:-}" ]]; then
	return 0
fi

cd "linux-${kver}"

# This is for older kernels; it is harmless otherwise.
#
if [[ -f scripts/unifdef.c ]]; then
	_cmd="sed -e \"s/getline/uc_&/\" -i scripts/unifdef.c"
	ttylinux_build_comment ""
	ttylinux_build_command "${_cmd}"
	unset _cmd
fi

# This is for older kernels; it is harmless otherwise.
#
if [[ -f scripts/mod/sumversion.c ]]; then
	_old="<string.h>"
	_new="<limits.h>\n#include <string.h>"
	_cmd="sed -e \"s|${_old}|${_new}|\" -i scripts/mod/sumversion.c"
	ttylinux_build_comment ""
	ttylinux_build_command "${_cmd}"
	unset _old
	unset _new
	unset _cmd
fi

# Add-in
#
_tarFile="${TTYLINUX_PLATFORM_DIR}/kernel-${TTYLINUX_CONFIG}-add_in.tar.bz2"
if [[ -f ${_tarFile} ]]; then
	_cmd="tar --extract --file=${_tarFile}"
	ttylinux_build_comment ""
	ttylinux_build_comment "Adding kernel-${TTYLINUX_CONFIG}-add_in.tar.bz2"
	ttylinux_build_command "${_cmd}"
	unset _cmd
fi
unset _tarFile

# Patches
#
for p in ${TTYLINUX_PLATFORM_DIR}/kernel-${TTYLINUX_CONFIG}-??.patch; do
	if [[ -f "${p}" ]]; then
		_cmd="patch -p1 <${p}"
		ttylinux_build_command "${_cmd}"
		unset _cmd
	fi
done

# This is a test to see if a gcc version 4.6.0 or newer is being used on a
# kernel older than 3.0; this is the case with the current ttylinux mac_g4
# kernel and its xbuildtool gcc.  In this case, a bunch of warnings will kill
# the cross-compile of the kernel, but we know the kernel will actually work;
# so Crazy Hack the kernel Makefile to not make warnings be errors.
#
if [[ "${BBLINUX_BOARD}" = "mac_g4" ]]; then
	(source "${TTYLINUX_XTOOL_DIR}/_xbt_env_set"
	_kerVer=${kver%%.*}
	_gccVer=${XBT_XGCC_VER#gcc-}
	_gccVer=${_gccVer//./}
	if [[ ${_kerVer} -lt 3 && ${_gccVer} -gt 460 ]]; then
		ttylinux_build_comment ""
		ttylinux_build_comment "Doing the whacky fix."
		ttylinux_build_comment ""
		sed -e "s|^KBUILD_AFLAGS_KERNEL|KBUILD_CFLAGS += -Wno-error=unused-but-set-variable\nKBUILD_AFLAGS_KERNEL|" -i Makefile
	else
		echo ""                                 >${CONSOLE_FD}
		echo "********************************" >${CONSOLE_FD}
		echo "ERROR !! ERROR"                   >${CONSOLE_FD}
		echo "********************************" >${CONSOLE_FD}
		echo "Fix the cheap mac_g4 kernel hack" >${CONSOLE_FD}
		echo "in scripts/bld-kernel.sh"         >${CONSOLE_FD}
		echo "********************************" >${CONSOLE_FD}
		echo "ERROR !! ERROR"                   >${CONSOLE_FD}
		echo "********************************" >${CONSOLE_FD}
		echo ""                                 >${CONSOLE_FD}
	fi)
fi

cd ..

}

# *************************************************************************** #
#                                                                             #
# _ f u n c t i o n s   B o d y                                               #
#                                                                             #
# *************************************************************************** #

TEXT_BRED="\E[1;31m"    # bold+red
TEXT_BGREEN="\E[1;32m"  # bold+green
TEXT_BYELLOW="\E[1;33m" # bold+yellow
TEXT_BBLUE="\E[1;34m"   # bold+blue
TEXT_BPURPLE="\E[1;35m" # bold+purple
TEXT_BCYAN="\E[1;36m"   # bold+cyan
TEXT_BOLD="\E[1;37m"    # bold+white
TEXT_RED="\E[0;31m"     # red
TEXT_GREEN="\E[0;32m"   # green
TEXT_YELLOW="\E[0;33m"  # yellow
TEXT_BLUE="\E[0;34m"    # blue
TEXT_PURPLE="\E[0;35m"  # purple
TEXT_CYAN="\E[0;36m"    # cyan
TEXT_NORM="\E[0;39m"    # normal

_TB=$'\t'
_NL=$'\n'
_SP=$' '

export IFS="${_SP}${_TB}${_NL}"
export LC_ALL=POSIX
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

unset _TB
unset _NL
unset _SP

set -o errexit ; # Exit immediately if a command exits with a non-zero status.
set -o nounset ; # Treat unset variables as an error when substituting.

umask 022

# *************************************************************************** #
#                                                                             #
# G L O B A L   D A T A                                                       #
#                                                                             #
# *************************************************************************** #

# For failed downloads from bbl_get_file()
G_MISSED_PKG[0]=""
G_MISSED_URL[0]=""
G_NMISSING=0

# end of file
