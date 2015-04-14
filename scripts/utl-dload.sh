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
# dload_get_file
# *****************************************************************************

# Usage: dload_get_file <fname> <url> [url ...]
#
#      Example:
#      <fname> ... something like "lynx2-8-7.tgz"
#      for downloading lynx2-8-7.tgz from <url> [url ...]

dload_get_file() {

local pkgName=""
local pkgExt=""
local pName="$1" # could be like lynx-2.8.7
local fName="$2" # could be like lynx2-8-7.tgz

# Break the name into package name and file name extension.
#
_ext=""
if   [[ "${fName}" =~ (.*)\.tar\.gz$   ]]; then _ext=".tar.gz";
elif [[ "${fName}" =~ (.*)\.tar\.bz2$  ]]; then _ext=".tar.bz2";
elif [[ "${fName}" =~ (.*)\.tar\.xz$   ]]; then _ext=".tar.xz";
elif [[ "${fName}" =~ (.*)\.tar\.lzma$ ]]; then _ext=".tar.lzma";
elif [[ "${fName}" =~ (.*)\.tgz$       ]]; then _ext=".tgz";
elif [[ "${fName}" =~ (.*)\.tbz$       ]]; then _ext=".tbz";
elif [[ "${fName}" =~ .none.$          ]]; then _ext="(none)";
fi
pkgName="${BASH_REMATCH[1]:-${pName}}"
pkgExt="${_ext}"
unset _ext

# Go to the urls.
#
shift
shift

bbl_get_file "${pkgName}" "${pkgExt}" $@

}

# *************************************************************************** #
#                                                                             #
# M A I N   P R O G R A M                                                     #
#                                                                             #
# *************************************************************************** #

# *****************************************************************************
# Set up the shell functions and environment variables.
# *****************************************************************************

K_PKGLIST="$1"

source ./bblinux-config.sh     # bblinux target build configuration
source ./bblinux-setenv.sh     # bblinux environment configuration
source ./scripts/_functions.sh # bblinux build support

# *****************************************************************************
# Say something nice.
# *****************************************************************************

echo "i> Getting source code packages [be patient, this will not lock up]."
echo "=> Local cache directory: ${BBLINUX_CACHE_DIR}"

# *****************************************************************************
# Get the files.
# *****************************************************************************

_c=0     # Download count.
_p=${2-} # See if there is a single package to download.
while read pname pad1 fname pad2 url; do
	[[ -z "${pname}"                       ]] && continue || true
	[[ "${pname:0:1}" == "#"               ]] && continue || true
	[[ -n "${_p}" && "${pname}" != "${_p}" ]] && continue || true
	dload_get_file ${pname} ${fname} ${url}
	_c=$((${_c} + 1))
done <${K_PKGLIST}
echo "i> Fetched ${_c} packages."
if [[ ${_c} -eq 0 && -n "${_p}" ]]; then
	echo -e "E> ${TEXT_BRED}Error${TEXT_NORM}: no package named \"${_p}\""
fi
unset _c
unset _p

# *****************************************************************************
# Get the cross-tool chain tarball, if needed.
# *****************************************************************************

if [[ ${G_NMISSING} != 0 ]]; then
	echo ""
	echo "Oops -- missing ${G_NMISSING} packages."
	echo ""
	echo -e "E> ${TEXT_BRED}Error${TEXT_NORM}:"
	echo "At least one source package failed to download.  If all source   "
	echo "packages failed to download then check your Internet access.     "
	echo "Listed below are the missing source package name(s) and the last "
	echo "URL used to find the package.  Likely failure possibilities are: "
	echo "=> The URL is wrong, maybe it has changed.                       "
	echo "=> The source package name is no longer at the URL, maybe the    "
	echo "   version name has changed at the URL.                          "
	echo ""
	echo "You can use your web browser to look for the package, and maybe  "
	echo "use Google to look for an alternate site hosting the source      "
	echo "package; you can put them in one of these directories:           "
	echo "${BBLINUX_DLOAD_DIR}                                             "
	echo "${BBLINUX_CACHE_DIR}                                             "
	echo ""
	while [[ ${G_NMISSING} > 0 ]]; do
		G_NMISSING=$((${G_NMISSING} - 1))
		echo ${G_MISSED_PKG[${G_NMISSING}]}
		echo ${G_MISSED_URL[${G_NMISSING}]}
		if [[ ${G_NMISSING} != 0 ]]; then
			echo -e "${TEXT_BBLUE}-----${TEXT_NORM}"
		fi
	done
	echo ""
	unset G_NMISSING
	exit 1
fi

# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0

# end of file
