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
# Look for the kernel source tar file.
# *****************************************************************************

kernel_source_find() {

local kname=""
local tag=""

if   [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tgz$      ]]; then tag=".tgz";
elif [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tar\.gz$  ]]; then tag=".tar.gz";
elif [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tbz$      ]]; then tag=".tbz";
elif [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tar\.bz2$ ]]; then tag=".tar.bz2";
elif [[ "${BBLINUX_LINUX_TAR}" =~ (.*)\.tar\.xz$  ]]; then tag=".tar.xz";
else return 0
fi

kname=${BASH_REMATCH[1]}

if   [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tar.xz"  ]]; then tag=".tar.xz";
elif [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tar.bz2" ]]; then tag=".tar.bz2";
elif [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tbz"     ]]; then tag=".tbz";
elif [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tar.gz"  ]]; then tag=".tar.gz";
elif [[ -f "${BBLINUX_DLOAD_DIR}/${kname}.tgz"     ]]; then tag=".tgz";
else return 0
fi

if [[ x"${BBLINUX_LINUX_TAR}" != x"${kname}${tag}" ]]; then
	echo "i> Switching kernel package name to avoid download."
	echo "=> Found appropriate package in download directory:"
	echo "-> was ......... \"${BBLINUX_LINUX_TAR}\""
	echo "-> now using ... \"${kname}${tag}\""
fi

export BBLINUX_LINUX_TAR="${kname}${tag}"

}

# *****************************************************************************
# Get the kernel source tree and configuration file.
# *****************************************************************************

kernel_get() {

local fname="${BBLINUX_LINUX_TAR}"
local pname="${BBLINUX_LINUX_DIR}"
local kver="${BBLINUX_LINUX_DIR##*-}"
local kcfg="${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}/${pname}.config"

echo -n "g." >&${CONSOLE_FD}

if [[ x"${BB_USE_OLD_BUILD_DIRS:-}" == x"y" ]]; then
	if [[ -d ${BBLINUX_LINUX_DIR} ]]; then
		echo ";#"
		echo ";# kernel_get(): using previous build directory."
		echo ";# Found \"${BBLINUX_LINUX_DIR}\"."
		echo ";# Assuming it is patched."
		echo ";# Copying new config file."
		echo ";# => ${kcfg}"
		echo ";#"
		K_PATCHED="yes"
		cp ${kcfg} ${BBLINUX_LINUX_DIR}/.config
		return 0
	fi
fi

# Make log file entry.
#
echo ";#"
echo ";# kernel source"
echo ";# => ${BBLINUX_DLOAD_DIR}/${fname}"
echo ";#"

# Look for the linux kernel tarball.
#
if [[ ! -f "${BBLINUX_DLOAD_DIR}/${fname}" ]]; then
	echo "E> Linux kernel source tarball not found." >&${CONSOLE_FD}
	echo "=> ${BBLINUX_DLOAD_DIR}/${fname}" >&${CONSOLE_FD}
	exit 1
fi

# Make log file entry.
#
echo ";#"
echo ";# kernel config"
echo ";# => ${kcfg}"
echo ";#"

# Look for the linux kernel configuration file.
#
if [[ ! -f "${kcfg}" ]]; then
	echo "E> Linux kernel configuration file not found." >&${CONSOLE_FD}
	echo "=> ${kcfg}" >&${CONSOLE_FD}
	exit 1
fi

# Cleanup any previous left-over build results.
#
rm --force --recursive "${BBLINUX_LINUX_DIR}"*/
rm --force --recursive linux/

# Untar the kernel and get the configuration file.
#
tar --extract --file="${BBLINUX_DLOAD_DIR}/${fname}"
cp ${kcfg} ${BBLINUX_LINUX_DIR}/.config

}

# *****************************************************************************
# Add any add-ins and patches.
# *****************************************************************************

kernel_patch() {

local pname="${BBLINUX_LINUX_DIR}"
local addin="${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}/${pname}-add_in.tar.bz2"

echo -n "p." >&${CONSOLE_FD}

if [[ x"${K_PATCHED}" == x"yes" ]]; then
	echo ";#"
	echo ";# Patching not needed."
	echo ";#"
	return 0
fi

cd ${BBLINUX_LINUX_DIR}

# This is for older kernels built with newer GCC; it is harmless it this fails.
#
sed -e "s|-Werror-implicit-function-declaration||" -i Makefile || true

# This is for older kernels; it is harmless otherwise.
#
if [[ -f scripts/unifdef.c ]]; then
	sed -e "s/getline/uc_&/" -i scripts/unifdef.c || true
fi

# This is for older kernels; it is harmless otherwise.
#
if [[ -f scripts/mod/sumversion.c ]]; then
	_old="<string.h>"
	_new="<limits.h>\n#include <string.h>"
	sed -e "s|${_old}|${_new}|" -i scripts/mod/sumversion.c || true
	unset _old
	unset _new
fi

# Add-in
#
if [[ -f ${addin} ]]; then
	# Make log file entry.
	echo ";#"
	echo ";# Adding ${addin##*/}"
	echo ";#"
	tar --extract --file=${addin}
fi

# Patches
#
for _p in ${BBLINUX_BOARDS_DIR}/${BBLINUX_BOARD}/${pname}-??.patch; do
	if [[ -f "${_p}" ]]; then
		# Make log file entry.
		echo ";#"
		echo ";# Patching ${_p##*/}"
		echo ";#"
		patch -p1 <${_p}
	fi
done; unset _p

cd ..

K_PATCHED="yes"

}

# *****************************************************************************
# Build the kernel from source and make a binary package.
# *****************************************************************************

kernel_xbuild() {

local bitch=""
local target=""

echo -n "b." >&${CONSOLE_FD}

if [[ x"${BB_USE_OLD_BUILD_DIRS:-}" == x"y" ]]; then
	echo ";#"
	echo ";# kernel_xbuild(): using previous build directory."
	echo ";# Found \"${BBLINUX_LINUX_DIR}\"."
	echo ";#"
fi

# Agressively set njobs: set njobs to 2 if ${ncpus} is unset or has non-digit
# characters.
#
bitch=${ncpus:-1}
[[ -z "${bitch//[0-9]}" ]] && njobs=$((${bitch:-1} + 1)) || njobs=2

# Set the right kernel make target.
case "${BBLINUX_BOARD}" in
	keyasic_wifisd) target="zImage"  ;;
	pc_i486)	target="bzImage" ;;
	wrtu54g_tm)     target="vmlinux" ;;
esac

cd ${BBLINUX_LINUX_DIR}

_modules=$(set +u; source ".config"; echo "${CONFIG_MODULES}")
[[ x"${_modules}" == x"y" ]] && K_MODULES="yes"
unset _modules
if [[ "${K_MODULES}" == "yes" ]]; then
	# Make log file entry.
	echo ";#"
	echo ";# This kernel configuration has modules."
	echo ";#"
else
	# Make log file entry.
	echo ";#"
	echo ";# This kernel configuration has NO modules."
	echo ";#"
fi

# Do the kernel cross-building.  If this kernel has modules then build them.
# Leave the kernel, system map and any kernel modules in place; get them
# later.
#
_xtraPath=""
if [[ "${target}" == "uImage" ]]; then
	# Add the uboot build directory that has the mkimage program, and add
	# the device tree to the build target.
	#_xtraPath="${BBLINUX_BOOTLOADER_DIR}/uboot"
	target="uImage dtbs"
fi
source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_set"
echo ";#"
echo ";# Making Kernel \"${target}\""
echo ";#"
njobs=1
PATH="${_xtraPath}:${XTOOL_BIN_PATH}:${PATH}" make -j ${njobs} ${target} \
	V=1 \
	ARCH=${BBLINUX_LINUX_ARCH} \
	CROSS_COMPILE=${BBLINUX_XTOOL_NAME}-
if [[ "${K_MODULES}" == "yes" ]]; then
	# Make log file entry.
	echo ";#"
	echo ";# Making Kernel Modules"
	echo ";#"
	PATH="${XTOOL_BIN_PATH}:${PATH}" make -j ${njobs} modules \
		V=1 \
		ARCH=${BBLINUX_LINUX_ARCH} \
		CROSS_COMPILE=${BBLINUX_XTOOL_NAME}-
fi
source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_clr"
unset _xtraPath

cd ..

}

