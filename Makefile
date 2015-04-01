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
# Make Variables and Make Environment                                         #
# *************************************************************************** #

# This top level cannot run parallel jobs.
#
.NOTPARALLEL:

# -- Single-Package Target
#
PACKAGE=""

# -- Sanity
#
SHELL=/bin/bash

# *****************************************************************************
# Make Targets
# *****************************************************************************

.PHONY: help
.PHONY: getcfg xtools pkglist dload mount umount
.PHONY: clean kclean lclean pclean pkgs pkgs_ fsys

# -----------------------------------------------------------------------------
# -- Default Target
# -----------------------------------------------------------------------------

help:
	@echo ""
	@echo "Housekeeping Targets:"
	@echo "getcfg  - get default config file from the config directory"
	@echo "xtools  - build the cross tool-chain for the selected config"
	@echo "pkglist - make list of source packages using default config"
	@echo "dload   - download source packages"
	@echo "mount   - mount the bblinux file system image, if found"
	@echo "umount  - unmount the bblinux file system image, if mounted"
	@echo ""
	@echo "Build Targets:"
	@echo "clean  - remove the bblinux build"
	@echo "kclean - remove the bblinux kernel build"
	@echo "lclean - remove the bblinux boot loader build"
	@echo "pclean - remove the bblinux packages build"
	@echo "pkgs   - build the bblinux packages"
	@echo "pkgs_  - continue more building of the bblinux packages"
	@echo "fsys   - create the root file system image"
	@echo "PACKAGE=name name - Use this to build a single package:"
	@echo "         the base file system and uClibc must be in sysroot"
	@echo ""

# -----------------------------------------------------------------------------
# -- Housekeeping Targets
# -----------------------------------------------------------------------------

getcfg:
	@(								\
	dlist=`cd boards; for d in *; do echo $${d#*-}; done`;		\
	for d in $${dlist}; do						\
		for f in boards/$${d}/$${d}-*config; do			\
			[[ -f $${f} ]] && llist+="$${f##*/} " || true;	\
		done;							\
	done;								\
	list=($${llist});						\
	declare -i i=0;							\
	declare -i cfg=0;						\
	declare -i cnt="$${#list[@]}";					\
	while [[ $${cfg} -eq 0 || $${cfg} -gt $${cnt} ]]; do		\
		echo "";						\
		echo "bblinux target configurations:";			\
		for (( i=1 ; $${i} <= $${cnt} ; i++ )); do		\
			echo "$${i}) $${list[(($${i}-1))]}";		\
		done;							\
		echo "";						\
		read -p "   Choose from 1 through $${cnt} -> " cfg;	\
	done;								\
	cfg="(($${cfg} - 1))";						\
	echo "";							\
	echo "=> using $${list[$${cfg}]}";				\
	rm --force bblinux-config.sh;					\
	rm --force bblinux-pkglst.txt;					\
	cp boards/*/$${list[$${cfg}]} bblinux-config.sh;		\
	)
	@chmod 666 bblinux-config.sh
	@ls --color -Fl bblinux-config.sh

bblinux-config.sh:
	@echo "Need a new bblinux-config.sh file."
	@echo "=> Run \"make getcf\"."
	@false

xtools:	bblinux-config.sh scripts/bld-xtools.sh
	@(scripts/bld-xtools.sh)

bblinux-pkglst.txt pkglist:	bblinux-config.sh
	@echo "Regenerating bblinux-pkglst.txt:"
	@(								\
	. ./bblinux-config.sh;						\
	rm --force bblinux-pkglst.txt;					\
	touch bblinux-pkglst.txt;					\
	for dir in $${BBLINUX_PACKAGE[@]}; do				\
		echo -n "$${dir} " >> bblinux-pkglst.txt;		\
		for ((i=35 ; $${i}>$${#dir} ; i--)); do			\
			echo -n "." >>bblinux-pkglst.txt;		\
		done;							\
		. config/$${dir}/bld.sh;				\
		echo -n " $${PKG_ZIP} " >>bblinux-pkglst.txt;		\
		for ((i=35 ; $${i}>$${#PKG_ZIP} ; i--)); do		\
			echo -n "." >>bblinux-pkglst.txt;		\
		done;							\
		echo -n " $${PKG_URL}" >>bblinux-pkglst.txt;		\
		echo "" >>bblinux-pkglst.txt;				\
	done;								\
	)
	@chmod 666 bblinux-pkglst.txt
	@ls --color -Fl bblinux-pkglst.txt

dload:	bblinux-pkglst.txt scripts/utl-dload.sh
	@(scripts/utl-dload.sh)

mount:	scripts/utl-mount.sh
	@(scripts/utl-mount.sh)

umount:	scripts/utl-umount.sh
	@(scripts/utl-umount.sh)

# -----------------------------------------------------------------------------
# -- Build Targets
# -----------------------------------------------------------------------------

clean:	scripts/bld-clean.sh
	@(scripts/bld-clean.sh all)

kclean:	scripts/bld-clean.sh
	@(scripts/bld-clean.sh kernel)

lclean:	scripts/bld-clean.sh
	@(scripts/bld-clean.sh loader)

pclean:	scripts/bld-clean.sh
	@(scripts/bld-clean.sh packages)

${PACKAGE}:	bblinux-pkglst.txt scripts/bld-packages.sh
	@(scripts/bld-packages.sh ${PACKAGE})

pkgs:	bblinux-pkglst.txt scripts/bld-packages.sh
	@(scripts/bld-packages.sh)

pkgs_:	bblinux-pkglst.txt scripts/bld-packages.sh
	@(scripts/bld-packages.sh continue)

fsys:	scripts/bld-fsys.sh
	@(scripts/bld-fsys.sh)

# end of file
