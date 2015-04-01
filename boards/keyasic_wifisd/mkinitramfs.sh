#!/bin/bash

# $1 ... "IN" or "OUT": making or unmaking the board specific format.
#
# $2 ... This is the input root file system image file. It IS gzipped
#        compressed and this file name ends with ".gz".
#
# $3 ... This is the name of file system that this script must make. It must be
#        a gzipped compressed file. This name does end  with ".gz".

# *****************************************************************************
# make
# *****************************************************************************

if [[ x"$1" == x"IN" ]]; then

	# This part of this script should be run after making a standard cpio
	# root file system image file, named something like "initramfs.gz".
	#
	# This script makes a keyasic wifisd compatible cpio root file system
	# image file.
	#
	# Pre-pend 0x4b41475aXXXXXXXX to the initramfs file, where 0x4b41475a
	# is a magic number and XXXXXXXX is the size of the gzipped root file
	# system image file in bytes.
	#
	# TODO This might not be needed if the kernel is built differently from
	#      the supplied keyasic wifisd kernel.
	#
	# FIXME The following printf probably doesn't work on big endian.

	echo "keyasic_wifisd/mkinitramfs.sh making ..."

	printf "0: 4b41475a%.8x" $(wc -c < "${2}") |
		xxd -r -g0 |
		cat - "${2}" > "${3}"

	echo "keyasic_wifisd/mkinitramfs.sh DONE"

fi

# *****************************************************************************
# unmake
# *****************************************************************************

if [[ x"$1" == x"OUT" ]]; then
	echo "keyasic_wifisd/mkinitramfs.sh un-making ..."
	tail -c +9 "${2}" > "${3}"
	echo "keyasic_wifisd/mkinitramfs.sh DONE"
fi

# end of file