# *****************************************************************************
# Collect the built kernel into an as-built packge.
# *****************************************************************************

kernel_collect() {

local kver="${BBLINUX_LINUX_DIR##*-}"
local _vmlinuz=""
local _dtb=""

echo -n "f.p." >&${CONSOLE_FD}

# Setup kernel directories. Ignore messages and don't let the statement fail.
#
mkdir ${BBLINUX_TARGET_DIR}/kroot/boot        >/dev/null 2>&1 || true
mkdir ${BBLINUX_TARGET_DIR}/kroot/etc         >/dev/null 2>&1 || true
mkdir ${BBLINUX_TARGET_DIR}/kroot/lib         >/dev/null 2>&1 || true
mkdir ${BBLINUX_TARGET_DIR}/kroot/lib/modules >/dev/null 2>&1 || true

# $ make vmlinux
# $ mipsel-linux-strip vmlinux
# $ echo "root=/dev/ram0 ramdisk_size=8192" >kernel.params
# $ mipsel-linux-objcopy --add-section kernparm=kernel.params vmlinux
# $ mipsel-linux-objcopy --add-section initrd=initrd.gz vmlinux

# Find the kernel file and dtb file if needed.
#
_vmlinux="arch/${BBLINUX_LINUX_ARCH}/boot/"
_dtbfile="(none)"
case "${BBLINUX_BOARD}" in
	keyasic_wifisd)	_dtbfile=""; _vmlinux+="Image"   ;;
	pc_i486)	_dtbfile=""; _vmlinux+="bzImage" ;;
	wrtu54g_tm)	_dtbfile=""; _vmlinux="vmlinux"  ;;
