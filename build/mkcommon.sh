#!/bin/bash
#
# scripts/mkcommon.sh
# (c) Copyright 2013
# Allwinner Technology Co., Ltd. <www.allwinnertech.com>
# James Deng <csjamesdeng@allwinnertech.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

export LC_ALL=C
BUILD_SCRIPTS_DIR=$(cd $(dirname $0) && pwd)
BUILD_CONFIG=$BUILD_SCRIPTS_DIR/../.buildconfig
source ${BUILD_SCRIPTS_DIR}/mkcmd.sh

if [ -f ${BUILD_CONFIG} ]; then
	. ${BUILD_CONFIG}
	LICHEE_TOP_DIR_NEW=$(cd $BUILD_SCRIPTS_DIR/.. && pwd)
	if [ -n "$LICHEE_TOP_DIR" -a "$LICHEE_TOP_DIR_NEW" != "$LICHEE_TOP_DIR" ]; then
		sed -i "s|$LICHEE_TOP_DIR|$LICHEE_TOP_DIR_NEW|g" ${BUILD_CONFIG}
		. ${BUILD_CONFIG}
	fi
fi

# Invoke 'bsp.sh' directly
if echo "$1" | grep -w "bsp" >/dev/null; then
    opt=${@/bsp/}  # Remove 'bsp' from '$@'
    bsp_action $opt
    exit $?
fi

ACTION="build_linuxdev;"
################ Parse command arguments ###################
while [ $# -gt 0 ]; do
	case "$1" in
	# config for build environment
	config|autoconfig)
		ACTION="mk_${1} ${@:2};";
		clean_old_env_var
		break;
		;;
	# config for kernel
	menuconfig|saveconfig|uboot_menuconfig|uboot_saveconfig|mergeconfig|loadconfig|recovery_menuconfig|recovery_saveconfig)
		ACTION="handle_defconfig ${@:1};";
		break;
		;;
	# config for roofs
	bsp_menuconfig|openwrt_menuconfig|buildroot_menuconfig)
		ACTION="config_${1} ${@:2};"
		break;
		;;
	# save config for buildroot roofs
	buildroot_saveconfig)
		ACTION="config_${1} ${@:2};"
		break;
		;;
	# build package for buildroot
	buildroot_package)
		ACTION="build_${1} ${@:2};"
		break;
		;;
	# build for target
	dtb|brandy|bootloader|arisc|dts|kernel|modules|bootimg|rtos|dsp)
		ACTION="build_${1} ${@:2};"
		break;
		;;
	# build roofs
	bsp_rootfs|openwrt_rootfs|buildroot_rootfs|ubuntu_rootfs)
		ACTION="build_${1} ${@:2};"
		break;
		;;
	independent_package)
		OPTIONS=$(printf '"%s" ' "${@:2}")
		ACTION="eval build_${1};"
		break;
		;;
	# build for all
	tina)
		ACTION="build_linuxdev ${@:2};"
		break;
		;;
	# pack
	pack*)
		optlist=$(echo ${1#pack} | sed 's/_/ /g')
		mode=""
		for opt in $optlist; do
			case "$opt" in
				debug)
					mode="$mode -d card0"
					;;
				dump)
					mode="$mode -m dump"
					;;
				prvt)
					mode="$mode -f prvt"
					;;
				secure)
					mode="$mode -v secure"
					;;
				prev)
					mode="$mode -s prev_refurbish"
					;;
				crash)
					mode="$mode -m crashdump"
					;;
				vsp)
					mode="$mode -t vsp"
					;;
				raw)
					mode="$mode -w programmer"
					;;
				verity)
					mode="$mode --verity"
					;;
				signfel)
					mode="$mode --signfel"
					;;
				*)
					mk_error "Invalid pack option $opt"
					exit 1
					;;
			esac
		done
		######### Don't build other module, if pack firmware ########
		ACTION="mk_pack ${mode};";
		break;
		;;
	# clean
	clean|distclean)
		ACTION="mk_${1} ${@:2};"
		break;
		;;
	recovery)
		ACTION="mkrecovery;";
		break;
		;;
	ramfs)
		# $2:action $3:src $4:dst
		ACTION="mk_ramfs $2 $3 $4;";
		module="";
		break
		;;
	check_whitelist)
		ACTION="gki_extract_symbols_check;";
		break;
		;;
	*) ;;
	esac;
	dropargs=
	shift;
done

if [ ! -f "${BUILD_CONFIG}" ] && [ "$1" != autoconfig ] && [ "$1" != config ]; then
	# If we do config, it must be clean the old env var.
	clean_old_env_var

	mk_config ${@:2}
fi

# Execute the action list.
echo "========ACTION List: ${ACTION}========"
action_exit_status=$?
while [ -n "${ACTION}" ]; do
	act=${ACTION%%;*};
	echo "options : ${OPTIONS}"
	${act} ${OPTIONS}
	action_exit_status=$?
	ACTION=${ACTION#*;};
done
exit ${action_exit_status}
