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
source ./bblinux-setenv.sh     # bblinux environment configuration
source ./scripts/_functions.sh # bblinux build support

# *****************************************************************************
# Check if the cross-tool chain already exists.
# *****************************************************************************

if [[ -d "${BBLINUX_XTOOLS_DIR}/${BBLINUX_XTOOL_NAME}" ]]; then
	echo "${BBLINUX_XTOOL_NAME} cross-tool chain already exists."
	echo "x-tools/:"
	ls -1F "${BBLINUX_XTOOLS_DIR}"
	exit 0
fi

# *****************************************************************************
# Get the cross-tool chain tarball.
# *****************************************************************************

bbl_get_file ${BBLINUX_XTOOL_FNAME} ${BBLINUX_XTOOL_EXT} ${BBLINUX_XTOOL_URL}
if [[ ${G_NMISSING} != 0 ]]; then
	echo -e "${TEXT_BRED}Error${TEXT_NORM}:"
	echo "Failed to download ${BBLINUX_XTOOL_FNAME}${BBLINUX_XTOOL_EXT}"
	echo "from ${BBLINUX_XTOOL_URL}"
	echo "Check the ${BBLINUX_CONFIG} file."
	unset G_NMISSING
	exit 1
fi

# *****************************************************************************
# Get the cross-tool chain tarball, if needed.
# *****************************************************************************

# Use a subshell so the current working directory can be changed and shell
# variables can be assaulted without affecting this script.

(
# Go to the build directory and clean it.
echo "Cleaning build directory ..."
cd "${BBLINUX_BUILD_DIR}/bld" || exit 2
rm --force --recursive *

# Untar the cross-tool package and go into its top-level directory.
echo "Uncompressing ${BBLINUX_XTOOL_FNAME}${BBLINUX_XTOOL_EXT} ..."
tar xf "${BBLINUX_DLOAD_DIR}/${BBLINUX_XTOOL_FNAME}${BBLINUX_XTOOL_EXT}"
cd ${BBLINUX_XTOOL_FNAME}

# Make the cross-tool chain builder.
./bootstrap
./configure --enable-local
MAKELEVEL=0 make

# Get the cross-tool chain configuration file.
cp ${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}/${BBLINUX_XTOOL_CFG} .config
_dloaddir="${BBLINUX_DLOAD_DIR}"
_xtooldir="${BBLINUX_XTOOLS_DIR}"
_boarddir="${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}"
sed --expression="s|@@DLOAD_DIR@@|${_dloaddir}|" --in-place .config
sed --expression="s|@@XTOOL_DIR@@|${_xtooldir}|" --in-place .config
sed --expression="s|@@BOARD_DIR@@|${_boarddir}|" --in-place .config
unset _dloaddir
unset _xtooldir
unset _boarddir

# Make the cross-tool chain.
./ct-ng build

# Cleanup
cd ..
echo "Removing ${BBLINUX_XTOOL_FNAME} directory ..."
rm -rf ${BBLINUX_XTOOL_FNAME}
)

# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0

# end of file