esac

# Get the kernel, the system map, and the dtb file if needed.
#
bDir="${BBLINUX_TARGET_DIR}/kroot/boot"
cp "${BBLINUX_LINUX_DIR}/System.map"  "${bDir}/System.map"
cp "${BBLINUX_LINUX_DIR}/vmlinux"     "${bDir}/vmlinux"
cp "${BBLINUX_LINUX_DIR}/${_vmlinux}" "${bDir}/$(basename ${_vmlinux})"
if [[ -n "${_dtbfile}" ]]; then
	cp "${BBLINUX_LINUX_DIR}/${_dtbfile}" "${bDir}/$(basename ${_dtbfile})"
fi
unset bDir

if [[ "${K_MODULES}" == "yes" ]]; then

	bDir="${BBLINUX_TARGET_DIR}/kroot"
	pDir="${BBLINUX_TARGET_DIR}/kpkgs"

	# Install the kernel modules into ${BBLINUX_TARGET_DIR}/kroot
	#
	echo ";#"
	echo ";# Install the kernel modules into:"
	echo ";# => ${BBLINUX_TARGET_DIR}/kroot"
	echo ";#"
	cd "${BBLINUX_LINUX_DIR}"
	source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_set"
	PATH="${XTOOL_BIN_PATH}:${PATH}" make -j ${njobs} modules_install\
		V=1 \
		ARCH=${BBLINUX_LINUX_ARCH} \
		CROSS_COMPILE=${BBLINUX_XTOOL_NAME}- \
		INSTALL_MOD_PATH=${bDir}
	source "${BBLINUX_SCRIPTS_DIR}/_xbt_env_clr"
	cd ..

	# Scrub the modules directory.
	#
	echo ";#"
	echo ";# Scrub the modules directory; remove these:"
	echo ";# => ${bDir}/lib/modules/${kver}/build"
	echo ";# => ${bDir}/lib/modules/${kver}/source"
	echo ";#"
	rm --force "${bDir}/lib/modules/${kver}/build"
	rm --force "${bDir}/lib/modules/${kver}/source"

	# Make the kernel modules binary package in ${TTYLINUX_BUILD_DIR}/kpkgs
	#
	uTarBall="${pDir}/kmodules-${kver}-${BBLINUX_CPU_ARCH}.tar"
	cTarBall="${pDir}/kmodules-${kver}-${BBLINUX_CPU_ARCH}.tbz"
	tar --directory ${bDir} --create --file="${uTarBall}" lib
	bzip2 --force "${uTarBall}"
	mv --force "${uTarBall}.bz2" "${cTarBall}"
	unset uTarBall
	unset cTarBall

	unset bDir
	unset pDir

fi

}

# *****************************************************************************
# Cleanup kernel build directory.
# *****************************************************************************

