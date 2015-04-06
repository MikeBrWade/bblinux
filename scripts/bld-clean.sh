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

source ./bblinux-config.sh     # bblinux target build configuration
source ./bblinux-dnames.sh     # bblinux distribution name and revision
source ./bblinux-setenv.sh     # bblinux environment configuration
source ./scripts/_functions.sh # bblinux build support

bbl_root_check  || exit 1
bbl_dist_config || exit 1

declare -i CLEAN=0

# *****************************************************************************
# Maybe remove the kernel parts and their build log files.
# *****************************************************************************

if [[ $# -gt 0 ]]; then
	[[ x"$1" == x"all" || x"$1" == x"kernel" ]] && {
		CLEAN=1
		echo "i> Removing kernel modules package, if any."
		rm --force --recursive "${BBLINUX_TARGET_DIR}/kpkgs/"*
		echo "i> Removing kernel and module tree, if any."
		rm --force --recursive "${BBLINUX_TARGET_DIR}/kroot/"*
		for _file in "${BBLINUX_BUILD_DIR}/log/k."*; do
			rm --force ${_file}
		done
		unset _file
	}
fi

# *****************************************************************************
# Maybe remove the packages and their build log files.
# *****************************************************************************

if [[ $# -gt 0 ]]; then
	[[ x"$1" == x"all" || x"$1" == x"packages" ]] && {
		CLEAN=1
		echo "i> Removing the packages:"
		echo "=> Removing sysroot contents."
		rm --force --recursive "${BBLINUX_SYSROOT_DIR}/"*
		echo "=> Removing target/pkgbin/ binary packages."
		rm --force --recursive "${BBLINUX_TARGET_DIR}/pkgbin/"*
		echo "=> Removing build/log/ build logs."
		for _file in "${BBLINUX_BUILD_DIR}/log/p."*; do
			rm --force ${_file}
		done
		unset _file
		echo "=> Removing build/run/done. build flags."
		rm --force --recursive "${BBLINUX_BUILD_DIR}/run/done."*
	}
fi

# *****************************************************************************
# Maybe remove the boot loader and its build log file.
# *****************************************************************************

if [[ $# -gt 0 ]]; then
	[[ x"$1" == x"all" || x"$1" == x"loader" ]] && {
		CLEAN=1
		echo "i> Removing target/loader binary packages."
		rm --force --recursive "${BBLINUX_TARGET_DIR}/loader/"*
		for _file in "${BBLINUX_BUILD_DIR}/log/l."*; do
			rm --force ${_file}
		done
		unset _file
	}
fi

# *****************************************************************************
# Cleaning any part of the build invalidates any file system images, so always
# remove these.
# *****************************************************************************

if [[ ${CLEAN} -eq 1 ]]; then
	echo "i> Removing file system images."
	rm --force --recursive "${BBLINUX_TARGET_DIR}/image/"*
fi
rm --force --recursive "${BBLINUX_BUILD_DIR}/bld/"*

# *****************************************************************************
# Exit OK
# *****************************************************************************

unset CLEAN

exit 0

# end of file
