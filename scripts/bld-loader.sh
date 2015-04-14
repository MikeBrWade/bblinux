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
# Get and untar a source package.
# *****************************************************************************

package_get() {

# Function Arguments:
# $1 ... Source package zip-file name, like "lynx2.8.7.tar.bz2".

local srcPkg="$1"
local tarBall=""
local unZipper=""

if   [[ "$1" =~ (.*)\.tgz$      ]]; then unZipper="gunzip --force";
elif [[ "$1" =~ (.*)\.tar\.gz$  ]]; then unZipper="gunzip --force";
elif [[ "$1" =~ (.*)\.tbz$      ]]; then unZipper="bunzip2 --force";
elif [[ "$1" =~ (.*)\.tar\.bz2$ ]]; then unZipper="bunzip2 --force";
elif [[ "$1" =~ (.*)\.tar\.xz$  ]]; then unZipper="xz --decompress --force";
fi

if [[ -n "${unZipper}" ]]; then
	tarBall="${BASH_REMATCH[1]}.tar"
	cp "${BBLINUX_DLOAD_DIR}/${srcPkg}" .
	${unZipper} "${srcPkg}" >/dev/null
	tar --extract --file="${tarBall}"
	rm --force "${tarBall}"
else
	echo ";#"                                       # Make a log file entry.
	echo ";# ERROR ***** ${srcPkg} not recognized." # Make a log file entry.
	echo ";#"                                       # Make a log file entry.
	echo -e "E> ${TEXT_BRED}ERROR${TEXT_NORM}"      >&${CONSOLE_FD}
	echo    "=> Source package ${srcPkg} not found" >&${CONSOLE_FD}
	exit 1 # Bust out of sub-shell.
fi

}

# *****************************************************************************
# Build a boot loader from source.
# *****************************************************************************

loader_build() {

# Function Arguments:
#      $1 ... Package name, like "glibc-2.19".

unset pkg_patch
unset pkg_configure
unset pkg_make
unset pkg_install
unset pkg_clean
source "${BBLINUX_LOADER_DIR}/$1/bld.sh"

# Get the source package, if any.  The package_get function will unzip and
# untar the soucre package.
#
package_get ${PKG_ZIP}

# Patch, configure, build, install and clean.
#
PKG_STATUS=""
[[ -z "${PKG_STATUS}" ]] && pkg_patch     $1
[[ -z "${PKG_STATUS}" ]] && pkg_configure $1
[[ -z "${PKG_STATUS}" ]] && pkg_make      $1
[[ -z "${PKG_STATUS}" ]] && pkg_install   $1
[[ -z "${PKG_STATUS}" ]] && pkg_clean     $1
unset NJOBS
if [[ -n "${PKG_STATUS}" ]]; then
	echo ";#"                           # Make a log file entry.
	echo ";# ERROR ***** ${PKG_STATUS}" # Make a log file entry.
	echo ";#"                           # Make a log file entry.
	echo -e "E> ${TEXT_BRED}ERROR${TEXT_NORM}" >&${CONSOLE_FD}
	echo    "=> ${PKG_STATUS}"                 >&${CONSOLE_FD}
	rm --force INSTALL_STAMP
	rm --force FILES
	exit 1 # Bust out of sub-shell.
fi
unset PKG_STATUS

# Remove the un-tarred loader source package directory.
#
[[ -d "${PKG_DIR}" ]] && rm --force --recursive "${PKG_DIR}" || true

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

#bbl_root_check  || exit 1
bbl_dist_config || exit 1

# *****************************************************************************
# Build the boot loader. 
# *****************************************************************************

echo ""
echo "##### START building boot loader"
echo ""

pushd "${BBLINUX_BUILD_DIR}/bld" >/dev/null 2>&1

t1=${SECONDS}

pname="${BBLINUX_BOOTLOADER}"

echo -n "${pname} ";
for ((i=(30-${#pname}) ; i > 0 ; i--)); do echo -n "."; done

exec 4>&1    # Save stdout at fd 4.
CONSOLE_FD=4 #

set +e ; # Let a build step fail without exiting this script.
(
rm --force "${BBLINUX_BUILD_DIR}/log/l.${pname}.log"
loader_build "${pname}" >>"${BBLINUX_BUILD_DIR}/log/l.${pname}.log" 2>&1
)
if [[ $? -ne 0 ]]; then
	echo -e "${TEXT_RED}ERROR${TEXT_NORM}"
	echo "Check the build log files.  Probably check:"
	echo "=> ${BBLINUX_BUILD_DIR}/log/l.${pname}.log"
	exit 1
fi
set -e ; # All done with build steps; fail enabled.

exec >&4     # Set fd 1 back to stdout.
CONSOLE_FD=1 #

echo -n "... DONE ["
t2=${SECONDS}
mins=$(((${t2}-${t1})/60))
secs=$(((${t2}-${t1})%60))
[[ ${#mins} -eq 1 ]] && echo -n " "; echo -n "${mins} minutes "
[[ ${#secs} -eq 1 ]] && echo -n " "; echo -n "${secs} seconds"
echo "]"

unset pname

popd >/dev/null 2>&1

echo ""
echo "##### DONE building boot loader"

# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0

# end of file
