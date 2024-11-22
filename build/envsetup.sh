#!/bin/bash

function env_prepare()
{
	# check top of SDK
	if [ ! -f "$(pwd)/build/.tinatopdir" ]; then
		echo "ERROR: Please source envsetup.sh in the root of SDK"
		return -1
	else
		# check TINA_TOPDIR
		# It already exists, return 0
		#env | grep TINA_TOPDIR 1>/dev/null 2>&1
		#if [ 0 -eq $? -a x"${TINA_TOPDIR}" = x"$(pwd)" ] ; then
		#	return 0;
		#fi
		# It isnot exists
		echo "NOTE: The SDK($(pwd)) was successfully loaded"
		export TINA_TOPDIR="$(pwd)"
	fi

	# check openwrt
	if [ -d "$(pwd)/openwrt" ] ; then
		echo -n "load openwrt... "
		[ -e "$(pwd)/openwrt/build/envsetup.sh" ] && source $(pwd)/openwrt/build/envsetup.sh
		echo "ok"
		echo "Please run lunch next for openwrt."
	fi

	# check others
	if [ -x "$(pwd)/build.sh" ] ; then
		linux_dev="bsp"
		[ -d "$(pwd)/test/dragonboard" ] && linux_dev="dragonboard,${linux_dev}"
		[ -d "$(pwd)/test/SATA" ] && linux_dev="sata,${linux_dev}"
		[ -d "$(pwd)/buildroot" ] && linux_dev="buildroot,${linux_dev}"

		echo -n "load ${linux_dev}..."
		[ -e "$(pwd)/build/build_common.sh" ] && source "$(pwd)/build/build_common.sh"
		[ -e "$(pwd)/build/build_${linux_dev}.sh" ] && source "$(pwd)/build/build_${linux_dev}.sh"
		echo "ok"
	fi

	### MAIN ###
	[ -e "$(pwd)/build/buildbase.sh" ] && source "$(pwd)/build/buildbase.sh"
	[ -e "$(pwd)/build/quick.sh" ] && source $(pwd)/build/quick.sh

	# use hooks
	[ -e "$(pwd)/build/.hooks/envsetup.hook" ] && source $(pwd)/build/.hooks/envsetup.hook

	# print build_help
	if [ -d "$(pwd)/buildroot" ] ; then
		[ -e "$(pwd)/build/quick.sh" ] && source $(pwd)/build/quick.sh build_help
	fi
}

### MAIN ###

env_prepare