kernel_clean() {

echo -n "c" >&${CONSOLE_FD}

if [[ x"${BB_USE_OLD_BUILD_DIRS:-}" == x"y" ]]; then
	echo ";#"
	echo ";# kernel_clean(): using previous build directory."
	echo ";# Found \"${BBLINUX_LINUX_DIR}\"."
	echo ";# Not cleaning."
	echo ";#"
	return 0
fi

# Make log file entry.
echo ";#"
echo ";# Removing build directory ${BBLINUX_LINUX_DIR}"
echo ";#"

rm --force --recursive "${BBLINUX_LINUX_DIR}/"
rm --force --recursive "linux/"

}

# *************************************************************************** #
#                                                                             #
# M A I N   P R O G R A M                                                     #
#                                                                             #
# *************************************************************************** #

# *****************************************************************************
# Set up the shell functions and environment variables.
# *****************************************************************************

K_MODULES="no"
K_PATCHED="no"

source ./bblinux-config.sh     # bblinux target build configuration
source ./bblinux-setenv.sh     # bblinux environment configuration
source ./scripts/_functions.sh # bblinux build support

bbl_dist_config || exit 1

# *****************************************************************************
# Download the kernel if needed.
# *****************************************************************************

# There may be an appropriate linux source tarball in ${BBLINUX_DLOAD_DIR} that
# doesn't have the same file suffix as ${BBLINUX_LINUX_TAR} e.g., the name in
# ${BBLINUX_LINUX_TAR} may end in ".tar.bz2" and there may be a ".tar.xz" in
# ${BBLINUX_DLOAD_DIR}  The 'kernel_source_find' function looks for an
# appropriate kernel source tarball and changes the value of BBLINUX_LINUX_TAR
# as needed.
#
kernel_source_find

if [[ ! -f "${BBLINUX_DLOAD_DIR}/${BBLINUX_LINUX_TAR}" ]]; then
	echo "i> Getting Linux source code package."
	echo "=> Local cache directory: ${BBLINUX_CACHE_DIR}"
	bbl_get_urlnametag "${BBLINUX_LINUX_URL}/${BBLINUX_LINUX_TAR}"
fi

# *****************************************************************************
# Build the kernel and maybe some its modules.
# *****************************************************************************

echo ""
echo "##### START cross-building the kernel"
echo ""
echo "g - getting the source and configuration packages"
echo "p - applying add-ins and patches"
echo "b - building and installing the package into build directory"
echo "f - finding module files"
echo "p - creating module files package"
echo "c - cleaning"
echo ""

pushd "${BBLINUX_BUILD_DIR}/bld" >/dev/null 2>&1

pname="${BBLINUX_LINUX_DIR}"

t1=${SECONDS}
_title="${BBLINUX_CPU_ARCH} ${pname} "
echo -n "${_title}";
for ((i=(30-${#_title}) ; i > 0 ; i--)); do echo -n "."; done
echo -n " ";
unset _title

exec 4>&1    # Save stdout at fd 4.
CONSOLE_FD=4 #

set +e ; # Let a build step fail without exiting this script.
(
rm --force "${BBLINUX_BUILD_DIR}/log/k.${pname}.log"
kernel_get     >>"${BBLINUX_BUILD_DIR}/log/k.${pname}.log" 2>&1
kernel_patch   >>"${BBLINUX_BUILD_DIR}/log/k.${pname}.log" 2>&1
kernel_xbuild  >>"${BBLINUX_BUILD_DIR}/log/k.${pname}.log" 2>&1
kernel_collect >>"${BBLINUX_BUILD_DIR}/log/k.${pname}.log" 2>&1
kernel_clean   >>"${BBLINUX_BUILD_DIR}/log/k.${pname}.log" 2>&1
)
if [[ $? -ne 0 ]]; then
	echo -e "${TEXT_RED}ERROR${TEXT_NORM}"
	echo "Check the build log file."
	echo "=> ${BBLINUX_BUILD_DIR}/log/k.${pname}.log"
	exit 1
fi
set -e ; # All done with build steps; fail enabled.

exec >&4     # Set fd 1 back to stdout.
CONSOLE_FD=1 #

echo -n " ... DONE ["
t2=${SECONDS}
mins=$(((${t2}-${t1})/60))
secs=$(((${t2}-${t1})%60))
[[ ${#mins} -eq 1 ]] && echo -n " "; echo -n "${mins} minutes "
[[ ${#secs} -eq 1 ]] && echo -n " "; echo    "${secs} seconds]"

popd >/dev/null 2>&1

echo ""
echo "##### DONE cross-building the kernel"

# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0

# end of file
