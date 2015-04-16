#!/bin/bash -eu

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
# Check the arguments.
# *****************************************************************************

[[ $# != 1 ]] && {
echo "This script takes one argument, the bblinux CD-ROM staging directory."
echo "Usage: qemu.sh <directory>"
exit 1
}

[[ ! -d $1 ]] && {
echo "\"$1\" is not a directory."
echo "Usage: qemu.sh <directory>"
exit 1
}

# *****************************************************************************
# Look for the qemu executable in the path.
# *****************************************************************************

_path=""
for p in ${PATH//:/ }; do
	if [[ -x $p/qemu-system-i386 ]]; then _path=$p/qemu-system-i386; fi
done
if [[ x"${_path}" = x ]]; then
	echo ""
	echo "Cannot find an executable \"qemu\" program in your \$PATH"
	echo "setting.  Maybe you need to set your \$PATH or download and"
	echo "install qemu.  Qemu can be found at http://wiki.qemu.org/"
	echo ""
	exit 1
fi
unset _path

# *****************************************************************************
# Silly startup prompt.
# *****************************************************************************

echo -e "\e[1;31m"
cat - <<EOF
  _     _     _ _                  
 | |   | |   | (_)                 
 | |__ | |__ | |_ _ __  _   ___  __
 | '_ \| '_ \| | | '_ \| | | \ \/ /
 | |_) | |_) | | | | | | |_| |>  < 
 |_.__/|_.__/|_|_|_| |_|\__,_/_/\_\\
EOF
echo -e "\e[0;39m"
echo ""
read -p "bblinux: "

# *****************************************************************************
# Run qemu with the kernel and file system.
# *****************************************************************************

# To use serial terminal on the host use nc: nc -u -l 6174
#      maybe "stty -echo" after logged in
#
# To see the boot messages with the host nc, append to the kernel parameters:
#      console=ttyS0,9600n8

_serial=""
_initrd=boot/initramfs.gz
_kernel=boot/vmlinuz
_rdsksz="ramdisk_size=10240"
_rdsksz=""

for p in ${REPLY}; do
	if [[ x"${p:0:8}" = x"console=" ]]; then
		_serial="-serial udp::6174"
		echo ""
		echo "To use serial terminal on the host use nc: nc -u -l 6174"
		echo "Maybe "stty -echo" after logged in."
		echo ""
	fi
done

_cmdline="initrd=/${_initrd} root=/dev/ram0 ${_rdsksz} rw ${REPLY}"
echo "cmdline=\"${_cmdline}\""
qemu-system-i386                \
	-m 32                   \
	-net nic,model=rtl8139  \
	${_serial}              \
	-kernel $1/${_kernel}   \
	-initrd $1/${_initrd}   \
	-append "${_cmdline}"

unset _serial
unset _initrd
unset _kernel
unset _rdsksz
unset _cmdline


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0

# end of file
