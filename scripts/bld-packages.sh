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
	echo "ERROR ***** ${srcPkg} not recognized." # Make a log file entry.
	echo -e "${TEXT_BRED}ERROR${TEXT_NORM}"         >&${CONSOLE_FD}
	echo    "E> Source package ${srcPkg} not found" >&${CONSOLE_FD}
	exit 1 # Bust out of sub-shell.
fi

}

# <--------------------------------------------------------- 132 columns ---------------------------------------------------------->
# *********************************************************************************************************************************
# Make a file to list the bblinux package contents.
# *********************************************************************************************************************************

# Function Arguments:
#      $1 ... ASCII file that is the file list

package_list_make() {

# The file list is an ASCII file that is the list of files from which to make the binary package; it can have some scripting that
# interprets variables to control the list of files, so the file list needs some special processing to interpret the scripting.
# The file list is filtered in this function, honoring any embedded scripting, and the actual list of binary package files is
# created as ${BBLINUX_BUILD_DIR}/var/files

local cfgPkgFiles="$1" # This is a rooted full pathname of the files-list file.
local pathname=""      # This is local variable for miscellaneous use.

local -i lineNum=0
local -i nestings=0
local -i uselines=1   # 1 indicates that lines from the files-list file are being used.  0 indicates lines are being skipped.
local -i oldUseLine=1 # This makes a stack of one deep for the "uselines" flag.
local -i retStat=0

echo "***** Making Package File List" # Make a log file entry.

rm --force "${BBLINUX_BUILD_DIR}/var/files" # This is the file that will have the explicit list of files names that is generated
>"${BBLINUX_BUILD_DIR}/var/files"           # by processing the source files-list file.

while read; do
	lineNum=$((${lineNum}+1))
	[[ -z "${REPLY}"       ]] && continue || true # ......................................................... Skip blank lines.
	[[ "${REPLY}" =~ ^\ *$ ]] && continue || true # .................................................... Skip whitespace lines.
	[[ "${REPLY}" =~ ^\ *# ]] && continue || true # ....................................................... Skip comment lines.
	if [[ "${REPLY}" =~ ^if\  ]]; then
		# ....................................................................................... Interpret the 'if' lines.
		if [[ ${nestings} == 1 ]]; then
			echo "E> Cannot nest scripting in files-list file."
			echo "=> line ${lineNum}: \"${REPLY}\""
			continue
		fi
		set ${REPLY}
		if [[ $# != 4 ]]; then
			echo "E> IGNORING malformed if-condition in files-list file."
			echo "=> line ${lineNum}: \"${REPLY}\""
			continue
		fi
		oldUseLine=${uselines}
		eval [[ "\$$2" $3 "$4" ]] && uselines=1 || uselines=0  # interpret the if-condtion
		nestings=1
		echo "if \$$2 $3 $4 # -- nestings=${nestings} uselines=${uselines}"
		continue
	fi
	if [[ "${REPLY}" =~ ^fi ]]; then
		# ....................................................................................... Interpret the 'fi' lines.
		uselines=${oldUseLine}
		nestings=0
		echo "fi # ------------- nestings=${nestings} uselines=${uselines}"
		continue
	fi
	if [[ ${uselines} == 1 ]]; then
		# ....................................................................................... Interpret the used lines.
		if [[ "${REPLY}" =~ ^\'glob\'\  ]]; then
			# ................................................................................... Interpret file globs.
			set ${REPLY}
			echo "Start 'glob' \"$2\""
			_p=""
			for pathname in ${BBLINUX_SYSROOT_DIR}/$2; do
				if [[ -f ${pathname} ]]; then
					_p=${pathname#${BBLINUX_SYSROOT_DIR}/}
					echo ${_p} >>"${BBLINUX_BUILD_DIR}/var/files"
				fi
			done
			unset _p
			echo "End 'glob' \"$2\""
		elif [[ "${REPLY}" =~ ^\'hardlink\'\  ]]; then
			# ........................................................................... Interpret 'hardlinked' files.
			set ${REPLY}
			echo "Start 'hardli' \"$2\" \"$3\""
			for pathname in ${BBLINUX_SYSROOT_DIR}/$2; do
				if [[ ${pathname} -ef ${BBLINUX_SYSROOT_DIR}/$3 ]]; then
					_p=${pathname#${BBLINUX_SYSROOT_DIR}/}
					echo ${_p} >>"${BBLINUX_BUILD_DIR}/var/files"
				fi
			done
			unset _p
			echo "End 'hardli' \"$2\" \"$3\""
		elif [[ "${REPLY}" =~ ^\'symlink\'\  ]]; then
			# ............................................................................ Interpret 'symlinked' files.
			set ${REPLY}
			echo "Start 'synlink' \"$2\" \"$3\""
			for pathname in ${BBLINUX_SYSROOT_DIR}/$2; do
				if [[ -h ${pathname} && "$(readlink ${pathname})" == "$3" ]]; then
					_p=${pathname#${BBLINUX_SYSROOT_DIR}/}
					echo ${_p} >>"${BBLINUX_BUILD_DIR}/var/files"
				fi
			done
			unset _p
			echo "End 'synlink' \"$2\" \"$3\""
		else
			# ................................................................................... Interpret file names.
			eval "pathname=${REPLY}"
			echo ${pathname} >>"${BBLINUX_BUILD_DIR}/var/files"
		fi
	fi
done <"${cfgPkgFiles}"

while read; do
	if [[ ! -e ${BBLINUX_SYSROOT_DIR}/${REPLY} ]]; then
		echo "ERROR ***** sysroot is missing \"${REPLY}\""
		echo "=> from ${cfgPkgFiles}"
		retStat=1
	fi
done <"${BBLINUX_BUILD_DIR}/var/files"

if [[ ${retStat} -eq 1 ]]; then
	echo -e "${TEXT_BRED}ERROR${TEXT_NORM}"         >&${CONSOLE_FD}
	echo    "E> Something wrong in ${cfgPkgFiles}." >&${CONSOLE_FD}
fi

return ${retStat}

}
# <--------------------------------------------------------- 132 columns ---------------------------------------------------------->

# *****************************************************************************
# Build a package from source and make a binary package.
# *****************************************************************************

package_xbuild() {

# Function Arguments:
#      $1 ... Package name, like "glibc-2.19".

source "${BBLINUX_CONFIG_DIR}/$1/bld.sh"

# Get the source package, if any.  The package_get function will unzip and
# untar the soucre package.
#
[[ "x${PKG_ZIP}" == "x(none)" ]] || package_get ${PKG_ZIP}

# Get the bblinux-specific rootfs, if any.
#
if [[ -f "${BBLINUX_CONFIG_DIR}/$1/rootfs.tar.bz2" ]]; then
	cp "${BBLINUX_CONFIG_DIR}/$1/rootfs.tar.bz2" .
	bunzip2 --force "rootfs.tar.bz2"
	tar --extract --file="rootfs.tar"
	rm --force "rootfs.tar"
fi

# Prepare to create a list of the installed files.
#
rm --force INSTALL_STAMP
rm --force FILES
>INSTALL_STAMP
>FILES
sleep 1 # For detecting files newer than INSTALL_STAMP

# Patch, configure, build, install and clean.
#
PKG_STATUS=""
_bitch=${ncpus:-1}
[[ -z "${_bitch//[0-9]}" ]] && NJOBS=$((${_bitch:-1} + 1)) || NJOBS=2
unset _bitch
echo -n "b." >&${CONSOLE_FD}
[[ -z "${PKG_STATUS}" ]] && pkg_patch     $1
[[ -z "${PKG_STATUS}" ]] && pkg_configure $1
[[ -z "${PKG_STATUS}" ]] && pkg_make      $1
[[ -z "${PKG_STATUS}" ]] && pkg_install   $1
[[ -z "${PKG_STATUS}" ]] && pkg_clean     $1
unset NJOBS
if [[ -n "${PKG_STATUS}" ]]; then
	echo "ERROR ***** ${PKG_STATUS}" # Make a log file entry.
	echo -e "${TEXT_BRED}ERROR${TEXT_NORM}" >&${CONSOLE_FD}
	echo    "E> ${PKG_STATUS}"              >&${CONSOLE_FD}
	rm --force INSTALL_STAMP
	rm --force FILES
	exit 1 # Bust out of sub-shell.
fi
unset PKG_STATUS

# Only the latest revision of libtool understands sysroot, but even it has
# problems when cross-building: remove any .la files.
#
rm --force ${BBLINUX_SYSROOT_DIR}/lib/*.la
rm --force ${BBLINUX_SYSROOT_DIR}/usr/lib/*.la

# Remove the un-tarred source package directory and the un-tarred rootfs
# directory, if any.
#
[[ -d "${PKG_DIR}" ]] && rm --force --recursive "${PKG_DIR}" || true
[[ -d "rootfs"     ]] && rm --force --recursive "rootfs"     || true

# Make a list of the installed files.  Remove sysroot and its path component
# from the file names.
#
echo -n "f." >&${CONSOLE_FD}
find ${BBLINUX_SYSROOT_DIR} -newer INSTALL_STAMP | sort >> FILES
sed --in-place "FILES" --expression="\#^${BBLINUX_SYSROOT_DIR}\$#d"
sed --in-place "FILES" --expression="s|^${BBLINUX_SYSROOT_DIR}/||"
rm --force INSTALL_STAMP # All done with the INSTALL_STAMP file.

# Strip as possible.
#
_x_strip="${XTOOL_BIN_PATH}/${BBLINUX_XTOOL_NAME}-strip"
echo "***** stripping"
for f in $(<FILES); do
	[[ -d "${BBLINUX_SYSROOT_DIR}/${f}" ]] && continue || true
	if [[ "$(dirname ${f})" == "bin" ]]; then
		echo "stripping ${f}"
		"${_x_strip}" "${BBLINUX_SYSROOT_DIR}/${f}" || true
	fi
	if [[ "$(dirname ${f})" == "sbin" ]]; then
		echo "stripping ${f}"
		"${_x_strip}" "${BBLINUX_SYSROOT_DIR}/${f}" || true
	fi
	if [[ "$(dirname ${f})" == "usr/bin" ]]; then
		echo "stripping ${f}"
		"${_x_strip}" "${BBLINUX_SYSROOT_DIR}/${f}" || true
	fi
	if [[ "$(dirname ${f})" == "usr/sbin" ]]; then
		echo "stripping ${f}"
		"${_x_strip}" "${BBLINUX_SYSROOT_DIR}/${f}" || true
	fi
_bname="$(basename ${f})"
[[ $(expr "${_bname}" : ".*\\(.o\)$" ) == ".o" ]] && continue || true
[[ $(expr "${_bname}" : ".*\\(.a\)$" ) == ".a" ]] && continue || true
	if [[ "$(dirname ${f})" == "lib" ]]; then
		echo "stripping ${f}"
		"${_x_strip}" "${BBLINUX_SYSROOT_DIR}/${f}" || true
	fi
[[ "${_bname}" == "libgcc_s.so"   ]] && continue || true
[[ "${_bname}" == "libgcc_s.so.1" ]] && continue || true
	if [[ "$(dirname ${f})" == "usr/lib" ]]; then
		echo "stripping ${f}"
		"${_x_strip}" "${BBLINUX_SYSROOT_DIR}/${f}" || true
	fi
done
unset _bname
unset _x_strip

return 0

}

# *****************************************************************************
# Find the installed man pages, compress them, and adjust the file name db.
# *****************************************************************************

manpage_compress() {

echo -n "m" >&${CONSOLE_FD}
for f in $(<FILES); do
	[[ -d "${BBLINUX_SYSROOT_DIR}/${f}" ]] && continue || true
	if [[ -n "$(grep "^usr/share/man/man" <<<${f})" ]]; then
		i=$(($i + 1))
#
# The goal of this is to gzip any non-gziped man pages.  The problem is that
# some of those have more than one sym link to them; how to fixup all the
# symlinks?
#
#               lFile=""
#               mFile=$(basename ${f})
#               manDir=$(dirname ${f})
#               pushd "${BBLINUX_SYSROOT_DIR}/${manDir}" >/dev/null 2>&1
#               if [[ -L ${mFile} ]]; then
#                       lFile="${mFile}"
#                       mFile="$(readlink ${lFile})"
#               fi
#               if [[   x"${mFile%.gz}"  == x"${mFile}" && \
#                       x"${mFile%.bz2}" == x"${mFile}" ]]; then
#                       echo "zipping \"${mFile}\""
#                       gzip "${mFile}"
#                       if [[ -n "${lFile}" ]]; then
#                               rm --force "${lFile}"
#                               ln --force --symbolic "${mFile}.gz" "${lFile}"
#                       fi
#                       sed --in-place "${BBLINUX_BUILD_DIR}/packages/FILES" \
#                               --expression="s|${mFile}$|${mFile}.gz|"
#               fi
#               popd >/dev/null 2>&1
	fi
done
[[ ${#i} -eq 1 ]] && echo -n "___${i}." >&${CONSOLE_FD}
[[ ${#i} -eq 2 ]] && echo -n  "__${i}." >&${CONSOLE_FD}
[[ ${#i} -eq 3 ]] && echo -n   "_${i}." >&${CONSOLE_FD}
[[ ${#i} -eq 4 ]] && echo -n    "${i}." >&${CONSOLE_FD}

return 0

}

# *****************************************************************************
# Collect the installed files into an as-built packge.
# *****************************************************************************

package_collect() {

# Function Arguments:
#      $1 ... Package name, like "glibc-2.19".

# Make the binary package: make a tarball of the files that is specified in the
# package configuration; this is found in "${BBLINUX_CONFIG_DIR}/$1/files".

# Save the list of files actually installed into sysroot/
#
cp --force FILES "${BBLINUX_SYSROOT_DIR}/usr/share/bblinux/pkg-$1-FILES"
rm --force FILES # All done with the FILES file.

# Look for a package configuration file list.
#
fileList="${BBLINUX_CONFIG_DIR}/$1/files"
if [[ -f "${fileList}-${BBLINUX_BOARD}" ]]; then
        fileList="${fileList}-${BBLINUX_BOARD}"
fi

# Remark on the current activity.  Probably do something interesting.
#
echo -n "p." >&${CONSOLE_FD}
#
# This is tricky.  First make a list of actual file names in
# "${BBLINUX_BUILD_DIR}/var/files" from the contents in the "${fileList}" file
# which has some macro-data in it, then make a binary package from the actual
# file list in "${BBLINUX_BUILD_DIR}/var/files".
#
package_list_make "${fileList}" || exit 1 # Bust out of sub-shell.
uTarBall="${BBLINUX_TARGET_DIR}/pkgbin/$1-${BBLINUX_CPU}.tar"
cTarBall="${BBLINUX_TARGET_DIR}/pkgbin/$1-${BBLINUX_CPU}.tbz"
tar --create \
	--directory="${BBLINUX_SYSROOT_DIR}" \
	--file="${uTarBall}" \
	--files-from="${BBLINUX_BUILD_DIR}/var/files" \
	--no-recursion
bzip2 --force "${uTarBall}"
mv --force "${uTarBall}.bz2" "${cTarBall}"
unset uTarBall
unset cTarBall
rm --force "${BBLINUX_BUILD_DIR}/var/files" # Remove the temporary file.

echo -n "c" >&${CONSOLE_FD}

return 0

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

bbl_root_check  || exit 1
bbl_dist_config || exit 1

ZP="" # This is a mechanism to skip already-built packages.
if [[ $# -gt 0 ]]; then
	# "$1" may be unbound so hide it in this if statement.
	# Set the ZP flag, if so specified; otherwise reset the package list.
	[[ "$1" == "continue" ]] && ZP="y" || BBLINUX_PACKAGE=("$1")
fi

# *****************************************************************************
# Build each package.
# *****************************************************************************

echo ""
echo "##### START cross-building packages"
echo "g - getting the source and configuration packages"
echo "b - building and installing the package into sysroot"
echo "f - finding installed files"
echo "m - looking for man pages to compress"
echo "p - creating bblinux-installable package"
echo "c - cleaning"
echo ""

pushd "${BBLINUX_BUILD_DIR}/bld" >/dev/null 2>&1

if [[ $(ls -1 | wc -l) -ne 0 ]]; then
	echo "w> build/bld build directory is not empty:"
	ls -l
	echo ""
fi

T1P=${SECONDS}

for _p in ${BBLINUX_PACKAGE[@]}; do

	[[ -n "${ZP}" && -f "${BBLINUX_BUILD_DIR}/run/done.${p}" ]] && continue

	t1=${SECONDS}

	echo -n "${_p} ";
	for ((i=(30-${#_p}) ; i > 0 ; i--)); do echo -n "."; done
	echo -n " ";

	exec 4>&1    # Save stdout at fd 4.
	CONSOLE_FD=4 #

	set +e ; # Let a build step fail without exiting this script.
	(
	rm --force "${BBLINUX_BUILD_DIR}/log/p.${_p}.log"
	package_xbuild  "${_p}" >>"${BBLINUX_BUILD_DIR}/log/p.${_p}.log" 2>&1
	manpage_compress        >>"${BBLINUX_BUILD_DIR}/log/p.${_p}.log" 2>&1
	package_collect "${_p}" >>"${BBLINUX_BUILD_DIR}/log/p.${_p}.log" 2>&1
	)
	if [[ $? -ne 0 ]]; then
		echo "Check the build log files.  Probably check:"
		echo "=> ${BBLINUX_BUILD_DIR}/log/p.${_p}.log"
		exit 1
	fi
	set -e ; # All done with build steps; fail enabled.

	exec >&4     # Set fd 1 back to stdout.
	CONSOLE_FD=1 #

	touch "${BBLINUX_BUILD_DIR}/run/done.${_p}"

	echo -n " ... DONE ["
	t2=${SECONDS}
	mins=$(((${t2}-${t1})/60))
	secs=$(((${t2}-${t1})%60))
	[[ ${#mins} -eq 1 ]] && echo -n " "; echo -n "${mins} minutes "
	[[ ${#secs} -eq 1 ]] && echo -n " "; echo -n "${secs} seconds"
	echo "]"

	if [[ $(ls -1 | wc -l) -ne 0 ]]; then
		echo "w> build/bld build directory is not empty:"
		ls -l
	fi

done
unset _p

T2P=${SECONDS}
echo "=> $(((${T2P}-${T1P})/60)) minutes $(((${T2P}-${T1P})%60)) seconds"
echo ""

popd >/dev/null 2>&1

echo "##### DONE cross-building packages"

# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0

# end of file
