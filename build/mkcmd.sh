# scripts/mkcmd.sh
#
# (c) Copyright 2013
# Allwinner Technology Co., Ltd. <www.allwinnertech.com>
# James Deng <csjamesdeng@allwinnertech.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Notice:
#   1. This script muse source at the top directory of lichee.
BUILD_SCRIPTS_DIR=$(cd $(dirname $0) && pwd)
source ${BUILD_SCRIPTS_DIR}/shflags
cpu_cores=`cat /proc/cpuinfo | grep "processor" | wc -l`
if [ ${cpu_cores} -le 8 ] ; then
	LICHEE_JLEVEL=${cpu_cores}
else
	LICHEE_JLEVEL=`expr ${cpu_cores} / 2`
fi

export LICHEE_JLEVEL

function mk_error()
{
	echo -e "\033[47;31mERROR: $*\033[0m"
}

function mk_warn()
{
	echo -e "\033[47;34mWARN: $*\033[0m"
}

function mk_info()
{
	echo -e "\033[47;30mINFO: $*\033[0m"
}
function parse_common_parameters()
{
	# some parameters that represent the build target for function mk_autoconfig()
	DEFINE_string  'ic'       ''          'ic to build, e.g. V316'             'i'
	DEFINE_string  'kernel'   ''          'Kernel to build, e.g. 3.3'          'k'
	DEFINE_string  'board'    ''          'Board to build, e.g. evb'           'b'
	DEFINE_string  'flash'    'default'   'flash to build, e.g. nor'           'n'
	DEFINE_string  'os'       ''          'os to build, e.g. android bsp'      'o'
	DEFINE_string  'arch'     ''          'arch to build, e.g. arm arm64'      'a'
	DEFINE_string  'sata_mod' 'all'       'sata module to build when build sata, e.g. all, spi, pinctrl, ...' 's'
	DEFINE_string  'jobs'     '1'         'how many jobs to build, e.g. 16'    'j'

	FLAGS "$@" || exit $?
	eval set -- "${FLAGS_ARGV}"

	FLAGS_IC=${FLAGS_ic}
	FLAGS_PLATFORM=${FLAGS_os}
	FLAGS_BOARD=${FLAGS_board}
	FLAGS_FLASH=${FLAGS_flash}
	FLAGS_KERN=${FLAGS_kernel}
	FLAGS_ARCH=${FLAGS_arch}
	FLAGS_SATA_MODE=${FLAGS_sata_mod}
	FLAGS_JOBS=${FLAGS_jobs}
}

function export_important_variable()
{
	# define importance variable
	export LICHEE_BUILD_DIR=$(cd $(dirname $0) && pwd)
	export LICHEE_TOP_DIR=$(cd $LICHEE_BUILD_DIR/.. && pwd)
	export LICHEE_DEVICE_DIR=${LICHEE_TOP_DIR}/device
	export LICHEE_PLATFORM_DIR=${LICHEE_TOP_DIR}/platform
	export LICHEE_SATA_DIR=${LICHEE_TOP_DIR}/test/SATA
	export LICHEE_DRAGONBAORD_DIR=${LICHEE_TOP_DIR}/test/dragonboard
	export LICHEE_DRAGONABTS_DIR=${LICHEE_TOP_DIR}/test/dragonabts
	export LICHEE_TOOLS_DIR=${LICHEE_TOP_DIR}/tools
	export LICHEE_COMMON_CONFIG_DIR=${LICHEE_DEVICE_DIR}/config/common
	export LICHEE_OUT_DIR=$LICHEE_TOP_DIR/out
	[ -z "${LICHEE_TOOLCHAIN_PATH}" ] && \
	export LICHEE_TOOLCHAIN_PATH=${LICHEE_OUT_DIR}/external-toolchain/gcc-arm
	export LICHEE_ARISC_PATH=${LICHEE_TOP_DIR}/brandy/arisc
	export LICHEE_DRAMLIB_PATH=${LICHEE_TOP_DIR}/brandy/dramlib
	export LICHEE_BSP_DIR=${LICHEE_TOP_DIR}/bsp

	# make surce at the top directory of lichee
	if [ ! -d ${LICHEE_BUILD_DIR} -o \
		! -d ${LICHEE_DEVICE_DIR} ] ; then
		mk_error "You are not at the top directory of lichee."
		mk_error "Please changes to that directory."
		return 1
	fi

	mkdir -p $LICHEE_OUT_DIR
}

selectconfig=(
LICHEE_ARCH
LICHEE_KERN_VER
)

boardconfig=(
${selectconfig[@]}
LICHEE_KERNEL_VERSION
LICHEE_KERN_DEFCONF
LICHEE_KERN_DEFCONF_RT
LICHEE_BUILDING_SYSTEM
LICHEE_BR_VER
LICHEE_BR_DEFCONF
LICHEE_DEFCONFIG_FRAGMENT
LICHEE_PRODUCT
LICHEE_BRANDY_VER
LICHEE_BRANDY_DEFCONF
LICHEE_BRANDY_UBOOT_VER
LICHEE_COMPILER_TAR
LICHEE_ROOTFS
LICHEE_BUSSINESS
LICHEE_BR_RAMFS_CONF
LICHEE_CHIP
LICHEE_RTOS_PROJECT_NAME
LICHEE_DSP_PROJECT_NAME
LICHEE_PACK_HOOK
LICHEE_REDUNDANT_ENV_SIZE
LICHEE_BRANDY_SPL
LICHEE_COMPRESS
LICHEE_NO_RAMDISK_NEEDED
LICHEE_RAMDISK_PATH
LICHEE_KERN_DEFCONF_RECOVERY
LICHEE_USE_INDEPENDENT_BSP
LICHEE_INDEPENDENT_PACK
LICHEE_BOOT0_BIN_NAME
LICHEE_EFEX_BIN_NAME
ANDROID_CLANG_PATH
ANDROID_TOOLCHAIN_PATH
ANDROID_CLANG_ARGS
LICHEE_BSP_STAGING
)

allconfig=(
${boardconfig[@]}
LICHEE_PLATFORM
LICHEE_LINUX_DEV
LICHEE_IC
LICHEE_BOARD
LICHEE_FLASH
LICHEE_KERN_SYSTEM
LICHEE_KERN_DEFCONF_RELATIVE
LICHEE_KERN_DEFCONF_ABSOLUTE
LICHEE_KERN_DEFCONF_RECOVERY_RELATIVE
LICHEE_KERN_DEFCONF_RECOVERY_ABSOLUTE
LICHEE_CROSS_COMPILER
CONFIG_SESSION_SEPARATE
LICHEE_TOP_DIR
LICHEE_CBBPKG_DIR
LICHEE_BRANDY_DIR
LICHEE_BUILD_DIR
LICHEE_BR_DIR
LICHEE_DEVICE_DIR
LICHEE_KERN_DIR
LICHEE_BSP_DIR
BSP_TOP
LICHEE_PLATFORM_DIR
LICHEE_SATA_DIR
LICHEE_DRAGONABTS_DIR
LICHEE_DRAGONBAORD_DIR
LICHEE_TOOLS_DIR
CONFIG_SESSION_SEPARATE
LICHEE_COMMON_CONFIG_DIR
LICHEE_CHIP_CONFIG_DIR
LICHEE_BOARD_CONFIG_DIR
LICHEE_PRODUCT_CONFIG_DIR
CONFIG_SESSION_SEPARATE
LICHEE_OUT_DIR
LICHEE_BRANDY_OUT_DIR
LICHEE_BR_OUT
LICHEE_PACK_OUT_DIR
LICHEE_TOOLCHAIN_PATH
LICHEE_PLAT_OUT
LICHEE_BOARDCONFIG_PATH
LICHEE_ARISC_PATH
LICHEE_DRAMLIB_PATH
LICHEE_KERN_NAME
LICHEE_KERN_TYPE
)

# export importance variable
platforms=(
"android"
"linux"
)

linux_development=(
"bsp"
)

flash=(
"default"
"nor"
)

arch=(
"arm"
"arm64"
)

cross_compiler=(
'linux-3.4	arm		gcc-linaro.tar.bz2						target_arm.tar.bz2'
'linux-3.4	arm64		gcc-linaro-aarch64.tar.xz					target_arm64.tar.bz2'
'linux-3.10	arm		gcc-linaro-arm.tar.xz						target_arm.tar.bz2'
'linux-3.10	arm64		gcc-linaro-aarch64.tar.xz					target_arm64.tar.bz2'
'linux-4.4	arm		gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi.tar.xz	target-arm-linaro-5.3.tar.bz2'
'linux-4.4	arm64		gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu.tar.xz	target-arm64-linaro-5.3.tar.bz2'
'linux-4.9	arm		gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi.tar.xz	target-arm-linaro-5.3.tar.bz2'
'linux-4.9	arm64		gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu.tar.xz	target-arm64-linaro-5.3.tar.bz2'
'linux-5.4	arm		gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi.tar.xz	target-arm-linaro-5.3.tar.bz2'
'linux-5.4	arm64		gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu.tar.xz	target-arm64-linaro-5.3.tar.bz2'
'linux-5.4	riscv64		riscv64-linux-x86_64-20200528.tar.xz				target_riscv.tar.bz2'
'linux-5.4	riscv32		nds32le-linux-glibc-v5d.txz					rootfs_riscv32'
'linux-5.10	arm		gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi.tar.xz	target-arm-linaro-5.3.tar.bz2'
'linux-5.10	arm64		gcc-linaro-5.1-2015.08-x86_64_aarch64-linux-gnu.tar.xz		target-arm64-linaro-5.3.tar.bz2'
'linux-5.10-origin	arm		gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz	target-arm-10.3'
'linux-5.10-origin	arm64		gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz	target-arm64-10.3'
'linux-5.15	arm		gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz	target-arm-10.3'
'linux-5.15	arm64		gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz	target-arm64-10.3'
'linux-5.15-origin	arm		gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz	target-arm-10.3'
'linux-5.15-origin	arm64		gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz	target-arm64-10.3'
'linux-6.1	arm		gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz	target-arm-10.3'
'linux-6.1	arm64		gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz	target-arm64-10.3'
'linux-6.6	arm64		gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz	target-arm64-10.3'
)

gki_check_whitelist=(
'a523	linux-5.15'
'a527	linux-5.15'
'a133	linux-5.4|linux-5.15'
)

#eg. save_config "LICHEE_PLATFORM" "$LICHEE_PLATFORM" $BUILD_CONFIG
function save_config()
{
	local cfgkey=$1
	local cfgval=$2
	local cfgfile=$3
	local dir=$(dirname $cfgfile)
	[ ! -d $dir ] && mkdir -p $dir
	cfgval=$(echo -e "$cfgval" | sed -e 's/^\s\+//g' -e 's/\s\+$//g')
	if [ -f $cfgfile ] && [ -n "$(sed -n "/^\s*export\s\+$cfgkey\s*=/p" $cfgfile)" ]; then
		sed -i "s|^\s*export\s\+$cfgkey\s*=\s*.*$|export $cfgkey=$cfgval|g" $cfgfile
	else
		echo "export $cfgkey=$cfgval" >> $cfgfile
	fi
}

function load_config()
{
	local cfgkey=$1
	local cfgfile=$2
	local defval=$3
	local val=""

	[ -f "$cfgfile" ] && val="$(sed -n "/^\s*export\s\+$cfgkey\s*=/h;\${x;p}" $cfgfile | sed -e 's/^[^=]\+=//g' -e 's/^\s\+//g' -e 's/\s\+$//g')"
	eval echo "${val:-"$defval"}"
}

#
# This function can get the realpath between $SRC and $DST
#
function get_realpath()
{
	local src=$(cd $1; pwd);
	local dst=$(cd $2; pwd);
	local res="./";
	local tmp="$dst"

	while [ "${src##*$tmp}" == "${src}" ]; do
		tmp=${tmp%/*};
		res=$res"../"
	done
	res="$res${src#*$tmp/}"

	printf "%s" $res
}

function check_output_dir()
{
	#mkdir out directory:
	if [ "x" != "x${LICHEE_PLAT_OUT}" ]; then
		if [ ! -d ${LICHEE_PLAT_OUT} ]; then
			mkdir -p ${LICHEE_PLAT_OUT}
		fi
	fi

	if [ "x" != "x${LICHEE_PLATFORM}" ]; then
		if [ ${LICHEE_PLATFORM} = "linux" ] ; then
			if [ ${LICHEE_LINUX_DEV} = "buildroot" ] ; then
				if [ "x" != "x${LICHEE_BR_OUT}" ]; then
					if [ ! -d ${LICHEE_BR_OUT} ]; then
						mkdir -p ${LICHEE_BR_OUT}
					fi
				fi
			fi
		fi
	fi

}

function check_env()
{
	if [ -z "${LICHEE_IC}" -o \
		-z "${LICHEE_PLATFORM}" -o \
		-z "${LICHEE_BOARD}" ] ; then
		mk_error "run './build.sh config' setup env"
		exit 1
	fi

	if [ ${LICHEE_PLATFORM} = "linux" ] ; then
		if [ -z "${LICHEE_LINUX_DEV}" ] ; then
			mk_error "LICHEE_LINUX_DEV is invalid, run './build.sh config' setup env"
			exit 1
		fi
	else
		[ ! -e $LICHEE_TOP_DIR/Android.mk ] && \
		printf 'ifeq ($(BUILD_LONGAN_IN_ANDROID), true)\n\tinclude $(call all-subdir-makefiles)\nendif\n' > $LICHEE_TOP_DIR/Android.mk
	fi

	check_output_dir
	cd ${LICHEE_DEVICE_DIR}
	ln -sfT $(get_realpath config/chips/ ./)/${LICHEE_IC} product
	cd - > /dev/null
}

function loadconfig_for_independent_bsp()
{
	local KERNEL_DEFCONF_PATH=$LICHEE_KERN_DIR/arch/$LICHEE_ARCH/configs
	local search_dir=""
	local CURRENT_DEFCONF_ABSOLUTE=""
	local CURRENT_DEFCONF_RELATIVE=""

	# Note: Order is important in defconfig parent dir list
	search_dir+=($KERNEL_DEFCONF_PATH)
	search_dir+=($LICHEE_BOARD_CONFIG_DIR/${LICHEE_KERN_VER})
	search_dir+=($LICHEE_CHIP_CONFIG_DIR/configs/default/${LICHEE_KERN_VER}/${LICHEE_ARCH})
	search_dir+=($LICHEE_CHIP_CONFIG_DIR/configs/default/${LICHEE_KERN_VER})
	search_dir+=($LICHEE_BSP_DIR/configs/${LICHEE_KERN_VER})

	for path in "${search_dir[@]}"; do
		if [ -f "$path/$1" ]; then
			CURRENT_DEFCONF_ABSOLUTE=$path/$1
			CURRENT_DEFCONF_RELATIVE=($(python -c "import os.path; print (os.path.relpath('$path', '$KERNEL_DEFCONF_PATH'))")/$1)
			break
		fi
	done
	if [ -z "$CURRENT_DEFCONF_RELATIVE" ]; then
		mk_error "can't find defconfig: $1"
	else
		save_config "LICHEE_KERN_DEFCONF_RELATIVE" ${CURRENT_DEFCONF_RELATIVE} $BUILD_CONFIG
		save_config "LICHEE_KERN_DEFCONF_ABSOLUTE" ${CURRENT_DEFCONF_ABSOLUTE} $BUILD_CONFIG
		LOAD_DEFCONFIG_NAME=$CURRENT_DEFCONF_RELATIVE
	fi
}

function handle_defconfig()
{
	prepare_toolchain

	local MAKE="make"
	local ARCH_PREFIX="arm"
	local CROSS_COMPILE="${LICHEE_TOOLCHAIN_PATH}/bin/${LICHEE_CROSS_COMPILER}-"
	local CLANG_TRIPLE=""
	local uboot_path=""

	if echo "${LICHEE_KERN_VER}" | grep -Eq "linux-6.[0-9]+"; then
		# Ensures `make 4.3` as the default `make`, to solve the build error in linux-6.1:
		#   linux-6.1/Makefile: 1308: *** multiple target patterns.  Stop.
		# Notice: make-4.3+ requires GLIBC_2.15+
		MAKE="${LICHEE_BUILD_DIR}/bin/make-4.3"
		mk_info "use local '${LICHEE_BUILD_DIR}/bin/make-4.3' as the default make"
	fi

	if [ -n "$ANDROID_CLANG_PATH" ]; then
		export PATH=$ANDROID_CLANG_PATH:$PATH
		MAKE+=" $ANDROID_CLANG_ARGS"
		[ "x${LICHEE_ARCH}" = "xarm64" ] && ARCH_PREFIX=aarch64
		if [ -n "$ANDROID_TOOLCHAIN_PATH" ]; then
			export CROSS_COMPILE=$ANDROID_TOOLCHAIN_PATH/$ARCH_PREFIX-linux-androidkernel-
			export CLANG_TRIPLE=$ARCH_PREFIX-linux-gnu-
		fi
	else
		if [ -n "${LICHEE_TOOLCHAIN_PATH}" -a -d "${LICHEE_TOOLCHAIN_PATH}" ]; then
			local GCC=$(find ${LICHEE_TOOLCHAIN_PATH} -perm /a+x -a -regex '.*-gcc' | head -n 1)
			export CROSS_COMPILE="${GCC%-*}-";
		elif [ -n "${LICHEE_CROSS_COMPILER}" ]; then
			export CROSS_COMPILE="${LICHEE_CROSS_COMPILER}-"
		else
			if [ "${LICHEE_ARCH}" == "arm" ]; then
				export CROSS_COMPILE=arm-linux-gnueabi-
			elif [ "${LICHEE_ARCH}" == "arm64" ]; then
				export CROSS_COMPILE=aarch64-linux-gnu-
			elif [ "${LICHEE_ARCH}" == "riscv" ]; then
				export CROSS_COMPILE=riscv64-unknown-linux-gnu-
			elif [ "${LICHEE_ARCH}" == "riscv32" ]; then
				export CROSS_COMPILE=riscv32-unknown-linux-
			else
				mk_error "Unsupported arch: [$ARCH]!"
				exit 1
			fi
		fi
	fi

	MAKE+=" -C $LICHEE_KERN_DIR ARCH=${LICHEE_KERNEL_ARCH}"

	[ "$LICHEE_KERN_DIR" != "$KERNEL_BUILD_OUT_DIR" ] && \
	MAKE+=" O=$KERNEL_BUILD_OUT_DIR"

	case "$1" in
		loadconfig)
			local LOAD_DEFCONFIG_NAME=$LICHEE_KERN_DEFCONF_RELATIVE
			if [ -n "$2" ] && [[ "$2" != *fragment ]]; then
				if [ "x${LICHEE_USE_INDEPENDENT_BSP}" == "xtrue" ] ; then
					loadconfig_for_independent_bsp $2
				else
					LOAD_DEFCONFIG_NAME=$(dirname $LICHEE_KERN_DEFCONF_RELATIVE)/$2
				fi
			fi
			(cd ${LICHEE_KERN_DIR} && \
			${MAKE} defconfig KBUILD_DEFCONFIG=$LOAD_DEFCONFIG_NAME
			)

			shift
			local fragment_list="$*"
			for fragment in $fragment_list; do
				if [[ "$fragment" == *fragment ]]; then
					bsp_merge_config $LICHEE_BSP_DIR/configs/$LICHEE_KERN_VER/"$fragment"
				fi
			done
			;;
		recovery_menuconfig)
			local LOAD_DEFCONFIG_RECOVERY_NAME=$LICHEE_KERN_DEFCONF_RECOVERY_RELATIVE
			if [ -n "${LICHEE_KERN_DEFCONF_RECOVERY_RELATIVE}" ]; then
				(cd ${LICHEE_KERN_DIR} && \
				${MAKE} defconfig KBUILD_DEFCONFIG=$LOAD_DEFCONFIG_RECOVERY_NAME && \
				${MAKE} menuconfig
				)
			fi
			;;
		menuconfig)
			(cd ${LICHEE_KERN_DIR} && \
			${MAKE} menuconfig
			)
			;;
		uboot_menuconfig)
			if [ $LICHEE_BRANDY_UBOOT_VER -eq 2023 ]; then
				uboot_path=${LICHEE_BRANDY_DIR}/u-boot-$LICHEE_BRANDY_UBOOT_VER
				(cd ${uboot_path} && ${LICHEE_BRANDY_DIR}/tools/make_dir/make4.1/bin/make menuconfig)
			else
				echo "cmd '$1' is not supported"
			fi
			;;
		uboot_saveconfig)
			if [ $LICHEE_BRANDY_UBOOT_VER -eq 2023 ]; then
				uboot_path=${LICHEE_BRANDY_DIR}/u-boot-$LICHEE_BRANDY_UBOOT_VER
				(cd ${uboot_path} && ${LICHEE_BRANDY_DIR}/tools/make_dir/make4.1/bin/make savedefconfig)
			else
				echo "cmd '$1' is not supported"
			fi
			;;
		recovery_saveconfig)
			local SAVE_DEFCONFIG_RECOVERY_NAME=$LICHEE_KERN_DEFCONF_RECOVERY_ABSOLUTE
			if [ -n "${LICHEE_KERN_DEFCONF_RECOVERY_ABSOLUTE}" ]; then
				(cd ${LICHEE_KERN_DIR} && \
				${MAKE} savedefconfig && \
				mv $KERNEL_BUILD_OUT_DIR/defconfig $SAVE_DEFCONFIG_RECOVERY_NAME
				)
			fi
			;;
		saveconfig)
			local SAVE_DEFCONFIG_NAME=$LICHEE_KERN_DEFCONF_ABSOLUTE
			if [ -n "$2" ]; then
				SAVE_DEFCONFIG_NAME=$(dirname $LICHEE_KERN_DEFCONF_ABSOLUTE)/$2
			fi
			if [ -f $KERNEL_BUILD_OUT_DIR/.config.delta ]; then
				grep -vf $KERNEL_BUILD_OUT_DIR/.config.delta $KERNEL_BUILD_OUT_DIR/.config > $KERNEL_BUILD_OUT_DIR/.config.tmp
				mv $KERNEL_BUILD_OUT_DIR/.config.tmp $KERNEL_BUILD_OUT_DIR/.config
			fi
			(cd ${LICHEE_KERN_DIR} && \
			${MAKE} savedefconfig && \
			mv $KERNEL_BUILD_OUT_DIR/defconfig $SAVE_DEFCONFIG_NAME
			)
			;;
		mergeconfig)
			([ "$1" == "mergeconfig" ] && \
			cd ${LICHEE_KERN_DIR} && \
			${LICHEE_KERN_DIR}/scripts/kconfig/merge_config.sh \
			-O ${KERNEL_BUILD_OUT_DIR} \
			${LICHEE_KERN_DIR}/arch/${LICHEE_KERNEL_ARCH}/configs/${LICHEE_CHIP}smp_defconfig \
			${LICHEE_KERN_DIR}/kernel/configs/android-base.config  \
			${LICHEE_KERN_DIR}/kernel/configs/android-recommended.config  \
			${LICHEE_KERN_DIR}/kernel/configs/sunxi-recommended.config
			)
			;;
		*)
			mk_error "Unsupport action: $1"
			return 1
			;;
	esac
}

function bsp_merge_config()
{
	cp $LICHEE_OUT_DIR/$LICHEE_IC/kernel/build/.config $LICHEE_OUT_DIR/$LICHEE_IC/kernel/build/.config.tmp
	$LICHEE_KERN_DIR/scripts/kconfig/merge_config.sh -m $LICHEE_OUT_DIR/$LICHEE_IC/kernel/build/.config $1
	mv .config $LICHEE_OUT_DIR/$LICHEE_IC/kernel/build/.config
	diff $LICHEE_OUT_DIR/$LICHEE_IC/kernel/build/.config  $LICHEE_OUT_DIR/$LICHEE_IC/kernel/build/.config.tmp | grep "< " | sed 's/< //g' >> $LICHEE_OUT_DIR/$LICHEE_IC/kernel/build/.config.delta
	rm $LICHEE_OUT_DIR/$LICHEE_IC/kernel/build/.config.tmp
}

function init_defconf()
{
	if [ "$ENV_SKIP_LOAD_DEFCONFIG" == "true" ]; then
		check_output_dir
		return 0
	fi

	if [ -n "${LICHEE_KERN_DIR}" ]; then
		local relative_path=""
		local absolute_path=""
		local relative_recovery_path=""
		local absolute_recovery_path=""
		local KERNEL_DEFCONF_PATH=$LICHEE_KERN_DIR/arch/$LICHEE_KERNEL_ARCH/configs
		local search_tab
		local search_recovery_tab

		if [ "${LICHEE_LINUX_DEV}" = "openwrt" ] ; then
			search_tab+=($LICHEE_BOARD_CONFIG_DIR/${LICHEE_LINUX_DEV}/${LICHEE_KERN_DEFCONF})
			search_recovery_tab+=($LICHEE_BOARD_CONFIG_DIR/${LICHEE_LINUX_DEV}/${LICHEE_KERN_DEFCONF_RECOVERY})
		fi

		if [ "${LICHEE_KERN_TYPE}" == "rt" ]; then
			if [ -n "$LICHEE_KERN_DEFCONF_RT" ]; then
				search_tab+=($KERNEL_DEFCONF_PATH/${LICHEE_KERN_DEFCONF_RT})
				search_tab+=($LICHEE_BOARD_CONFIG_DIR/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF_RT})
				search_tab+=($LICHEE_CHIP_CONFIG_DIR/configs/default/${LICHEE_KERN_VER}/${LICHEE_ARCH}/${LICHEE_KERN_DEFCONF_RT})
				search_tab+=($LICHEE_CHIP_CONFIG_DIR/configs/default/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF_RT})
				search_tab+=($LICHEE_BSP_DIR/configs/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF_RT})
			fi
		fi

		if [ "${LICHEE_LINUX_DEV}" == "ubuntu" ]; then
			search_tab+=($LICHEE_BOARD_CONFIG_DIR/ubuntu/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF})
		fi

		if [ -n "$LICHEE_KERN_DEFCONF" ]; then
			search_tab+=($KERNEL_DEFCONF_PATH/${LICHEE_KERN_DEFCONF})
			search_tab+=($LICHEE_BOARD_CONFIG_DIR/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF})
			search_tab+=($LICHEE_CHIP_CONFIG_DIR/configs/default/${LICHEE_KERN_VER}/${LICHEE_ARCH}/${LICHEE_KERN_DEFCONF})
			search_tab+=($LICHEE_CHIP_CONFIG_DIR/configs/default/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF})
			search_tab+=($LICHEE_BSP_DIR/configs/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF})
		fi

		if [ -n "${LICHEE_LINUX_DEV}" ]; then
			search_tab+=($LICHEE_BOARD_CONFIG_DIR/$LICHEE_LINUX_DEV/config-${LICHEE_ARCH}-${LICHEE_KERN_VER:6})
			search_tab+=($LICHEE_BOARD_CONFIG_DIR/$LICHEE_LINUX_DEV/config-${LICHEE_KERN_VER:6})
		fi

		if [ -n "$LICHEE_KERN_DEFCONF_RECOVERY" ]; then
			search_recovery_tab+=($KERNEL_DEFCONF_PATH/${LICHEE_KERN_DEFCONF_RECOVERY})
			search_recovery_tab+=($LICHEE_BOARD_CONFIG_DIR/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF_RECOVERY})
			search_recovery_tab+=($LICHEE_CHIP_CONFIG_DIR/configs/default/${LICHEE_KERN_VER}/${LICHEE_ARCH}/${LICHEE_KERN_DEFCONF_RECOVERY})
			search_recovery_tab+=($LICHEE_CHIP_CONFIG_DIR/configs/default/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF_RECOVERY})
			search_recovery_tab+=($LICHEE_BSP_DIR/configs/${LICHEE_KERN_VER}/${LICHEE_KERN_DEFCONF_RECOVERY})
		fi

		search_tab+=($LICHEE_BOARD_CONFIG_DIR/$LICHEE_KERN_VER/config-${LICHEE_ARCH}-${LICHEE_KERN_VER:6})
		search_tab+=($LICHEE_BOARD_CONFIG_DIR/$LICHEE_KERN_VER/config-${LICHEE_KERN_VER:6})
		search_tab+=($LICHEE_CHIP_CONFIG_DIR/configs/default/config-${LICHEE_ARCH}-${LICHEE_KERN_VER:6})
		search_tab+=($LICHEE_CHIP_CONFIG_DIR/configs/default/config-${LICHEE_KERN_VER:6})

		for absolute_path in "${search_tab[@]}"; do
			if [ -f $absolute_path ]; then
				relative_path=$(python -c "import os.path; print (os.path.relpath('$absolute_path', '$KERNEL_DEFCONF_PATH'))")
				break
			fi
		done

		for absolute_recovery_path in "${search_recovery_tab[@]}"; do
			if [ -f $absolute_recovery_path ]; then
				relative_recovery_path=$(python -c "import os.path; print (os.path.relpath('$absolute_recovery_path', '$KERNEL_DEFCONF_PATH'))")
				save_config "LICHEE_KERN_DEFCONF_RECOVERY_RELATIVE" ${relative_recovery_path} $BUILD_CONFIG
				save_config "LICHEE_KERN_DEFCONF_RECOVERY_ABSOLUTE" ${absolute_recovery_path} $BUILD_CONFIG
				LICHEE_KERN_DEFCONF_RECOVERY_RELATIVE=$relative_recovery_path
				LICHEE_KERN_DEFCONF_RECOVERY_ABSOLUTE=$absolute_recovery_path
				mk_info "kernel relative recovery defconfig: ${relative_recovery_path}"
				mk_info "kernel absolute recovery defconfig: ${absolute_recovery_path}"
				break
			fi
		done

		if [ -z "$relative_path" ]; then
			mk_error "Can't find kernel defconfig!"
			exit 1
		fi

		save_config "LICHEE_KERN_DEFCONF_RELATIVE" ${relative_path} $BUILD_CONFIG
		save_config "LICHEE_KERN_DEFCONF_ABSOLUTE" ${absolute_path} $BUILD_CONFIG
		LICHEE_KERN_DEFCONF_RELATIVE=$relative_path
		LICHEE_KERN_DEFCONF_ABSOLUTE=$absolute_path

		prepare_toolchain
		mk_info "kernel defconfig: generate ${KERNEL_BUILD_OUT_DIR}/.config by ${absolute_path}"
		handle_defconfig "loadconfig"
		if [[ -n "${LICHEE_DEFCONFIG_FRAGMENT}" ]]; then
			for str in $LICHEE_DEFCONFIG_FRAGMENT; do
				bsp_merge_config $LICHEE_BSP_DIR/configs/$LICHEE_KERN_VER/"$str"
			done
		fi
	fi
	if [ "${LICHEE_PLATFORM}" = "linux" ] ; then
		if [ ${LICHEE_LINUX_DEV} = "buildroot" ] ; then
		# later change to :${LICHEE_LINUX_DEV} = "buildroot"
			if [ -d ${LICHEE_BR_DIR} -a -f ${LICHEE_BR_DIR}/configs/${LICHEE_BR_DEFCONF} ]; then
				rm -rf ${LICHEE_BR_OUT}/.config
				(cd ${LICHEE_BR_DIR};make O=${LICHEE_BR_OUT} -C ${LICHEE_BR_DIR} ${LICHEE_BR_DEFCONF})
				mk_info "buildroot defconfig is ${LICHEE_BR_DEFCONF} "
			else
				mk_info "skip buildroot"
			fi
		fi

		if [ "${LICHEE_LINUX_DEV}" = "openwrt" ] ; then
			$TODO # delete openwrt .config and make openwrt defconfig
		fi

		if [ "${LICHEE_LINUX_DEV}" = "bsp" ] ; then
			$TODO # to do
		fi
	fi

	#mkdir out directory:
	check_output_dir
}

function list_subdir()
{
	echo "$(eval "$(echo "$(ls -d $1/*/)" | sed  "s/^/basename /g")")"
}

function init_key()
{
	local val_list=$1
	local cfg_key=$2
	local cfg_val=$3

	if [ -n "$(echo $val_list | grep -w $cfg_val)" ]; then
		export $cfg_key=$cfg_val
		return 0
	else
		return 1
	fi
}

function init_chips()
{
	local cfg_val=$1 # chip
	local cfg_key="LICHEE_CHIP"
	local val_list=$(list_subdir $LICHEE_DEVICE_DIR/config/chips)
	init_key "$val_list" "$cfg_key" "$cfg_val"
	return $?
}

function init_ic()
{
	local cfg_val=$1 # chip
	local cfg_key="LICHEE_IC"
	local val_list=$(list_subdir $LICHEE_DEVICE_DIR/config/chips)
	init_key "$val_list" "$cfg_key" "$cfg_val"
	return $?
}

function init_platforms()
{
	local cfg_val=$1 # platform
	local cfg_key="LICHEE_PLATFORM"
	local val_list=${platforms[@]}
	init_key "$val_list" "$cfg_key" "$cfg_val"
	return $?
}

function init_kern_ver()
{
	local cfg_val=$1 # kern_ver
	local cfg_key="LICHEE_KERN_NAME"
	local val_list=$(list_subdir $LICHEE_TOP_DIR | grep "linux-")
	init_key "$val_list" "$cfg_key" "$cfg_val"
	return $?
}

function init_boards()
{
	local chip=$1
	local cfg_val=$2 # board
	local cfg_key="LICHEE_BOARD"
	local val_list=$(list_subdir $LICHEE_DEVICE_DIR/config/chips/$chip/configs | grep -v default)
	init_key "$val_list" "$cfg_key" "$cfg_val"
	return $?
}

function mk_select()
{
	local val_list=$1
	local cfg_key=$2
	local cnt=0
	local cfg_val=$(load_config $cfg_key $BUILD_CONFIG)
	local cfg_idx=0
	local banner=$(echo ${cfg_key:7} | tr '[:upper:]' '[:lower:]')

	printf "All available $banner:\n"
	for val in $val_list; do
		array[$cnt]=$val
		if [ "X_$cfg_val" == "X_${array[$cnt]}" ]; then
			cfg_idx=$cnt
		fi
		printf "%4d. %s\n" $cnt $val
		let "cnt++"
	done
	while true; do
		read -p "Choice [${array[$cfg_idx]}]: " choice
		if [ -z "${choice}" ]; then
			choice=$cfg_idx
		fi

		if [ -z "${choice//[0-9]/}" ] ; then
			if [ $choice -ge 0 -a $choice -lt $cnt ] ; then
				cfg_val="${array[$choice]}"
				break;
			fi
		fi
		 printf "Invalid input ...\n"
	done
	export $cfg_key=$cfg_val
	save_config "$cfg_key" "$cfg_val" $BUILD_CONFIG
}

# For *newer* boards which run linux-5.4 and above:
# Since different kernels use different `board.dts`,
# We unify them with a soft link which has a certain path `${LICHEE_BOARD_CONFIG_DIR}/board.dts`.
# This soft link stays in the same path with linux-4.9's `board.dts` for backwards compatibility.
function board_dts_create_link()
{
	pushd ${LICHEE_BOARD_CONFIG_DIR} >/dev/null
	local new_board_dts="${LICHEE_KERN_VER}/board.dts"
	if [ -f ${new_board_dts} ]; then
		ln -sf ${new_board_dts} board.dts
	fi
	popd >/dev/null
}

function board_dts_remove_link()
{
	if [ -h "${LICHEE_BOARD_CONFIG_DIR}/board.dts" ] ; then
		rm -f ${LICHEE_BOARD_CONFIG_DIR}/board.dts
	fi
}

function copy_prebuilt_product_to_staging()
{
	if [ "x${LICHEE_PLATFORM}" = "xandroid" ]; then
		copy_bin_firmware ${LICHEE_PLAT_OUT}
	fi
}

function bsp_action()
{
	if [ "x${LICHEE_USE_INDEPENDENT_BSP}" = "xtrue" ] ; then
		operation=$@
		${BUILD_SCRIPTS_DIR}/bsp.sh ${operation}
	fi
}

function mk_autoconfig()
{
	parse_common_parameters $@
	# we have do clean_old_var() before auto_config(), so that we need export the variable again
	export_important_variable
	local IC=${FLAGS_IC}
	local platform=${FLAGS_PLATFORM}
	local board=${FLAGS_BOARD}
	local flash=${FLAGS_FLASH}
	local linux_ver=${FLAGS_KERN}
	local linux_arch=${FLAGS_ARCH}
	local sata_mod=${FLAGS_SATA_MODE}
	local linux_dev=""

	if [ "${platform}" != "android" ]; then
		linux_dev=${platform}
		platform="linux"
	fi

	export LICHEE_IC=${IC}
	export LICHEE_BOARD=${board}
	export LICHEE_PLATFORM=${platform}
	export LICHEE_FLASH=${flash}
	export LICHEE_LINUX_DEV=${linux_dev}

	if [ "x$linux_dev" = "xsata" ] && [ "x$sata_mod" != "x" ];then
	    export LICHEE_BTEST_MODULE=$sata_mod
	fi

	if [ -n "${linux_ver}" ]; then
		LICHEE_KERN_VER=${linux_ver}
		LICHEE_KERN_NAME=${linux_ver}
		if [[ ${linux_ver} == *_* ]]; then
			LICHEE_KERN_VER=${linux_ver%_*}
			LICHEE_KERN_TYPE=${linux_ver#*_}
		fi
	fi

	#parse boardconfig
	parse_boardconfig

	if [ -n "${linux_arch}" ]; then
		export LICHEE_ARCH=${linux_arch}
	fi

	if [ -z "${LICHEE_ARCH}" ]; then
		mk_error "can not find LICHEE_ARCH."
		exit 1
	else
		if [ "x${LICHEE_ARCH}" = "xarm" ]; then
			LICHEE_KERNEL_ARCH=arm
		fi

		if [ "x${LICHEE_ARCH}" = "xarm64" ]; then
			LICHEE_KERNEL_ARCH=arm64
		fi

		if [ "x${LICHEE_ARCH}" = "xriscv64" -o "x${LICHEE_ARCH}" = "xriscv32" ]; then
			LICHEE_KERNEL_ARCH=riscv
		fi

		save_config "LICHEE_KERNEL_ARCH" ${LICHEE_KERNEL_ARCH} $BUILD_CONFIG
	fi

	if [ -z "${LICHEE_KERN_NAME}" ]; then
		LICHEE_KERN_NAME=${LICHEE_KERN_VER}
	fi

	parse_toolchain_and_rootfs
	init_global_variable

	#save config to buildconfig
	save_config_to_buildconfig
	# setup bsp to kernel
	bsp_action setup

	#init defconfig
	init_defconf
	board_dts_create_link

	#update amp firmware address
	update_bin_path

	#restart buildserver
	clbuildserver
	prepare_buildserver

	cp $BUILD_CONFIG $LICHEE_PLAT_OUT
}

function config_openwrt_menuconfig()
{
	local openwrt_rootdir=${LICHEE_TOP_DIR}/openwrt/openwrt

	echo "==mkcmd.sh: mk_openwrt_menuconfig=="
	${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C ${openwrt_rootdir} menuconfig $@

	return $?
}

function config_buildroot_menuconfig()
{
	local buildroot_rootdir=${LICHEE_TOP_DIR}/buildroot/buildroot-${LICHEE_BR_VER}

	echo "==mkcmd.sh: mk_buildroot_menuconfig=="
	make -C ${buildroot_rootdir} menuconfig

	return $?
}

function config_buildroot_saveconfig()
{
	local buildroot_rootdir=${LICHEE_TOP_DIR}/buildroot/buildroot-${LICHEE_BR_VER}

	echo "==mkcmd.sh: mk_buildroot_savedefconfig=="
	make -C ${buildroot_rootdir} savedefconfig

	return $?
}

function build_buildroot_package()
{
	local buildroot_rootdir=${LICHEE_TOP_DIR}/buildroot/buildroot-${LICHEE_BR_VER}

	echo "==mkcmd.sh: build_buildroot_package=="
	make -C ${buildroot_rootdir} $@

	return $?
}

function config_bsp_menuconfig()
{
	$TODO
	return $?
}

function build_openwrt_rootfs()
{
	local openwrt_rootdir=${LICHEE_TOP_DIR}/openwrt/openwrt

	echo "==mkcmd.sh: build_openwrt_rootfs $@=="
	${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C ${openwrt_rootdir} $@

	return $?
}

function clopenwrt()
{
	$TODO
	return $?
}

function mk_config()
{
	parse_common_parameters $@
	# we have do clean_old_var() before config(), so that we need export the variable again
	export_important_variable
	#select config
	select_platform

	if [ ${LICHEE_PLATFORM} = "linux" ] ; then
		select_linux_development
		if [ ${LICHEE_LINUX_DEV} = "bsp" ] || [ ${LICHEE_LINUX_DEV} = "ubuntu" ]; then
			select_kern_ver
		elif [ ${LICHEE_LINUX_DEV} = "sata" ] ; then
			select_kern_ver
			select_sata_module
		fi
	fi

	select_ic
	select_board
	select_flash

	#parse boardconfig
	parse_boardconfig

	[ -z "${LICHEE_KERN_VER}" ] && \
	select_kern_ver

	if [ -z "${LICHEE_KERN_NAME}" ]; then
		LICHEE_KERN_NAME=${LICHEE_KERN_VER}
	fi

	parse_boardconfig

	if [ -z "${LICHEE_ARCH}" ]; then
		select_arch
	else
		if [ "x${LICHEE_ARCH}" = "xarm" ]; then
			LICHEE_KERNEL_ARCH=arm
		fi

		if [ "x${LICHEE_ARCH}" = "xarm64" ]; then
			LICHEE_KERNEL_ARCH=arm64
		fi

		if [ "x${LICHEE_ARCH}" = "xriscv64" -o "x${LICHEE_ARCH}" = "xriscv32" ]; then
			LICHEE_KERNEL_ARCH=riscv
		fi

		save_config "LICHEE_KERNEL_ARCH" ${LICHEE_KERNEL_ARCH} $BUILD_CONFIG
	fi

	parse_boardconfig

	parse_toolchain_and_rootfs
	init_global_variable
	#print_config

	#save config to buildconfig
	save_config_to_buildconfig
	#print_buildconfig
	# setup bsp to kernel
	bsp_action setup

	#init defconfig
	init_defconf
	board_dts_create_link

	#update amp firmware address
	update_bin_path

	#restart buildserver
	clbuildserver
	prepare_buildserver

	cp $BUILD_CONFIG $LICHEE_PLAT_OUT
}

function clean_old_env_var()
{
	local cfgkey
	for cfgkey in ${allconfig[@]}; do
		[ "x$cfgkey" == "xCONFIG_SESSION_SEPARATE" ] && continue
		export $cfgkey=""
	done
}

function init_global_variable()
{
	check_env

	export LICHEE_PACK_OUT_DIR=${LICHEE_OUT_DIR}/${LICHEE_IC}/${LICHEE_BOARD}/pack_out
	export LICHEE_BRANDY_DIR=${LICHEE_TOP_DIR}/brandy/brandy-${LICHEE_BRANDY_VER}
	export  LICHEE_KERN_DIR=${LICHEE_TOP_DIR}/kernel/${LICHEE_KERN_NAME}

	if [ ! -f $LICHEE_KERN_DIR/Makefile ]; then
		mk_error "Cannot find avalible kernel code for ${LICHEE_KERN_NAME}"
		exit 1
	fi

	if [ ${LICHEE_PLATFORM} = "linux" ] ; then
		export LICHEE_BR_DIR=${LICHEE_TOP_DIR}/buildroot/buildroot-${LICHEE_BR_VER}
	fi

	export LICHEE_PRODUCT_CONFIG_DIR=${LICHEE_DEVICE_DIR}/target/${LICHEE_PRODUCT}

	export LICHEE_BRANDY_OUT_DIR=${LICHEE_DEVICE_DIR}/config/chips/${LICHEE_IC}/bin
	export LICHEE_BR_OUT=${LICHEE_OUT_DIR}/${LICHEE_IC}/${LICHEE_BOARD}/${LICHEE_LINUX_DEV}/buildroot

	if [ ${LICHEE_PLATFORM} = "android" ] ; then
		export LICHEE_PLAT_OUT=${LICHEE_OUT_DIR}/${LICHEE_IC}/${LICHEE_BOARD}/${LICHEE_PLATFORM}
	else
		export LICHEE_PLAT_OUT=${LICHEE_OUT_DIR}/${LICHEE_IC}/${LICHEE_BOARD}/${LICHEE_LINUX_DEV}
	fi

	export LICHEE_CBBPKG_DIR=${LICHEE_TOP_DIR}/platform

	local VERSION=$(grep "^VERSION =" $LICHEE_KERN_DIR/Makefile | awk -F= '{print $2}' | awk '$1 = $1')
	local PATCHLEVEL=$(grep "^PATCHLEVEL =" $LICHEE_KERN_DIR/Makefile | awk -F= '{print $2}' | awk '$1 = $1')
	local SUBLEVEL=$(grep "^SUBLEVEL =" $LICHEE_KERN_DIR/Makefile | awk -F= '{print $2}' | awk '$1 = $1')
	export LICHEE_KERNEL_VERSION="${VERSION}.${PATCHLEVEL}.${SUBLEVEL}"
}

function parse_rootfs_tar()
{
	for i in "${cross_compiler[@]}" ; do
		local arr=($i)

		for j in "${arr[@]}" ; do
			if [ ${j} = $1 ] ; then
				local arch=`echo ${arr[@]} | awk '{print $2}'`

				if [ ${arch} = $2 ] ; then
					LICHEE_ROOTFS=`echo ${arr[@]} | awk '{print $4}'`
				fi
			fi
		done
	done

	if [ "${LICHEE_LINUX_DEV}" == "ubuntu" ]; then
		#TODO: support different version
		LICHEE_ROOTFS='ubuntu-base-22.04.3-base-arm64.tar.bz2'
	fi

	if [ -z ${LICHEE_ROOTFS} ] ; then
		mk_error "can not match LICHEE_ROOTFS."
		exit 1
	fi
}


function parse_cross_compiler()
{
	for i in "${cross_compiler[@]}" ; do
		local arr=($i)

		for j in "${arr[@]}" ; do
			if [ ${j} = $1 ] ; then
				local arch=`echo ${arr[@]} | awk '{print $2}'`

				if [ ${arch} = $2 ] ; then
					LICHEE_COMPILER_TAR=$(echo $2 | sed 's/.*arm64.*/aarch64/g')/`echo ${arr[@]} | awk '{print $3}'`
				fi
			fi
		done
	done

	if [ -z ${LICHEE_COMPILER_TAR} ] ; then
		mk_error "can not match LICHEE_COMPILER_TAR."
		exit 1
	fi
}

function substitute_inittab()
{
	declare console
	if [ "x${LICHEE_PLATFORM}" = "xlinux" ]; then
		env_cfg_dir=${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/env.cfg
		if [ ! -f ${env_cfg_dir} ];then
			env_cfg_dir=${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_PLATFORM}/env.cfg
			if [ ! -f ${env_cfg_dir} ];then
				env_cfg_dir=${LICHEE_CHIP_CONFIG_DIR}/configs/default/env.cfg
			fi
		fi
	fi

	if [ "x${LICHEE_PLATFORM}" = "xandroid" ]; then
		env_cfg_dir=${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_PLATFORM}/env.cfg
		if [ ! -f ${env_cfg_dir} ];then
			env_cfg_dir=${LICHEE_CHIP_CONFIG_DIR}/configs/default/env.cfg
		fi
	fi

	if [ ! -f ${env_cfg_dir} ];then
		mk_info "not find env.cfg in ${env_cfg_dir}"
		return;
	fi

	console=$(grep -m1 -o ${env_cfg_dir} -e 'console=\w\+')
	console=$(sed -e 's/console=\(\w\+\).*/\1/g' <<< $console)

	if [ ${console} ]; then
		sed -ie "s/ttyS[0-9]*/${console}/g" $1
	fi

}

function get_android_top_path()
{
	local file cnt

	file=$LICHEE_TOP_DIR/../build/make/core/envsetup.mk
	if [ -f $file ]; then
		ANDROID_TOP_PATH=$(cd $LICHEE_TOP_DIR/.. && pwd)
		return 0
	fi
	file=$LICHEE_TOP_DIR/../*/build/make/core/envsetup.mk
	cnt=$(ls $file 2>/dev/null | wc -l)
	if [ $cnt -eq 0 ]; then
		mk_error "No android exsist, please check!"
	elif [ $cnt -eq 1 ]; then
		ANDROID_TOP_PATH=$(cd $(dirname $file)/../../.. && pwd)
		return 0
	else
		mk_error "Multi android exsist, please check!"
		exit 1
	fi
	unset ANDROID_TOP_PATH
}

function parse_boardconfig()
{
	check_env

	export LICHEE_CHIP_CONFIG_DIR=${LICHEE_DEVICE_DIR}/config/chips/${LICHEE_IC}
	export LICHEE_BOARD_CONFIG_DIR=${LICHEE_DEVICE_DIR}/config/chips/${LICHEE_IC}/configs/${LICHEE_BOARD}

	local default_config_android="${LICHEE_CHIP_CONFIG_DIR}/configs/default/BoardConfig_android.mk"
	local default_config_nor="${LICHEE_CHIP_CONFIG_DIR}/configs/default/BoardConfig_nor.mk"
	local default_config="${LICHEE_CHIP_CONFIG_DIR}/configs/default/BoardConfig.mk"

	local special_config_condition="${LICHEE_CHIP_CONFIG_DIR}/configs/default/BoardConfig-conditions.mk"
	local special_config_android="${LICHEE_BOARD_CONFIG_DIR}/android/BoardConfig.mk"
	local special_config_linux_nor="${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/BoardConfig_nor.mk"
	local special_config_linux="${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/BoardConfig.mk"
	local special_config="${LICHEE_BOARD_CONFIG_DIR}/BoardConfig.mk"
	local special_config_nor="${LICHEE_BOARD_CONFIG_DIR}/BoardConfig_nor.mk"

	local config_list=""
	# find BoardConfig.mk path
	# Note: Order is important in config_list
	if [ "x${LICHEE_PLATFORM}" = "xandroid" ]; then
		config_list=($default_config $default_config_android $special_config $special_config_android)
	elif [ "x${LICHEE_PLATFORM}" = "xlinux" ]; then
		config_list=($default_config $default_config_nor $special_config $special_config_linux $special_config_nor $special_config_linux_nor)
		[ ${LICHEE_FLASH} != "nor" ] && config_list=($default_config $special_config $special_config_linux)
	else
		mk_error "Unsupport LICHEE_PLATFORM!"
		exit 1
	fi

	> $LICHEE_OUT_DIR/BoardConfig-select.mk
	config_list+=($LICHEE_OUT_DIR/BoardConfig-select.mk)
	config_list+=($special_config_condition)

	local fetch_list=""
	local fpare_list=""
	for f in ${config_list[@]}; do
		if [ -f $f ]; then
			fetch_list=(${fetch_list[@]} $f)
			fpare_list="$fpare_list -f $f"
		fi
	done

	local v_cfg=""
	for f in ${config_list[@]}; do
		v_cfg=$(echo $f | sed "s|\.mk$|-${LICHEE_KERN_VER#*-}.mk|g")
		if [ -f $v_cfg ]; then
			fetch_list=(${fetch_list[@]} $v_cfg)
			fpare_list="$fpare_list -f $v_cfg"
		fi
	done

	if [ -z "${fetch_list[0]}" ]; then
		mk_error "BoardConfig not found!"
		exit 1
	fi

	export LICHEE_BOARDCONFIG_PATH="\"${fetch_list[@]}\""

	#parse BoardConfig.mk
	local cfgkey=""
	local cfgval=""
	local cfgenv=""
	local includes="--include-dir $LICHEE_TOP_DIR --include-dir $LICHEE_CHIP_CONFIG_DIR"

	if [ "x${LICHEE_PLATFORM}" = "xandroid" ]; then
		get_android_top_path
		[ -n "$ANDROID_TOP_PATH" ] && \
		includes+=" --include-dir $ANDROID_TOP_PATH"
	fi

	for cfgkey in ${selectconfig[@]}; do
		eval cfgval="$""$cfgkey"
		eval "$cfgkey='$cfgval'"
		[ "$cfgkey" == "LICHEE_KERN_VER" ] && [ -n "$cfgval" ] && LICHEE_KERN_VER="linux-${LICHEE_KERN_VER/linux-/}"
		[ -n "$cfgval" ] && echo "$cfgkey := $cfgval" >> $LICHEE_OUT_DIR/BoardConfig-select.mk
	done

	for cfgkey in ${boardconfig[@]}; do
		cfgval="$(echo '__unique:;@echo ${'"$cfgkey"'}' | make $includes -f - $fpare_list --no-print-directory __unique)"
		eval cfgenv="$""$cfgkey"
		if [ -n "$cfgenv" ] && [[ "${selectconfig[@]}"  =~ "$cfgkey" ]]; then
			eval "$cfgkey='$cfgenv'"
		else
			eval "$cfgkey='$cfgval'"
		fi
	done
	[ -n "$LICHEE_KERN_VER" ] && LICHEE_KERN_VER="linux-${LICHEE_KERN_VER/linux-/}"
	rm -rf ${LICHEE_OUT_DIR}/BoardConfig-select.mk
}

function parse_toolchain_and_rootfs()
{
	if [ -z ${LICHEE_COMPILER_TAR} ] ; then
		parse_cross_compiler ${LICHEE_KERN_VER} ${LICHEE_ARCH}
	fi
	if [ -z ${LICHEE_ROOTFS} ]; then
		parse_rootfs_tar ${LICHEE_KERN_VER} ${LICHEE_ARCH}
	fi
}

function save_config_to_buildconfig()
{
	local cfgkey=""
	local cfgval=""

	for cfgkey in ${allconfig[@]}; do
		[ "x$cfgkey" == "xCONFIG_SESSION_SEPARATE" ] && continue
		cfgval="$(eval echo '$'${cfgkey})"
		save_config "$cfgkey" "$cfgval" $BUILD_CONFIG
	done
}

function print_buildconfig()
{
	printf "printf .buildconfig:\n"
	cat ./.buildconfig
}

function print_config()
{
	echo "boardconfig:"
	for ((i=0;i<${#allconfig[@]};i++)); do
		[ "x${allconfig[$i]}" == "xCONFIG_SESSION_SEPARATE" ] && break
		echo "	${allconfig[$i]}=$(eval echo '$'"${allconfig[$i]}")"
	done

	echo "top directory:"
	for ((i++;i<${#allconfig[@]};i++)); do
		[ "x${allconfig[$i]}" == "xCONFIG_SESSION_SEPARATE" ] && break
		echo "	${allconfig[$i]}=$(eval echo '$'"${allconfig[$i]}")"
	done

	echo "config:"
	for ((i++;i<${#allconfig[@]};i++)); do
		[ "x${allconfig[$i]}" == "xCONFIG_SESSION_SEPARATE" ] && break
		echo "	${allconfig[$i]}=$(eval echo '$'"${allconfig[$i]}")"
	done

	echo "out directory:"
	for((i++;i<${#allconfig[@]};i++)); do
		echo "	${allconfig[$i]}=$(eval echo '$'"${allconfig[$i]}")"
	done
}

function select_ic()
{
	local val_list=$(list_subdir $LICHEE_DEVICE_DIR/config/chips)
	local cfg_key="LICHEE_IC"
	mk_select "$val_list" "$cfg_key"
}

function select_platform()
{
	local val_list="${platforms[@]}"
	local cfg_key="LICHEE_PLATFORM"
	mk_select "$val_list" "$cfg_key"
}

function select_linux_development()
{
	local val_list="${linux_development[@]}"
	local cfg_key="LICHEE_LINUX_DEV"

	[ -d $LICHEE_DRAGONABTS_DIR ] && \
	val_list="$val_list dragonabts"

	[ -d $LICHEE_DRAGONBAORD_DIR ] && \
	val_list="$val_list dragonboard"

	[ -d $LICHEE_SATA_DIR ] && \
	val_list="$val_list sata"

	[ -n "$(find $LICHEE_TOP_DIR/buildroot -maxdepth 1 -type d -name "buildroot-*" 2>/dev/null)" ] && \
	val_list="$val_list buildroot"

	[ -n "$(find $LICHEE_TOP_DIR/openwrt -maxdepth 1 -type d -name "openwrt*" 2>/dev/null)" ] && \
	val_list="$val_list openwrt"

	[ -n "$(find $LICHEE_TOP_DIR/device/config/rootfs_tar -maxdepth 1 -type f -name "ubuntu-base-*" 2>/dev/null)" ] && \
	val_list="$val_list ubuntu"

	mk_select "$val_list" "$cfg_key"
}

function select_sata_module()
{
	local val_list_all=$(list_subdir $LICHEE_SATA_DIR/linux/bsptest)
	local val_list="all"
	for val in $val_list_all;do
		if [ "x$val" != "xscript" -a "x$val" != "xconfigs" ];then
			val_list="$val_list $val"
		fi
	done
	local cfg_key="LICHEE_BTEST_MODULE"
	mk_select "$val_list" "$cfg_key"
}

function select_flash()
{
	local val_list="${flash[@]}"
	local cfg_key="LICHEE_FLASH"
	mk_select "$val_list" "$cfg_key"
}

function select_kern_ver()
{
	local val_list=$(list_subdir $LICHEE_TOP_DIR/kernel | grep "linux-")
	local cfg_key="LICHEE_KERN_NAME"

	mk_select "$val_list" "$cfg_key"

	LICHEE_KERN_VER=${LICHEE_KERN_NAME}
	if [[ ${LICHEE_KERN_NAME} == *_* ]]; then
		LICHEE_KERN_VER=${LICHEE_KERN_NAME%_*}
		LICHEE_KERN_TYPE=${LICHEE_KERN_NAME#*_}
	fi
}

function select_board()
{
	local val_list=$(list_subdir $LICHEE_DEVICE_DIR/config/chips/$LICHEE_IC/configs | grep -v default)
	local cfg_key="LICHEE_BOARD"
	mk_select "$val_list" "$cfg_key"
}

function select_arch()
{
	local val_list="${arch[@]}"
	local cfg_key="LICHEE_ARCH"
	mk_select "$val_list" "$cfg_key"

	if [ "x${LICHEE_ARCH}" = "xarm" ]; then
		LICHEE_KERNEL_ARCH=arm
	fi

	if [ "x${LICHEE_ARCH}" = "xarm64" ]; then
		LICHEE_KERNEL_ARCH=arm64
	fi

	save_config "LICHEE_KERNEL_ARCH" ${LICHEE_KERNEL_ARCH} $BUILD_CONFIG
}

function get_file_create_time()
{
	local file=$1;
	local date=""
	local time=""
	local create_time=""

	if [ -f ${file} ]; then
		date="`ls --full-time ${file} | cut -d ' ' -f 6`"
		time="`ls --full-time ${file} | cut -d ' ' -f 7`"
		create_time="${date} ${time}"

		printf "%s" "${create_time}"
	fi
}

function modify_longan_config()
{
	local LONGAN_CONFIG="${LICHEE_BR_OUT}/target/etc/longan.conf"
	local KERNEL_IMG="${KERNEL_STAGING_DIR}/uImage"
	local BUILDROOT_ROOTFS="${LICHEE_BR_OUT}/images/rootfs.ext4"
	local kernel_time=""
	local rootfs_time=""

	if [ -f ${LONGAN_CONFIG} ]; then
		kernel_time=$(get_file_create_time ${KERNEL_IMG})
		rootfs_time=$(get_file_create_time ${BUILDROOT_ROOTFS})

		#rootfs_time
		sed -i '/SYSTEM_VERSION/ s/$/ '"${rootfs_time}"'/g' ${LONGAN_CONFIG}
	fi
}

function build_buildroot_rootfs()
{
	mk_info "build buildroot ..."

	#build buildroot
	local build_script="build.sh"

	[ $? -ne 0 ] && mk_error "prepare toolchain Failed!" && return 1

	(cd ${LICHEE_BR_DIR} && [ -x ${build_script} ] && ./${build_script} $@)
	[ $? -ne 0 ] && mk_error "build buildroot Failed" && return 1

	#copy files to rootfs
	if [ -d ${LICHEE_BR_OUT}/target ]; then
		mk_info "copy the config files form device ..."
		if [ ! -e ${LICHEE_PLATFORM_DIR}/Makefile ]; then
			ln -fs ${LICHEE_BUILD_DIR}/Makefile  ${LICHEE_PLATFORM_DIR}/Makefile
		fi
		make -C ${LICHEE_PLATFORM_DIR}/ INSTALL_FILES
		[ $? -ne 0 ] && mk_error "copy the config files from device Failed" && return 1
	else
		mk_error "you nend build buildroot first!" && return 1
	fi

	modify_longan_config

	if [ ${LICHEE_LINUX_DEV} != "buildroot" ] ; then
		local rootfs_name=""

		if [ -n "`echo $LICHEE_KERN_VER | grep "linux-4.[49]"`" ]; then
			rootfs_name=target-${LICHEE_ARCH}-linaro-5.3.tar.bz2
		else
			rootfs_name=target_${LICHEE_ARCH}.tar.bz2
		fi

		mk_info "create rootfs tar ..."
		(cd ${LICHEE_BR_OUT}/target && tar -jcf ${rootfs_name} ./* && mv ${rootfs_name} ${LICHEE_DEVICE_DIR}/config/rootfs_tar)
	fi

	mk_info "build buildroot OK."
}

function clbuildroot()
{
	mk_info "clean buildroot ..."

	local build_script="build.sh"
	if [ -f ${LICHEE_BR_DIR} ]; then
		(cd ${LICHEE_BR_DIR} && [ -x ${build_script} ] && ./${build_script} "clean")
	fi

	mk_info "clean buildroot OK."
}

function prepare_buildserver()
{
	(
		cd $LICHEE_TOP_DIR/tools/build
		if [ -f buildserver ]; then
			mk_info "prepare_buildserver"
			./buildserver --path $LICHEE_TOP_DIR >/dev/null &
		fi
	)
}

function clbuildserver()
{
	local pidlist=($(lsof 2>/dev/null | awk '$9~"'$LICHEE_TOP_DIR/tools/build/buildserver'"{print $2}'))
	mk_info "clean buildserver"
	for pid in ${pidlist[@]}; do
		kill -9 $pid
	done
}

function prepare_toolchain()
{
	local ARCH=""
	local GCC=""
	local GCC_PREFIX=""
	local toolchain_archive=""
	local toolchain_archive_tmp=""
	local toolchain_archive_out=""
	local toolchain_archivedir=""
	local tooldir=""
	local boardconfig="${LICHEE_BOARDCONFIG_PATH}"

	if [ "${LICHEE_USE_INDEPENDENT_BSP}" == "true" ] && [ -d "${LICHEE_BSP_DIR}" ]; then
		export BSP_TOP=bsp/
	fi

	mk_info "Prepare toolchain ..."
	export PATH=${LICHEE_TOP_DIR}/prebuilt/hostbuilt/linux-x86/bin:$PATH
	export PATH=$PATH:${LICHEE_TOP_DIR}/build/bin

	if [ -f $LICHEE_KERN_DIR/scripts/build.sh ]; then
		KERNEL_BUILD_SCRIPT_DIR=$LICHEE_KERN_DIR
		KERNEL_BUILD_SCRIPT=scripts/build.sh
		KERNEL_BUILD_OUT_DIR=$LICHEE_KERN_DIR
		KERNEL_STAGING_DIR=$LICHEE_KERN_DIR/output
	else
		KERNEL_BUILD_SCRIPT_DIR=$LICHEE_BUILD_DIR
		KERNEL_BUILD_SCRIPT=mkkernel.sh
		KERNEL_BUILD_OUT_DIR=$LICHEE_OUT_DIR/$LICHEE_IC/kernel/build
		KERNEL_STAGING_DIR=$LICHEE_OUT_DIR/$LICHEE_IC/kernel/staging
		(
			cd $LICHEE_OUT_DIR
			rm -rf $LICHEE_OUT_DIR/kernel
			ln -sf $LICHEE_IC/kernel kernel
		)
	fi

	if [ -n "$ANDROID_CLANG_PATH" ] && [ ! -d $ANDROID_CLANG_PATH -o ${ANDROID_CLANG_PATH:0:1} != '/' ]; then
		local support_list=(longanstandalone longanforandroid longan)
		local longanstandalone_path_list=($(ls -d $LICHEE_TOP_DIR/prebuilts/clang/host/linux-x86 2>/dev/null))
		local longanforandroid_path_list=($(ls $LICHEE_TOP_DIR/../build/make/core/envsetup.mk 2>/dev/null))
		local longan_path_list=($(ls $LICHEE_TOP_DIR/../*/build/make/core/envsetup.mk 2>/dev/null))
		local build_system=""

		for s in ${support_list[@]}; do
			if [ -n "$(eval echo '$'{${s}_path_list[@]})" ]; then
				build_system=$s
				break
			fi
		done

		if [ -z "$build_system" ]; then
			mk_error "Error fetch build system for android!"
			exit 1
		fi

		local handle_path_list=($(echo "$(eval echo '$'{${build_system}_path_list[@]})" | xargs  readlink -f | xargs -n1 | sort | uniq))
		local clang_top_path=$(readlink -f $(dirname ${handle_path_list[0]})/../../..)

		[ ${#handle_path_list[@]} -gt 1 ] && \
		mk_warn "More than one $build_system project found, use first!"
		mk_info "$build_system project, clang_top_path: $clang_top_path"

		ANDROID_CLANG_PATH=$clang_top_path/$ANDROID_CLANG_PATH
		save_config "ANDROID_CLANG_PATH" "$ANDROID_CLANG_PATH" ${BUILD_CONFIG}

		if [ -z "$ANDROID_CLANG_ARGS" ]; then
			case "$LICHEE_KERN_VER" in
				linux-5.4)
					ANDROID_CLANG_ARGS="CC=clang HOSTCC=clang LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy LLVM=1 LLVM_IAS=1"
					;;
				linux-5.10)
					ANDROID_CLANG_ARGS="CC=clang HOSTCC=clang LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy LLVM=1"
					;;
				linux-5.15)
					ANDROID_CLANG_ARGS="CC=clang HOSTCC=clang LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy LLVM=1"
					ANDROID_CLANG_ARGS+=" HOSTLD=ld.lld"
					;;
				linux-6.1)
					ANDROID_CLANG_ARGS="CC=clang HOSTCC=clang LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy LLVM=1"
					ANDROID_CLANG_ARGS+=" HOSTLD=ld.lld"
					;;
				linux-6.6)
					ANDROID_CLANG_ARGS="CC=clang HOSTCC=clang LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy LLVM=1"
					ANDROID_CLANG_ARGS+=" HOSTLD=ld.lld"
					;;
			esac
		fi

		save_config "ANDROID_CLANG_ARGS" "\"$ANDROID_CLANG_ARGS\"" ${BUILD_CONFIG}

		if [ -n "$ANDROID_TOOLCHAIN_PATH" ]; then
			ANDROID_TOOLCHAIN_PATH=$clang_top_path/$ANDROID_TOOLCHAIN_PATH
			save_config "ANDROID_TOOLCHAIN_PATH" "$ANDROID_TOOLCHAIN_PATH" ${BUILD_CONFIG}
		fi

		if  [ ! -f "$ANDROID_CLANG_PATH/clang" ]; then
			mk_error "Cannot find android clang!"
			exit 1
		fi
		if [ -n "$ANDROID_TOOLCHAIN_PATH" ]; then
			if [ ! -d "$ANDROID_TOOLCHAIN_PATH" ]; then
				mk_error "Cannot find android toolchain!"
				exit 1
			fi
			return 0
		fi
	fi

	toolchain_archive=${LICHEE_COMPILER_TAR}
	toolchain_archivedir=${LICHEE_TOP_DIR}/prebuilt/kernelbuilt/${toolchain_archive}
	if [ ! -f ${toolchain_archivedir} ]; then
		mk_error "Prepare toolchain error!"
		exit 1
	fi

	toolchain_archive_out=${LICHEE_COMPILER_TAR##*/}
	toolchain_archive_tmp=${toolchain_archive_out%.*}
	tooldir=${LICHEE_OUT_DIR}/toolchain/${toolchain_archive_tmp%.*}

	if [ ! -d "${tooldir}" ]; then
		mkdir -p ${tooldir} || exit 1
		tar --strip-components=1 -xf ${toolchain_archivedir} -C ${tooldir} || exit 1
	fi

	GCC=$(find ${tooldir} -perm /a+x -a -regex '.*-gcc' | head -n 1);
	if [ -z "${GCC}" ]; then
		tar --strip-components=1 -xf ${toolchain_archivedir} -C ${tooldir} || exit 1
		GCC=$(find ${tooldir} -perm /a+x -a -regex '.*-gcc' | head -n 1);
	fi
	GCC_PREFIX=${GCC##*/};

	if [ "${tooldir}" == "${LICHEE_TOOLCHAIN_PATH}" \
		-a "${LICHEE_CROSS_COMPILER}-gcc" == "${GCC_PREFIX}" \
		-a -x "${GCC}" ]; then
		return
	fi

	if ! echo $PATH | grep -q "${tooldir}" ; then
		export PATH=${tooldir}/bin:$PATH
	fi

	LICHEE_CROSS_COMPILER="${GCC_PREFIX%-*}";

	if [ -n ${LICHEE_CROSS_COMPILER} ]; then
		export LICHEE_CROSS_COMPILER=${LICHEE_CROSS_COMPILER}
		export LICHEE_TOOLCHAIN_PATH=${tooldir}
		save_config "LICHEE_CROSS_COMPILER" "$LICHEE_CROSS_COMPILER" ${BUILD_CONFIG}
		save_config "LICHEE_TOOLCHAIN_PATH" "$tooldir" ${BUILD_CONFIG}
	fi
}

function prepare_dragonboard_toolchain()
{
	local ARCH="arm";
	local GCC="";
	local GCC_PREFIX="";
	local toolchain_archive="${LICHEE_TOP_DIR}/prebuilt/kernelbuilt/arm/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi.tar.xz";
	local tooldir="";

	mk_info "Prepare dragonboard toolchain ..."
	tooldir=${LICHEE_OUT_DIR}/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi/

	if [ ! -d "${tooldir}" ]; then
		mkdir -p ${tooldir} || exit 1
		tar --strip-components=1 -xf ${toolchain_archive} -C ${tooldir} || exit 1
	fi


	GCC=$(find ${tooldir} -perm /a+x -a -regex '.*-gcc');
	if [ -z "${GCC}" ]; then
		tar --strip-components=1 -xf ${toolchain_archive} -C ${tooldir} || exit 1
		GCC=$(find ${tooldir} -perm /a+x -a -regex '.*-gcc');
	fi
	GCC_PREFIX=${GCC##*/};

	if [ "${tooldir}" == "${LICHEE_TOOLCHAIN_PATH}" \
		-a "${LICHEE_CROSS_COMPILER}-gcc" == "${GCC_PREFIX}" \
		-a -x "${GCC}" ]; then
		return
	fi

	if ! echo $PATH | grep -q "${tooldir}" ; then
		export PATH=${tooldir}/bin:$PATH
	fi


	LICHEE_CROSS_COMPILER="${GCC_PREFIX%-*}";

	if [ -n ${LICHEE_CROSS_COMPILER} ]; then
		export LICHEE_CROSS_COMPILER=${LICHEE_CROSS_COMPILER}
		export LICHEE_TOOLCHAIN_PATH=${tooldir}
	fi
}

function build_dragonboard_rootfs()
{
	if [ -d ${LICHEE_DRAGONBAORD_DIR} ]; then
		echo "Regenerating dragonboard Rootfs..."
		(
			cd ${LICHEE_DRAGONBAORD_DIR}; \
				if [ ! -d "./rootfs" ]; then \
					echo "extract dragonboard rootfs.tar.gz"; \
					tar zxf ./common/rootfs/rootfs.tar.gz; \
				fi
		)
		mkdir -p ${LICHEE_DRAGONBAORD_DIR}/rootfs/lib/modules
		rm -rf ${LICHEE_DRAGONBAORD_DIR}/rootfs/lib/modules/*
		cp -rf ${KERNEL_STAGING_DIR}/lib/modules/* ${LICHEE_DRAGONBAORD_DIR}/rootfs/lib/modules/
		(cd ${LICHEE_DRAGONBAORD_DIR}/common/scripts; ./build.sh)
		[  $? -ne 0 ] && mk_error "build rootfs Failed" && return 1
		cp ${LICHEE_DRAGONBAORD_DIR}/rootfs.ext4 ${LICHEE_PLAT_OUT}
		cp ${LICHEE_DRAGONBAORD_DIR}/rootfs.ubifs ${LICHEE_PLAT_OUT}
	else
		mk_error "no ${LICHEE_PLATFORM} in lichee,please git clone it under lichee"
		exit 1
	fi
}

function prepare_dragonabts_toolchain()
{
	local gcc="";
	local gcc_prefix="";
	local toolchain_archive="${LICHEE_TOP_DIR}/prebuilt/kernelbuilt/arm/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi.tar.xz";
	local tooldir="";

	mk_info "Prepare dragonabts toolchain ..."
	tooldir=${LICHEE_OUT_DIR}/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi/

	if [ ! -d "${tooldir}" ]; then
		mkdir -p ${tooldir} || exit 1
		tar --strip-components=1 -xf ${toolchain_archive} -C ${tooldir} || exit 1
	fi


	gcc=$(find ${tooldir} -perm /a+x -a -regex '.*-gcc');
	if [ -z "${gcc}" ]; then
		tar --strip-components=1 -xf ${toolchain_archive} -C ${tooldir} || exit 1
		gcc=$(find ${tooldir} -perm /a+x -a -regex '.*-gcc');
	fi
	gcc_prefix=${gcc##*/};

	if [ "${tooldir}" == "${LICHEE_TOOLCHAIN_PATH}" \
		-a "${LICHEE_CROSS_COMPILER}-gcc" == "${gcc_prefix}" \
		-a -x "${gcc}" ]; then
		return
	fi

	if ! echo $PATH | grep -q "${tooldir}" ; then
		export PATH=${tooldir}/bin:$PATH
	fi


	LICHEE_CROSS_COMPILER="${GCC_PREFIX%-*}";

	if [ -n ${LICHEE_CROSS_COMPILER} ]; then
		export LICHEE_CROSS_COMPILER=${LICHEE_CROSS_COMPILER}
		export LICHEE_TOOLCHAIN_PATH=${tooldir}
	fi
}


function build_dragonabts_rootfs()
{
	if [ -d ${LICHEE_DRAGONABTS_DIR} ]; then
		echo "Regenerating dragonabts Rootfs..."
		(
			cd ${LICHEE_DRAGONABTS_DIR}; \
				if [ ! -d "./rootfs" ]; then \
					echo "extract dragonabts rootfs.tar.gz"; \
					tar zxf ./common/rootfs/rootfs.tar.gz; \
				fi
		)
		mkdir -p ${LICHEE_DRAGONABTS_DIR}/rootfs/lib/modules
		rm -rf ${LICHEE_DRAGONABTS_DIR}/rootfs/lib/modules/*
		cp -rf ${KERNEL_STAGING_DIR}/lib/modules/* ${LICHEE_DRAGONABTS_DIR}/rootfs/lib/modules/
		(cd ${LICHEE_DRAGONABTS_DIR}/common/scripts; ./build.sh)
		[  $? -ne 0 ] && mk_error "build rootfs Failed" && return 1
		cp ${LICHEE_DRAGONABTS_DIR}/rootfs.ext4 ${LICHEE_PLAT_OUT}
		cp ${LICHEE_DRAGONABTS_DIR}/rootfs.ubifs ${LICHEE_PLAT_OUT}
	else
		mk_error "no ${LICHEE_PLATFORM} in lichee,please git clone it under lichee"
		exit 1
	fi
}

function prepare_mkkernel()
{
	# mark kernel .config belong to which platform
	local config_mark="${KERNEL_BUILD_OUT_DIR}/.config.mark"
	local board_dts="$LICHEE_BOARD_CONFIG_DIR/board.dts"

	# setup bsp code to kernel
	bsp_action setup

	board_dts_create_link

	if [ "x${LICHEE_USE_INDEPENDENT_BSP}" != "xtrue" ] && [ -f ${board_dts} ]; then
		if [ "x${LICHEE_ARCH}" == "xarm64" ] || [ "x${LICHEE_ARCH}" == "xriscv64" ]; then
			cp $board_dts ${LICHEE_KERN_DIR}/arch/${LICHEE_KERNEL_ARCH}/boot/dts/sunxi/board.dts
		else
			cp $board_dts ${LICHEE_KERN_DIR}/arch/${LICHEE_KERNEL_ARCH}/boot/dts/board.dts
		fi
	fi
	if [ -f ${config_mark} ] ; then
		local tmp=`cat ${config_mark}`
		local tmp1="${LICHEE_CHIP}_${LICHEE_BOARD}_${LICHEE_PLATFORM}"
		if [ ${tmp} != ${tmp1} ] ; then
			mk_info "clean last time build for different platform"
			if [ "x${LICHEE_KERN_DIR}" != "x" -a -d ${LICHEE_KERN_DIR} ]; then
				(cd ${KERNEL_BUILD_SCRIPT_DIR} && [ -x ${KERNEL_BUILD_SCRIPT} ] && ./${KERNEL_BUILD_SCRIPT} "distclean")
				rm -rf ${KERNEL_BUILD_OUT_DIR}/.config
				echo "${LICHEE_CHIP}_${LICHEE_BOARD}_${LICHEE_PLATFORM}" > ${config_mark}
			fi
		fi
	else
		echo "${LICHEE_CHIP}_${LICHEE_BOARD}_${LICHEE_PLATFORM}" > ${config_mark}
	fi
}

function build_dts()
{
	mk_info "build dts ..."
	local build=$1

	prepare_toolchain
	prepare_mkkernel

	# Do not compile dts again, process the compiled files related to dts
	[ "$build" != "false" ] && \
	(cd ${KERNEL_BUILD_SCRIPT_DIR} && [ -x ${KERNEL_BUILD_SCRIPT} ] && ./${KERNEL_BUILD_SCRIPT} dts)

	if [ "x$LICHEE_KERN_VER" != "xlinux-3.4" ]; then
		cp ${KERNEL_BUILD_OUT_DIR}/scripts/dtc/dtc ${LICHEE_PLAT_OUT}
		local dts_path=$KERNEL_BUILD_OUT_DIR/arch/${LICHEE_ARCH}/boot/dts
		[ "x${LICHEE_ARCH}" == "xarm64" ] && \
		dts_path=$dts_path/sunxi

		local copy_list=(
			$dts_path/.${LICHEE_CHIP}-*.dtb.d.dtc.tmp:${LICHEE_PLAT_OUT}
			$dts_path/.${LICHEE_CHIP}-*.dtb.dts.tmp:${LICHEE_PLAT_OUT}
			$dts_path/.board.dtb.d.dtc.tmp:${LICHEE_PLAT_OUT}
			$dts_path/.board.dtb.dts.tmp:${LICHEE_PLAT_OUT}
			${KERNEL_STAGING_DIR}/.sunxi.dts:${LICHEE_PLAT_OUT}
			${KERNEL_STAGING_DIR}/sunxi.dtb:${LICHEE_PLAT_OUT}
		)

		rm -vf ${LICHEE_PLAT_OUT}/.board.dtb.*.tmp ${LICHEE_PLAT_OUT}/board.dtb
		for e in ${copy_list[@]}; do
			cp -vf ${e/:*} ${e#*:} 2>/dev/null
		done
	fi

	# delete board.dts
	if [ "x${LICHEE_ARCH}" == "xarm64" ]; then
		if [ -f ${LICHEE_KERN_DIR}/arch/${LICHEE_ARCH}/boot/dts/sunxi/board.dts ]; then
			rm ${LICHEE_KERN_DIR}/arch/${LICHEE_ARCH}/boot/dts/sunxi/board.dts
		fi
	else
		if [ -f ${LICHEE_KERN_DIR}/arch/${LICHEE_ARCH}/boot/dts/board.dts ];then
			rm ${LICHEE_KERN_DIR}/arch/${LICHEE_ARCH}/boot/dts/board.dts
		fi
	fi
}

# Actually we compiled booth the kernel + driver-modules + dts that need to be compiled separately
# From users, it is not necessary to separate the compilation of this three into two separate processes.
function build_kernel()
{
	mk_info "build kernel ..."

	prepare_buildserver
	prepare_toolchain
	prepare_mkkernel

	# compile dts togther
	(cd ${KERNEL_BUILD_SCRIPT_DIR} && [ -x ${KERNEL_BUILD_SCRIPT} ] && ./${KERNEL_BUILD_SCRIPT} $@)
	[ $? -ne 0 ] && mk_error "build $1 Failed" && return 1

	# copy files related to pack to platform out
	cp ${KERNEL_BUILD_OUT_DIR}/vmlinux ${LICHEE_PLAT_OUT}

	# dts real build in this function
	build_dts false $@
	if [ $? -ne 0 ]; then
		mk_info "build dts failed"
		exit 1
	fi
}


function build_bootimg()
{
	mk_info "build bootimg ..."
	prepare_toolchain
	prepare_mkkernel

	(cd ${KERNEL_BUILD_SCRIPT_DIR} && [ -x ${KERNEL_BUILD_SCRIPT} ] && ./${KERNEL_BUILD_SCRIPT} bootimg)
	if [ $? -ne 0 ]; then
		mk_error "---build $1 Failed---"
		exit 1
	fi
}

function gki_extract_symbols_check()
{
	local flag=0

	[ "$LICHEE_PLATFORM" != "android" ] && return 0

	for i in "${gki_check_whitelist[@]}"; do
		local arr=($i)
		if [[ "${LICHEE_IC}" == "${arr[0]}" ]] && [[ "${arr[1]}" =~ "${LICHEE_KERN_VER}" ]]; then
			mk_info "gki extract symbols check ..." && flag=1 && break
		fi
	done
	[ "$flag" != 1 ] && return 0

	cd ${LICHEE_BUILD_DIR}
	ANDROID_MODULES_PATH="$LICHEE_OUT_DIR/$LICHEE_IC/kernel/staging/lib/modules/"
	if [ -f ${LICHEE_TOP_DIR}/../vendor/gki/vmlinux ] ; then
		cp ${LICHEE_TOP_DIR}/../vendor/gki/vmlinux ${ANDROID_MODULES_PATH}/vmlinux
	else
		mk_error "---can' find gki vmlinux---"
		exit 1
	fi

	[ -f extract_symbols ] && [ -x extract_symbols ] && EXTRACT_SYMBOLS=extract_symbols
	unknown_symbol_list=$(./${EXTRACT_SYMBOLS} --whitelist ${LICHEE_PLAT_OUT}/aw.whitelist ${ANDROID_MODULES_PATH})
	if [ -n "${unknown_symbol_list}" ]; then
		mk_error "GKI CHECK FAILED"
		echo "$unknown_symbol_list"
		mk_info "Please confirm whether the not provided symbol in the mentioned .ko file are necessary for use"
		rm ${ANDROID_MODULES_PATH}/vmlinux
		exit 1
	else
		mk_info "GKI CHECK SUCCESS"
		rm ${ANDROID_MODULES_PATH}/vmlinux
		return 0
	fi
}

function mkrecovery()
{
	mk_info "build recovery ..."

	local build_script="scripts/build.sh"

	LICHEE_KERN_SYSTEM="kernel_recovery"

	prepare_toolchain

	prepare_mkkernel

	(cd ${KERNEL_BUILD_SCRIPT_DIR} && [ -x ${KERNEL_BUILD_SCRIPT} ] && ./${KERNEL_BUILD_SCRIPT} $@)

	[ $? -ne 0 ] && mk_error "build kernel Failed" && return 1

	mk_info "build recovery OK."

	#delete .config
	rm -rf ${LICHEE_OUT_DIR}/${LICHEE_IC}/kernel/build/.config

	#delete board.dts
	if [ "x${LICHEE_ARCH}" == "xarm64" ]; then
		if [ -f ${LICHEE_KERN_DIR}/arch/${LICHEE_ARCH}/boot/dts/sunxi/board.dts ]; then
			rm ${LICHEE_KERN_DIR}/arch/${LICHEE_ARCH}/boot/dts/sunxi/board.dts
		fi
	else
		if [ -f ${LICHEE_KERN_DIR}/arch/${LICHEE_ARCH}/boot/dts/board.dts ];then
			rm ${LICHEE_KERN_DIR}/arch/${LICHEE_ARCH}/boot/dts/board.dts
		fi
	fi
}

function mk_ramfs()
{
	local clarg="ramfs"
	local action=$1
	local src=$2
	local dst=$3

	mk_info "mk_ramfs ..."

	prepare_toolchain
	(cd ${KERNEL_BUILD_SCRIPT_DIR} && [ -x ${KERNEL_BUILD_SCRIPT} ] && ./${KERNEL_BUILD_SCRIPT} "$clarg" "$action" "$src" "$dst")

	mk_info "mk_ramfs OK."
}

function clkernel()
{
	local clarg="clean"

	if [ "x$1" == "xdistclean" ]; then
		clarg="distclean"
	fi

	mk_info "clean kernel ..."

	prepare_toolchain

	(cd ${KERNEL_BUILD_SCRIPT_DIR} && [ -x ${KERNEL_BUILD_SCRIPT} ] && ./${KERNEL_BUILD_SCRIPT} "$clarg")

	mk_info "clean kernel OK."
}

function cldragonboard()
{
	if  [ "x$LICHEE_PLATFORM" == "xlinux" ] && \
		[ "x$LICHEE_LINUX_DEV" == "xdragonboard" ] && \
		[ -n "$(ls $LICHEE_PLAT_OUT)" ]; then
		mk_info "clean dragonboard ..."

		local script_dir="${LICHEE_DRAGONBAORD_DIR}/common/scripts/"

		local clean_script="clean.sh"
		(cd ${script_dir} && [ -x ${clean_script} ] && ./${clean_script})

		mk_info "clean dragonboard OK."
	fi
}

function get_newest_file()
{
    # find the newest file in $1
    find $1 -type f -and -not -path "*/.git*" -and -not -path ".*" -and -not -path "*:*" -and -not -path "*\!*" -and -not -path "* *" -and -not -path "*\#*" -and -not -path "*/.*_check" -and -not -path "*/.*.swp" -and -not -path "*/.newest-*.patch" -printf "%T@   %Tc   %p\n" | sort -n | tail -n 1
}

function detect_rebuild()
{
    # arg1: dst dir path
    local newest_file=`get_newest_file $1`
    local rebuild_flag=`echo "$newest_file $LICHEE_IC $LICHEE_BOARD $LICHEE_ARCH" | md5sum | awk '{print ".newest-"$1".patch"}'`
    echo $rebuild_flag
}

function update_rebuild_flag()
{
    local newest_file=
    local rebuild_flag=

    # arg1: dst dir path
    [ ! -d $1 ] && return 0

    rm -rf $1/.newest-*.patch
    newest_file=`get_newest_file $1`
    rebuild_flag=`echo "$newest_file $LICHEE_IC $LICHEE_BOARD $LICHEE_ARCH" | md5sum | awk '{print ".newest-"$1".patch"}'`
    touch $1/$rebuild_flag
}

function build_bootloader()
{
	local CURDIR=$PWD
	local brandy_path=""
	local build_script="build.sh"

	local BOOT0_REBUILD_FLAG=
	local BOOT0_PUB_REBUILD_FLAG=
	local UBOOT_REBUILD_FLAG=
	local UBOOT_BSP_REBUILD_FLAG=
	local DRAM_REBUILD_FLAG=

	local build_flag=0
	local o_option=
	local u_uboot=2018

	# arg1: o_option, build target, such as spl,uboot,all
	# arg2: force, means force build without build_flag check

	if [ ${LICHEE_BRANDY_VER} = "1.0" ] ; then
		brandy_path=${LICHEE_BRANDY_DIR}/brandy
	elif [ ${LICHEE_BRANDY_VER} = "2.0" ] ; then
		brandy_path=${LICHEE_BRANDY_DIR}
	else
		echo "unkown brandy version, version=${LICHEE_BRANDY_VER}"
		exit 1;
	fi

	[ -z "$LICHEE_BRANDY_DEFCONF" ] && \
	mk_info "No need to build brandy." && \
	return 0

	# build brandy-1.0
	if [ ${LICHEE_BRANDY_VER} = "1.0" ] ; then
		brandy_path=${LICHEE_BRANDY_DIR}/brandy

		(cd ${brandy_path} && [ -x ${build_script} ] && ./${build_script} -t)
		[ $? -ne 0 ] && mk_error "prepare toolchain Failed" && return 1

		(cd ${brandy_path} && [ -x ${build_script} ] && ./${build_script} -p ${LICHEE_CHIP} -d ${LICHEE_BRANDY_OUT_DIR})
		[ $? -ne 0 ] && mk_error "build brandy-1.0 Failed" && return 1

		mk_info "build brandy-1.0 OK."
		cd $CURDIR
		return 0;
	fi

	[ x"$1" != x"" ] && o_option=$1
	[ x"$LICHEE_BRANDY_UBOOT_VER" != x"" ] && u_uboot=$LICHEE_BRANDY_UBOOT_VER

	BOOT0_REBUILD_FLAG=`detect_rebuild $LICHEE_TOP_DIR/brandy/brandy-2.0/spl`
	BOOT0_PUB_REBUILD_FLAG=`detect_rebuild $LICHEE_TOP_DIR/brandy/brandy-2.0/spl-pub`
	UBOOT_REBUILD_FLAG=`detect_rebuild $LICHEE_TOP_DIR/brandy/brandy-2.0/u-boot-$u_uboot`
	UBOOT_BSP_REBUILD_FLAG=`detect_rebuild $LICHEE_TOP_DIR/brandy/brandy-2.0/u-boot-bsp`
	DRAM_REBUILD_FLAG=`detect_rebuild $LICHEE_TOP_DIR/brandy/dramlib`

	# build brandy-2.0 or higher
	mk_info "build_bootloader: brandy_path=${brandy_path}"
	if [ ! -f $LICHEE_TOP_DIR/brandy/brandy-2.0/u-boot-$u_uboot/$UBOOT_REBUILD_FLAG ];then
		build_flag=1
	fi

	if [ $u_uboot -gt "2018" ];then
		if [ ! -f $LICHEE_TOP_DIR/brandy/brandy-2.0/u-boot-bsp/$UBOOT_BSP_REBUILD_FLAG ];then
			build_flag=1
		fi
	fi

	if [ -d $LICHEE_BOARD_CONFIG_DIR/uboot-$u_uboot -a \
		$LICHEE_TOP_DIR/brandy/brandy-2.0/u-boot-$u_uboot/$UBOOT_REBUILD_FLAG -ot \
		$LICHEE_BOARD_CONFIG_DIR/uboot-$u_uboot/uboot-board.dts ];then
		build_flag=1
		mk_info "uboot-$u_uboot/uboot-board.dts updated."
	elif [ $LICHEE_TOP_DIR/brandy/brandy-2.0/u-boot-$u_uboot/$UBOOT_REBUILD_FLAG -ot \
		$LICHEE_BOARD_CONFIG_DIR/uboot-board.dts ];then
		build_flag=1
		mk_info "uboot-board.dts updated."
	fi

	if [ -d $LICHEE_TOP_DIR/brandy/brandy-2.0/spl -a \
        ! -f $LICHEE_TOP_DIR/brandy/brandy-2.0/spl/$BOOT0_REBUILD_FLAG ];then
		build_flag=1
	fi

	if [ -d $LICHEE_TOP_DIR/brandy/brandy-2.0/spl-pub -a \
        ! -f $LICHEE_TOP_DIR/brandy/brandy-2.0/spl-pub/$BOOT0_PUB_REBUILD_FLAG ];then
		build_flag=1
	fi

	if [ -d $LICHEE_TOP_DIR/brandy/dramlib/ -a \
        ! -f $LICHEE_TOP_DIR/brandy/dramlib/$DRAM_REBUILD_FLAG ];then
		build_flag=1
	fi

	[ x"$2" = x"force" ] && build_flag=1

	# if there is no modification in uboot, do not rebuild uboot
	if [ x"$build_flag" != x"1" ];then
		mk_info "skip build brandy."
		cd $CURDIR
		return 0;
	fi

	# build bootloader
	local build_option="-p ${LICHEE_BRANDY_DEFCONF%%_def*} -b ${LICHEE_IC} "
	if [ x"$o_option" != x"" ];then
		build_option+="-o ${o_option} "
	fi
	if [ x"$u_uboot" != x"" -a x"$u_uboot" != x"2018" ];then
		build_option+="-u ${u_uboot} "
	fi
	echo "build_option:${build_option}"
	(cd ${brandy_path} && [ -x ${build_script} ] && ./${build_script} ${build_option})
	[ $? -ne 0 ] && mk_error "build brandy Failed" && return 1

	update_rebuild_flag $LICHEE_TOP_DIR/brandy/brandy-2.0/u-boot-$u_uboot
	update_rebuild_flag $LICHEE_TOP_DIR/brandy/brandy-2.0/spl
	update_rebuild_flag $LICHEE_TOP_DIR/brandy/brandy-2.0/spl-pub
	update_rebuild_flag $LICHEE_TOP_DIR/brandy/dramlib

	mk_info "build brandy OK."

	cd $CURDIR
}

function clbrandy()
{
	mk_info "clean brandy ..."
	(cd $LICHEE_BRANDY_DIR && ./build.sh -o clean)
	mk_info "clean brandy ok"
}

function update_bin_path()
{
	local PACK_PLATFORM=$LICHEE_PLATFORM
	[ "x${LICHEE_PLATFORM}" != "xandroid" ] && PACK_PLATFORM=$LICHEE_LINUX_DEV

	local possible_bin_path=(
		bin
		${LICHEE_BUSSINESS}/bin
		configs/${LICHEE_BOARD}/bin
		configs/${LICHEE_BOARD}/${LICHEE_BUSSINESS}/bin
		configs/${LICHEE_BOARD}/${PACK_PLATFORM}/bin
		configs/${LICHEE_BOARD}/${PACK_PLATFORM}/${LICHEE_BUSSINESS}/bin
	)
	export LICHEE_POSSIBLE_BIN_PATH="\"${possible_bin_path[@]}\""
	save_config "LICHEE_POSSIBLE_BIN_PATH" "$LICHEE_POSSIBLE_BIN_PATH" ${BUILD_CONFIG}
}

function copy_bin_firmware()
{
	local BIN_PATH=""
	local amp_bin_list=(
		${LICHEE_CHIP_CONFIG_DIR}/\${BIN_PATH}/amp_dsp0.bin:$1/amp_dsp0.bin
		${LICHEE_CHIP_CONFIG_DIR}/\${BIN_PATH}/amp_dsp1.bin:$1/amp_dsp1.bin
		${LICHEE_CHIP_CONFIG_DIR}/\${BIN_PATH}/amp_rv0.bin:$1/amp_rv0.bin
	)

	mk_info "start copy firmware to $1"

	update_bin_path

	mkdir -p $1

	for d in ${LICHEE_POSSIBLE_BIN_PATH[@]}; do
		[ ! -d ${LICHEE_CHIP_CONFIG_DIR}/$d ] && continue
		BIN_PATH=$d
		for file in ${amp_bin_list[@]} ; do
			eval cp -v -f $(echo $file | sed -e 's/:/ /g') 2>/dev/null
		done
	done

	mk_info "copy firmware to $1 ok ..."
}

function build_sata()
{
	if [ "x$LICHEE_LINUX_DEV" = "xsata" ];then
		clsata
		mk_info "build sata ..."

		local build_script="linux/bsptest/script/bsptest.sh"
		local sata_config="${LICHEE_SATA_DIR}/linux/bsptest/script/Config"
		. ${sata_config}
		[ "x$LICHEE_BTEST_MODULE" = "x" ] && LICHEE_BTEST_MODULE="all"

		(cd ${LICHEE_SATA_DIR} && [ -x ${build_script} ] && ./${build_script} -b $LICHEE_BTEST_MODULE)

		[ $? -ne 0 ] && mk_error "build sata Failed" && return 1
		mk_info "build sata OK."

		(cd ${LICHEE_SATA_DIR} && [ -x ${build_script} ] && ./${build_script} -s $LICHEE_BTEST_MODULE)
	fi
}

function clsata()
{
	mk_info "clear sata ..."

	local build_script="linux/bsptest/script/bsptest.sh"
	(cd ${LICHEE_SATA_DIR} && [ -x ${build_script} ] && ./${build_script} -b clean)

	mk_info "clean sata OK."
}

function mk_tinyandroid()
{
	local ROOTFS=${LICHEE_PLAT_OUT}/rootfs_tinyandroid

	mk_info "Build tinyandroid rootfs ..."
	if [ "$1" = "f" ]; then
		rm -fr ${ROOTFS}
	fi

	if [ ! -f ${ROOTFS} ]; then
		mkdir -p ${ROOTFS}
		tar -jxf ${LICHEE_DEVICE_DIR}/config/rootfs_tar/tinyandroid_${LICHEE_ARCH}.tar.bz2 -C ${ROOTFS}
	fi

	mkdir -p ${ROOTFS}/lib/modules
	cp -rf ${KERNEL_STAGING_DIR}/lib/modules/* \
		${ROOTFS}/lib/modules/

	if [ "x$PACK_BSPTEST" != "x" ];then
		if [ -d ${ROOTFS}/target ];then
 			rm -rf ${ROOTFS}/target/*
		fi
		if [ -d ${LICHEE_SATA_DIR}/linux/target ]; then
			mk_info "copy SATA rootfs_def"
			cp -a ${LICHEE_SATA_DIR}/linux/target  ${ROOTFS}/
		fi
	fi

	NR_SIZE=`du -sm ${ROOTFS} | awk '{print $1}'`
	NEW_NR_SIZE=$(((($NR_SIZE+32)/16)*16))

	echo "blocks: $NR_SIZE"M" -> $NEW_NR_SIZE"M""
	${LICHEE_BUILD_DIR}/bin/make_ext4fs -l \
		$NEW_NR_SIZE"M" ${LICHEE_PLAT_OUT}/rootfs.ext4 ${ROOTFS}
	fsck.ext4 -y ${LICHEE_PLAT_OUT}/rootfs.ext4 > /dev/null
}

# build rootfs.squashfs for spinor
function make_squashfs()
{
	local target_rootfs=$1

	fakeroot ${LICHEE_BUILD_DIR}/bin/mksquashfs \
	${target_rootfs} ${LICHEE_PLAT_OUT}/rootfs.squashfs -root-owned -no-progress -comp xz -noappend
}

# build rootfs.ubifs for nand
function make_ubifs()
{
	local target_rootfs=$1

	if [ -n "`echo $LICHEE_KERN_VER | grep "linux-[34].[149]"`" ] ||
	   [ "x${LICHEE_KERN_VER}" = "xlinux-5.4" ]
	then
		fakeroot ${LICHEE_BUILD_DIR}/bin/mkfs.ubifs \
			-m 4096 -e 258048 -c 375 -F -x zlib -r ${target_rootfs} -o ${LICHEE_PLAT_OUT}/rootfs.ubifs
	else
		fakeroot ${LICHEE_BUILD_DIR}/bin/mkfs.ubifs \
			-m 2048 -e 126976 -c 375 -F -x zlib -r ${target_rootfs} -o ${LICHEE_PLAT_OUT}/rootfs.ubifs
	fi
}

function make_2img()
{
	local target_rootfs=$1

	fakeroot mke2img -d ${target_rootfs} -G 4 -R 1 -B 0 -I 0 -o ${LICHEE_PLAT_OUT}/rootfs.ext4
}

function make_ext4()
{
	local target_rootfs=$1

	PARTITION_FEX=${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/sys_partition.fex

	echo "PARTITION_FEX=$PARTITION_FEX"
	ROOTFS_FEX_LINE=`awk "/rootfs.fex/{print NR}" $PARTITION_FEX |head -n1`
	echo "ROOTFS_FEX_LINE=$ROOTFS_FEX_LINE"
	ROOTFS_FEX_STR=$(awk "NR==${ROOTFS_FEX_LINE}-1 {print $NF}" $PARTITION_FEX)
	echo "ROOTFS_FEX_STR=${ROOTFS_FEX_STR}"
	ROOTFS_FEX_SIZE=$(echo $ROOTFS_FEX_STR |  cut -d "=" -f 2)
	if [ -z ${ROOTFS_FEX_SIZE} ]; then
	#use default rootfs partitions size 1GB
		ROOTFS_FEX_SIZE=2097152
		echo "can't find rootfs size in sys_partition.fex, use default $ROOTFS_FEX_SIZE"
	fi
	echo "ROOTFS_FEX_SIZE=$ROOTFS_FEX_SIZE"
	EXT4_SIZE=$(expr $ROOTFS_FEX_SIZE \* 512)
	echo "EXT4_SIZE=$EXT4_SIZE(`expr $EXT4_SIZE/1024/1024`)"

	echo "$PARTITION_FEX rootfs.fex size is $ROOTFS_FEX_SIZE"
	echo "EXT4_SIZE=$ROOTFS_FEX_SIZE*512=$EXT4_SIZE"

	$LICHEE_BUILD_DIR/bin/make_ext4fs -s -l $EXT4_SIZE ${LICHEE_PLAT_OUT}/rootfs.ext4  ${target_rootfs}
	echo "$LICHEE_BUILD_DIR/bin/make_ext4fs -s -l $EXT4_SIZE ${LICHEE_PLAT_OUT}/rootfs.ext4  ${target_rootfs}"
}

function build_bsp_rootfs()
{
	local ROOTFS=${LICHEE_PLAT_OUT}/rootfs_def
	local ROOTFS_FIRWMARE_PATH=${ROOTFS}/lib/firmware
	local INODES=""
	local BLOCKS=""
	local rootfs_archive=""
	local rootfs_archivedir=""
	local boardconfig="${LICHEE_BOARDCONFIG_PATH}"
	local main_version=${LICHEE_KERN_VER/.*/}
	local sub_version=${LICHEE_KERN_VER/*./}
	main_version=${main_version/linux-}

	#rootfs_archive=`cat ${boardconfig} | grep -w "LICHEE_ROOTFS" | awk -F= '{printf $2}'`
	rootfs_archive=${LICHEE_ROOTFS}
	rootfs_archivedir=${LICHEE_DEVICE_DIR}/config/rootfs_tar/${rootfs_archive}
	mk_info "Build default rootfs ..."
	if [ "$1" = "f" ]; then
		rm -fr ${ROOTFS}
	fi

	# bsp uses the compressed file system, just decompress them here,
	# but starting from gcc-10.3, use the extracted folder to directly copy
	if [ ! -d ${ROOTFS} ]; then
		mkdir -p ${ROOTFS}
		if [ -d ${rootfs_archivedir} ]; then
			cp -r ${rootfs_archivedir}/* ${ROOTFS}
		elif [ -f ${rootfs_archivedir} ]; then
			fakeroot tar -jxf ${rootfs_archivedir} -C ${ROOTFS}
		else
			mk_error "cann't find ${rootfs_archive}"
		fi
	fi

	# the following operation is similar to the pack_buildroot_rootfs() -> copy the ko and others that systenm need
	rm -rf ${ROOTFS}/lib/modules
	mkdir -p ${ROOTFS}/lib/modules
	cp -rf ${KERNEL_STAGING_DIR}/lib/modules/* \
		${ROOTFS}/lib/modules/
	if [[ "$main_version" > "5" ]] || [[ "$main_version" == "5" ]] && [[ "$sub_version" -ge "10" ]]; then
		cp ${LICHEE_CHIP_CONFIG_DIR}/configs/default/${LICHEE_KERN_VER}/S50module ${ROOTFS}/etc/init.d/
	else
		cp ${LICHEE_CHIP_CONFIG_DIR}/configs/default/S50module ${ROOTFS}/etc/init.d/
	fi

	if [ "x$PACK_STABILITY" = "xtrue" -a -d ${LICHEE_KERN_DIR}/tools/sunxi ];then
		cp -v ${LICHEE_KERN_DIR}/tools/sunxi/* ${ROOTFS}/bin
	fi

	copy_bin_firmware ${ROOTFS_FIRWMARE_PATH}

	if [ "x$LICHEE_LINUX_DEV" = "xsata" ];then
		if [ -d ${ROOTFS}/target ];then
			rm -rf ${ROOTFS}/target
		fi
		if [ -d ${LICHEE_SATA_DIR}/linux/target ];then
			mk_info "copy SATA rootfs"
			mkdir -p ${ROOTFS}/target
			cp -a ${LICHEE_SATA_DIR}/linux/target/* ${ROOTFS}/target
		fi
	fi

	(cd ${ROOTFS}; ln -fs bin/busybox init)
	#substitute_inittab ${ROOTFS}/etc/inittab

	export PATH=$PATH:${LICHEE_BUILD_DIR}/bin
	fakeroot chown	 -h -R 0:0	${ROOTFS}
	fakeroot mke2img -d ${ROOTFS} -G 4 -R 1 -B 0 -I 0 -o ${LICHEE_PLAT_OUT}/rootfs.ext4
	# 321 * 258048, about 79M, it should be enough for small capacity spinand

	if [ -n "`echo $LICHEE_KERN_VER | grep "linux-[34].[149]"`" ] || [ "x${LICHEE_KERN_VER}" = "xlinux-5.4" ]; then
		fakeroot mkfs.ubifs -m 4096 -e 258048 -c 375 -F -x zlib -r ${ROOTFS} -o ${LICHEE_PLAT_OUT}/rootfs.ubifs
	else
		fakeroot mkfs.ubifs -m 2048 -e 126976 -c 375 -F -x zlib -r ${ROOTFS} -o ${LICHEE_PLAT_OUT}/rootfs.ubifs
	fi

cat  > ${LICHEE_PLAT_OUT}/.rootfs << EOF
chown -h -R 0:0 ${ROOTFS}
${LICHEE_BUILD_DIR}/bin/makedevs -d \
${LICHEE_DEVICE_DIR}/config/rootfs_tar/_device_table.txt ${ROOTFS}
${LICHEE_BUILD_DIR}/bin/mksquashfs \
${ROOTFS} ${LICHEE_PLAT_OUT}/rootfs.squashfs -root-owned -no-progress -comp xz -noappend
EOF

	chmod a+x ${LICHEE_PLAT_OUT}/.rootfs
	fakeroot -- ${LICHEE_PLAT_OUT}/.rootfs
}

function pack_buildroot_rootfs()
{
	mk_info "pack rootfs ..."
	local ROOTFS=${LICHEE_BR_OUT}/target
	local ROOTFS_FIRWMARE_PATH=${ROOTFS}/lib/firmware
	local INODES=""
	local BLOCKS=""

	mkdir -p ${ROOTFS}/lib/modules
	cp -rf ${KERNEL_STAGING_DIR}/lib/modules/* \
		${ROOTFS}/lib/modules/

	copy_bin_firmware ${ROOTFS_FIRWMARE_PATH}

	(cd ${ROOTFS}; ln -fs bin/busybox init)

	export PATH=$PATH:${LICHEE_BUILD_DIR}/bin

	fakeroot chown -h -R 0:0 ${ROOTFS}

	make_ext4 ${ROOTFS}

	make_ubifs ${ROOTFS}

	make_squashfs ${ROOTFS}

	mk_info "pack rootfs ok ..."
}

function build_ubuntu_rootfs()
{
	local ROOTFS=${LICHEE_PLAT_OUT}/rootfs_def
	local ROOTFS_FIRWMARE_PATH=${ROOTFS}/lib/firmware
	local INODES=""
	local BLOCKS=""
	local rootfs_archive=""
	local rootfs_archivedir=""
	local install_libs=""
	local boardconfig="${LICHEE_BOARDCONFIG_PATH}"
	local main_version=${LICHEE_KERN_VER/.*/}
	local sub_version=${LICHEE_KERN_VER/*./}

	main_version=${main_version/linux-}

	#rootfs_archive=`cat ${boardconfig} | grep -w "LICHEE_ROOTFS" | awk -F= '{printf $2}'`
	rootfs_archive=${LICHEE_ROOTFS}
	rootfs_archivedir=${LICHEE_DEVICE_DIR}/config/rootfs_tar/${rootfs_archive}
	install_libs=${LICHEE_DEVICE_DIR}/config/rootfs_tar/install_libs/${LICHEE_BOARD}

	mk_info "Build ubuntu rootfs ..."

	if [ "$1" = "f" ]; then
		rm -fr ${ROOTFS}
	fi

	# bsp uses the compressed file system, just decompress them here,
	# but starting from gcc-10.3, use the extracted folder to directly copy
	if [ ! -d ${ROOTFS} ]; then
		mkdir -p ${ROOTFS}
		if [ -d ${rootfs_archivedir} ]; then
			cp -r ${rootfs_archivedir}/* ${ROOTFS}
		elif [ -f ${rootfs_archivedir} ]; then
			fakeroot tar -jxf ${rootfs_archivedir} -C ${ROOTFS}
		else
			mk_error "cann't find ${rootfs_archive}"
		fi
	fi

	if [ -d ${install_libs} ];then
		cp -rf ${install_libs}/* ${ROOTFS}/
	fi

	# the following operation is similar to the pack_buildroot_rootfs() -> copy the ko and others that systenm need
	rm -rf ${ROOTFS}/lib/modules
	mkdir -p ${ROOTFS}/lib/modules
	cp -rf ${KERNEL_STAGING_DIR}/lib/modules/* \
		${ROOTFS}/lib/modules/
	if [[ "$main_version" > "5" ]] || [[ "$main_version" == "5" ]] && [[ "$sub_version" -ge "10" ]]; then
		cp ${LICHEE_CHIP_CONFIG_DIR}/configs/default/${LICHEE_KERN_VER}/S50module ${ROOTFS}/etc/init.d/
	else
		cp ${LICHEE_CHIP_CONFIG_DIR}/configs/default/S50module ${ROOTFS}/etc/init.d/
	fi

	if [ "x$PACK_STABILITY" = "xtrue" -a -d ${LICHEE_KERN_DIR}/tools/sunxi ];then
		cp -v ${LICHEE_KERN_DIR}/tools/sunxi/* ${ROOTFS}/bin
	fi

	copy_bin_firmware ${ROOTFS_FIRWMARE_PATH}

	if [ "x$LICHEE_LINUX_DEV" = "xsata" ];then
		if [ -d ${ROOTFS}/target ];then
			rm -rf ${ROOTFS}/target
		fi
		if [ -d ${LICHEE_SATA_DIR}/linux/target ];then
			mk_info "copy SATA rootfs"
			mkdir -p ${ROOTFS}/target
			cp -a ${LICHEE_SATA_DIR}/linux/target/* ${ROOTFS}/target
		fi
	fi

	(cd ${ROOTFS}; ln -fs bin/busybox init)
	#substitute_inittab ${ROOTFS}/etc/inittab

	export PATH=$PATH:${LICHEE_BUILD_DIR}/bin
	fakeroot chown	 -h -R 0:0	${ROOTFS}
	#fakeroot mke2img -d ${ROOTFS} -G 4 -R 1 -B 0 -I 0 -o ${LICHEE_PLAT_OUT}/rootfs.ext4
	make_ext4 ${ROOTFS}
	# 321 * 258048, about 79M, it should be enough for small capacity spinand

	if [ -n "`echo $LICHEE_KERN_VER | grep "linux-[34].[149]"`" ] || [ "x${LICHEE_KERN_VER}" = "xlinux-5.4" ]; then
		fakeroot mkfs.ubifs -m 4096 -e 258048 -c 375 -F -x zlib -r ${ROOTFS} -o ${LICHEE_PLAT_OUT}/rootfs.ubifs
	else
		fakeroot mkfs.ubifs -m 2048 -e 126976 -c 375 -F -x zlib -r ${ROOTFS} -o ${LICHEE_PLAT_OUT}/rootfs.ubifs
	fi

cat  > ${LICHEE_PLAT_OUT}/.rootfs << EOF
chown -h -R 0:0 ${ROOTFS}
${LICHEE_BUILD_DIR}/bin/makedevs -d \
${LICHEE_DEVICE_DIR}/config/rootfs_tar/_device_table.txt ${ROOTFS}
${LICHEE_BUILD_DIR}/bin/mksquashfs \
${ROOTFS} ${LICHEE_PLAT_OUT}/rootfs.squashfs -root-owned -no-progress -comp xz -noappend
EOF

	chmod a+x ${LICHEE_PLAT_OUT}/.rootfs
	fakeroot -- ${LICHEE_PLAT_OUT}/.rootfs
}

function build_rootfs()
{
	mk_info "build rootfs ..."
	if [ ${LICHEE_PLATFORM} = "linux" ] ; then
		case ${LICHEE_LINUX_DEV} in
			bsp)
				build_bsp_rootfs $1
				;;
			ubuntu)
				build_ubuntu_rootfs $1
				;;
			sata)
				local ROOTFS=${LICHEE_PLAT_OUT}/rootfs_def
				if [ "x$PACK_TINY_ANDROID" = "xtrue" ]; then
					mk_tinyandroid $1
				else
					build_bsp_rootfs $1
				fi
				;;
			buildroot)
				build_buildroot_rootfs $@
				if [ $? -ne 0 ]; then
					mk_info "build_buildroot_rootfs failed"
					exit 1
				fi
				pack_buildroot_rootfs $1
				;;
			openwrt)
				build_openwrt_rootfs $@
				if [ $? -ne 0 ]; then
					mk_info "build_openwrt_rootfs failed"
					exit 1
				fi
				;;
			dragonboard)
				prepare_dragonboard_toolchain
				build_dragonboard_rootfs
				;;
			dragonabts)
				prepare_dragonabts_toolchain
				build_dragonabts_rootfs
				;;
		esac
	else
		mk_info "skip make rootfs for ${LICHEE_PLATFORM}"
	fi

}

function cldtbo()
{
	if [ -d ${LICHEE_CHIP_CONFIG_DIR}/dtbo ];  then
		mk_info "clean dtbo ..."
		rm -rf ${LICHEE_CHIP_CONFIG_DIR}/dtbo/*.dtbo
	fi
}

function build_dtbo()
{
	local dtb_search_path=(
		${LICHEE_BOARD_CONFIG_DIR}/dtbo
		${LICHEE_CHIP_CONFIG_DIR}/dtbo)

	local dtc_search_path=(
		${LICHEE_BOARD_CONFIG_DIR}/dtbo
		${LICHEE_CHIP_CONFIG_DIR}/dtbo
		${LICHEE_BUILD_DIR}/bin)

	local DTO_COMPILER=""
	local DTBO_DIR=""

	for d in ${dtb_search_path[@]}; do
		[ -d $d ] && DTBO_DIR=$d && break
	done

	for d in ${dtc_search_path[@]}; do
		[ -d $d ] && [ -f $d/dtco ] && DTO_COMPILER=$d/dtco && break
	done

	if [ -n "$DTBO_DIR" ] && [ -n "$DTO_COMPILER" ];  then
		mk_info "build dtbo ..."
		local DTC_FLAGS="-W no-unit_address_vs_reg"
		local DTS_DIR=${DTBO_DIR}
		local DTBO_OUT_DIR=${LICHEE_PLAT_OUT}

		if [ ! -f $DTO_COMPILER ]; then
			mk_info "build_dtbo: Can not find dtco compiler."
			exit 1
		fi

		local out_file_name=0
		for dts_file in ${DTS_DIR}/*.dts; do
			out_file_name=${dts_file%.*}
			$DTO_COMPILER ${DTC_FLAGS} -a 4 -@ -O dtb -o ${out_file_name}.dtbo ${dts_file}
			if [ $? -ne 0 ]; then
				mk_info "build_dtbo:create dtbo file failed"
				exit 1
			fi
		done

		local MKDTIMG=${LICHEE_BUILD_DIR}/bin/mkdtimg
		local DTBOIMG_CFG_FILE=${DTBO_DIR}/dtboimg.cfg
		local DTBOIMG_OUT_DIR=${LICHEE_PLAT_OUT}
		if [ -f ${MKDTIMG} ]; then
			if [ -f ${DTBOIMG_CFG_FILE} ]; then
				mk_info "build_dtbo: make  dtboimg start."
				cd ${DTBO_DIR}/
				${MKDTIMG} cfg_create ${DTBOIMG_OUT_DIR}/dtbo.img ${DTBOIMG_CFG_FILE}
				${MKDTIMG} dump ${DTBOIMG_OUT_DIR}/dtbo.img
				cd ${LICHEE_BUILD_DIR}
			else
				mk_info "build_dtbo: Can not find dtboimg.cfg\n"
				exit 1
			fi
		else
			mk_info "build_dtbo: Can not find mkdtimg\n"
			exit 1
		fi

	else
		mk_info "don't build dtbo ..."
	fi
}

function build_arisc()
{
	mk_info "build arisc"

	local arisc_cfg;

	if [ -f ${LICHEE_BOARD_CONFIG_DIR}/../default/arisc.config ]
	then
		arisc_cfg=${LICHEE_BOARD_CONFIG_DIR}/../default/arisc.config
	fi

	if [ -f ${LICHEE_CHIP_CONFIG_DIR}/tools/arisc_config_parse.sh ]
	then
		${LICHEE_CHIP_CONFIG_DIR}/tools/arisc_config_parse.sh
	fi

	if [ -f ${LICHEE_BOARD_CONFIG_DIR}/arisc.config ]
	then
		arisc_cfg=${LICHEE_BOARD_CONFIG_DIR}/arisc.config
	fi

	if [ ! $arisc_cfg ]
	then
		return 0;
	fi

	if [ ! -d ${LICHEE_ARISC_PATH} ];
	then
		mk_error "arisc project lost, use repo sync to get it"
		exit;
	fi

	cp $arisc_cfg $LICHEE_ARISC_PATH/.config
	make -C $LICHEE_ARISC_PATH
	return $?
}

function build_rtos()
{
	if [ -e "${LICHEE_TOP_DIR}/rtos/tools/scripts/build_rtos.sh" ]; then
		local cfg_key="LICHEE_RTOS_PROJECT_NAME"
		local rtos_project_name=$(load_config $cfg_key $BUILD_CONFIG)
		local lichee_board_brandy_dir=${LICHEE_BOARD_CONFIG_DIR}/bin
		local LICHEE_RTOS_BIN=
		local LICHEE_RTOS_BUILD_ARG=$@

		if [ -z "${rtos_project_name}" ]; then
			mk_info "rtos project name not set, skip build rtos."
			return 0
		fi

		if [ -d ${lichee_board_brandy_dir} ]; then
			export LICHEE_RTOS_BIN=${lichee_board_brandy_dir}/amp_rv0.bin
		else
			export LICHEE_RTOS_BIN=${LICHEE_BRANDY_OUT_DIR}/amp_rv0.bin
		fi

		export LICHEE_RTOS_BUILD_ARG=${LICHEE_RTOS_BUILD_ARG}
		export LICHEE_RTOS_PROJECT_NAME=${rtos_project_name}
		mk_info "build rtos ..."
		bash -c '${LICHEE_TOP_DIR}/rtos/tools/scripts/build_rtos.sh ${LICHEE_TOP_DIR}/rtos ${LICHEE_RTOS_PROJECT_NAME} ${LICHEE_RTOS_BIN} ${LICHEE_RTOS_BUILD_ARG}'
		return $?
	else
		mk_info "build_rtos.sh not exit, skip build rtos."
	fi
}

function build_dsp()
{
	if [ -e "${LICHEE_TOP_DIR}/rtos/lichee/dsp/build/build_dsp.sh" ]; then
		local lichee_board_brandy_dir=${LICHEE_BOARD_CONFIG_DIR}/bin
		local cfg_key="LICHEE_DSP_PROJECT_NAME"
		local dsp_project_name=$(load_config $cfg_key $BUILD_CONFIG)
		local LICHEE_DSP_BIN=""
		local LICHEE_DSP_BUILD_ARG=$@

		if [ -z "${dsp_project_name}" ]; then
			mk_info "dsp project name not set, skip build dsp."
			return 0
		fi

		if [ -d ${lichee_board_brandy_dir} ]; then
			export LICHEE_DSP_BIN=${lichee_board_brandy_dir}/amp_dsp0.bin
		else
			export LICHEE_DSP_BIN=${LICHEE_BRANDY_OUT_DIR}/amp_dsp0.bin
		fi

		export LICHEE_DSP_PROJECT_NAME=${dsp_project_name}
		export LICHEE_DSP_BUILD_ARG=${LICHEE_DSP_BUILD_ARG}
		mk_info "build dsp ..."
		bash -c '${LICHEE_TOP_DIR}/rtos/lichee/dsp/build/build_dsp.sh ${LICHEE_DSP_PROJECT_NAME} ${LICHEE_DSP_BIN} ${LICHEE_DSP_BUILD_ARG}'
		return $?
	else
		mk_info "build_dsp.sh not exit, skip build dsp."
	fi
}

function build_linuxdev()
{
	mk_info "----------------------------------------"
	mk_info "build linuxdev ..."
	mk_info "chip: $LICHEE_CHIP"
	mk_info "platform: $LICHEE_PLATFORM"
	mk_info "kernel: $LICHEE_KERN_VER"
	mk_info "board: $LICHEE_BOARD"
	mk_info "output: $LICHEE_PLAT_OUT"
	mk_info "----------------------------------------"

	check_env
	board_dts_create_link
	cp $BUILD_CONFIG $LICHEE_PLAT_OUT
	copy_prebuilt_product_to_staging

	build_dtbo
	if [ $? -ne 0 ]; then
		mk_info "build_dtbo failed"
		exit 1
	fi

	build_arisc
	if [ $? -ne 0 ]; then
		mk_info "build_arisc failed"
		exit 1
	fi

	build_bootloader
	if [ $? -ne 0 ]; then
		mk_info "build_bootloader failed"
		exit 1
	fi

	build_kernel $@
	if [ $? -ne 0 ]; then
		mk_info "build kernel failed"
		exit 1
	fi

	if [ -d ${LICHEE_SATA_DIR} ]; then
		build_sata $@
		if [ $? -ne 0 ]; then
			mk_info "build sata failed"
			exit 1
		fi
	fi

	build_rootfs $@
	if [ $? -ne 0 ]; then
		mk_info "build rootfs failed"
		exit 1
	fi

	mk_info "----------------------------------------"
	mk_info "build OK."
	mk_info "----------------------------------------"
}

function mk_clean()
{
	clbrandy
	clkernel
	cldragonboard
	cldtbo
	clbuildserver
	if [ "${LICHEE_LINUX_DEV}" == "buildroot" ] ; then
		clbuildroot
	elif [ "${LICHEE_LINUX_DEV}" == "openwrt" ]; then
		clopenwrt
	fi

	mk_info "clean product output in ${LICHEE_PLAT_OUT} ..."
	if [ "x${LICHEE_PLAT_OUT}" != "x" -a -d ${LICHEE_PLAT_OUT} ];then
		ls -A1 ${LICHEE_PLAT_OUT}/ | grep -vP "buildroot|.buildconfig" | xargs -I {} rm -rf ${LICHEE_PLAT_OUT}/{}
	fi
#	board_dts_remove_link
}

function mk_distclean()
{
	clbrandy
	clkernel "distclean"

	if [ "${LICHEE_LINUX_DEV}" == "buildroot" ] ; then
		clbuildroot
	elif [ "${LICHEE_LINUX_DEV}" == "openwrt" ]; then
		clopenwrt
	fi

	cldtbo
	cldragonboard

	mk_info "clean entires output dir ..."
	if [ "x${LICHEE_PLAT_OUT}" != "x" ]; then
		rm -rf ${LICHEE_PLAT_OUT}/{,.[!.],..?}*
	fi
#	board_dts_remove_link
}

function mk_pack()
{
	mk_info "packing firmware ..."

	check_env
	update_bin_path

	local PACK_PLATFORM=$LICHEE_PLATFORM
	[ "x${LICHEE_PLATFORM}" != "xandroid" ] && PACK_PLATFORM=$LICHEE_LINUX_DEV

	[ -z "$LICHEE_FLASH" ] && LICHEE_FLASH=none
	local PACK_CMD=./pack

	if [ -n "$LICHEE_PACK_HOOK" ] && [ -x "$LICHEE_TOP_DIR/$LICHEE_PACK_HOOK" ]; then
		mk_info "Use PACK HOOK $LICHEE_PACK_HOOK for $LICHEE_PLATFORM"
		PACK_CMD=$LICHEE_TOP_DIR/$LICHEE_PACK_HOOK
	fi

	(cd ${LICHEE_BUILD_DIR} && \
	$PACK_CMD -i ${LICHEE_IC} -c ${LICHEE_CHIP} -p ${PACK_PLATFORM} -b ${LICHEE_BOARD} -k ${LICHEE_KERN_VER} -n ${LICHEE_FLASH} $@)
}

function mkhelp()
{
	printf "
	mkscript - lichee build script

	<version>: 1.0.0
	<author >: james

	<command>:
	build_boot      build boot
	build_kernel    build kernel
	build_rootfs	build rootfs for linux, dragonboard
	mklichee    build total lichee

	mkclean     clean current board output
	mkdistclean clean entires output

	mk_pack      pack firmware for lichee

	mkhelp      show this message

	"
}

function _check_disclaimer()
{
	$BUILD_SCRIPTS_DIR/disclaimer/disclaimer.sh
	[ $? -ne 0 ] && exit 1
}

function parse_independent_package_build_para()
{
		while [ $# -gt 1 ]; do
		case "$1" in
			-c|--cflags)
				CFLAGS="$2"
				shift 2
				;;
			-l|--ldflags)
				LDFLAGS="$2"
				shift 2
				;;
			-x|--cxxflags)
				CXXFLAGS="$2"
				shift 2
				;;
			-p|--cppflags)
				CPPFLAGS="$2"
				shift 2
				;;
			-a|--configargs)
				CONFIGURE_ARGS="$2"
				shift 2
				;;
			-v|--configvars)
				CONFIGURE_VARS="$2"
				shift 2
				;;
			-s|--stagingdir)
				export STAGING_DIR="$2"
				STAGING_PREFIX=${STAGING_DIR}/usr
				shift 2
				;;
			-m|--makeargs)
				MAKE_ARGS=$2
				shift 2
				;;
			*)
				mk_err "Unknown option: $1"
				exit 1
				;;
		esac
	done
}

function build_independent_package_once()
{
(
	mk_info "==mkcmd.sh: build_independent_package=="
	cd $LICHEE_TOP_DIR
	CC="$(find ${LICHEE_TOOLCHAIN_PATH}/bin -name *gcc)"
	TOOLCHAIN_PREFIX="${CC##*/}"
	TOOLCHAIN_PREFIX="${TOOLCHAIN_PREFIX%-gcc}"
	CXX="${TOOLCHAIN_PREFIX}-g++"
	AR="${TOOLCHAIN_PREFIX}-ar"
	TARGET_CPU_VARIANT=$(cat ${LICHEE_TOP_DIR}/openwrt/target/${LICHEE_IC}/${LICHEE_IC}-common/BoardRules_common.mk | grep TARGET_CPU_VARIANT | awk -F= '{print $2}')
	PATH=${LICHEE_TOOLCHAIN_PATH}/bin:${PATH}
	PKG_DIR=${LICHEE_TOP_DIR}/$1
	TARGET=$2
	PKG_NAME=$(basename $PKG_DIR)
	STAGING_PREFIX=${STAGING_DIR}/usr
	#shift 2

	mkdir -p $STAGING_DIR
	CFLAGS="-I${LICHEE_TOOLCHAIN_PATH}/include -I${LICHEE_TOOLCHAIN_PATH}/usr/include ${CFLAGS}"
	PKG_SOURCE=$(${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C ${PKG_DIR} -p 2>/dev/null | grep PKG_SOURCE | grep -v PKG_SOURCE_ | tr -d ' '| awk -F= '{print $2}')
	PKG_BUILD_DIR=$(make -C ${PKG_DIR} -p 2>/dev/null | grep PKG_BUILD_DIR | grep := | tr -d ' '| awk -F= '{print $2}')
	if [ "x$PKG_BUILD_DIR" == "x" ]; then
		PKG_VERSION=$(${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C ${PKG_DIR} -p 2>/dev/null | grep PKG_VERSION | grep := | tr -d ' '| awk -F= '{print $2}')
		PKG_BUILD_DIR=/$PKG_NAME-$PKG_VERSION
	fi
	PKG_BUILD_DIR=${LICHEE_TOP_DIR}/out/bsp/${LICHEE_IC}/${LICHEE_BOARD}/build_dir${PKG_BUILD_DIR}
	PKG_INSTALL_DIR=$PKG_BUILD_DIR/install
	CFLAGS="-I$PKG_BUILD_DIR -I$PKG_BUILD_DIR/src -I${STAGING_DIR}/usr/include -I${LICHEE_TOOLCHAIN_PATH}/include -I${LICHEE_TOOLCHAIN_PATH}/usr/include ${CFLAGS}"
	LDFLAGS="-lpthread -L${STAGING_DIR}/usr/lib -Wl,-rpath-link,${STAGING_DIR}/usr/lib -L${LICHEE_TOOLCHAIN_PATH}/lib -L${LICHEE_TOOLCHAIN_PATH}/usr/lib -L$PKG_INSTALL_DIR/usr/lib ${LDFLAGS}"
	mkdir -p  $PKG_BUILD_DIR
	while read line; do
		if [ "x$(echo "$line" | grep "define Build/Prepare")" != "x" ]; then
			define_found=true
			continue
		fi
		if [ "$define_found" == "true" ] && [ $(echo "$line" | grep "endef") ]; then
			define_found=false
		elif [ "$define_found" == "true" ]; then
			[ "x$(echo $line | grep \$\(INSTALL_DIR\))" != "x" ] && line=$(echo $line | sed "s#\$(INSTALL_DIR)#install -d -m0755#g")

			[ "x$(echo $line | grep \$\(CP\))" != "x" ] && line=$(echo $line | sed "s#\$(CP)#cp -r#g")
			[ "x$(echo $line | grep \$\(PKG_BUILD_DIR\))" != "x" ] && line=$(echo $line | sed "s#\$(PKG_BUILD_DIR)#$PKG_BUILD_DIR#g")
			if [ "x$(echo $line | grep \$\(.*\))" != "x" ]; then
				pattern=$(echo $line | grep -o \$\(.*\) | cut -d '(' -f2 | cut -d ')' -f1)
				for word in $pattern; do
					val=$(${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C ${PKG_DIR} -p 2>/dev/null | grep "$word.*=" | tr -d ' '| awk -F= '{print $2}')
					line=$(echo $line | sed "s#\$($word)#$val#g") 
				done
			fi
			mk_info $(echo $line | sed "s#@##g")
			eval $(echo $line | sed "s#@##g")
		fi
	done < ${PKG_DIR}/Makefile

	cd $PKG_BUILD_DIR
	if [ "x$PKG_SOURCE" != "x" ]; then
		EXTENSION=${PKG_SOURCE##*.}
		case "$EXTENSION" in
			gz)
				DECOMPRESS_CMD="gzip -dc ${LICHEE_TOP_DIR}/openwrt/dl/${PKG_SOURCE} | "
				;;
			xz)
				DECOMPRESS_CMD="xzcat ${LICHEE_TOP_DIR}/openwrt/dl/${PKG_SOURCE} | "
				;;
		esac
		PKG_SOURCE=${PKG_SOURCE%.$EXTENSION}
		EXTENSION=${PKG_SOURCE##*.}
		case "$EXTENSION" in
			tar)
				DECOMPRESS_CMD="$DECOMPRESS_CMD tar -C $PKG_BUILD_DIR/.. -xf -"
				;;
		esac
		mkdir -p ${PKG_BUILD_DIR}
		eval $DECOMPRESS_CMD
		[ ! -d ./src/ ] || cp -r ./src $PKG_BUILD_DIR
		if [ "x$(ls $PKG_DIR/patches/*.patch 2>/dev/null)" != "x" ]; then
			for patchfile in $(ls $PKG_DIR/patches/*.patch | sort -n); do
				mk_info "Applying patch: $patchfile"
				patch -p1 < "$patchfile"
			done
		fi
	fi
	if [ -x $PKG_BUILD_DIR/configure ]; then
		export PKG_CONFIG_PATH=${STAGING_DIR}/usr/lib/pkgconfig:${STAGING_DIR}/usr/share/pkgconfig
		cd $PKG_BUILD_DIR
		CONFIGURE_ARGS=$(${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C ${PKG_DIR} -p 2>/dev/null | grep CONFIGURE_ARGS | grep -v _CONFIGURE_ARGS | grep = | awk -F= '{for(i=2;i<=NF;i++){if(i>2){printf("=") }printf("%s",$i)}}')
		CONFIGURE_ARGS="--host "${TOOLCHAIN_PREFIX}" \
				--target "${TOOLCHAIN_PREFIX}" \
				--program-suffix="" \
				--prefix=/usr \
				--exec-prefix=/usr \
				--bindir=/usr/bin \
				--sbindir=/usr/sbin \
				--libexecdir=/usr/lib \
				--sysconfdir=/etc \
				--datadir=/usr/share \
				--localstatedir=/var \
				--mandir=/usr/man \
				--infodir=/usr/info
				$CONFIGURE_ARGS"
		#find $PKG_BUILD_DIR -name config.guess | xargs -r chmod u+w
		#find $PKG_BUILD_DIR  -name config.guess | xargs -r -n1 cp --remove-destination ${LICHEE_TOP_DIR}/openwrt/openwrt/scripts/config.guess;
		#find $PKG_BUILD_DIR -name config.sub | xargs -r chmod u+w
		#find $PKG_BUILD_DIR -name config.sub | xargs -r -n1 cp --remove-destination ${LICHEE_TOP_DIR}/openwrt/openwrt/scripts/config.sub
		echo AS="$CC -c $CFLAGS" \
		LD="${TOOLCHAIN_PREFIX}-ld" \
		NM="${TOOLCHAIN_PREFIX}-nm" \
		OBJDUMP="${TOOLCHAIN_PREFIX}-objdump" \
		SIZE="${TOOLCHAIN_PREFIX}-size" \
		CC="${TOOLCHAIN_PREFIX}-gcc" \
		GCC="${TOOLCHAIN_PREFIX}-gcc" \
		CXX="${TOOLCHAIN_PREFIX}-g++" \
		RANLIB="${TOOLCHAIN_PREFIX}-ranlib" \
		STRIP="${TOOLCHAIN_PREFIX}-strip" \
		OBJCOPY="${TOOLCHAIN_PREFIX}-objcopy" \
		OBJDUMP="${TOOLCHAIN_PREFIX}objdump" \
		SIZE="${TOOLCHAIN_PREFIX}size" \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		CPPFLAGS="$CPPFLAGS" \
		LDFLAGS="$LDFLAGS" \
		AR="" \
		$PKG_BUILD_DIR/configure \
		$CONFIGURE_ARGS \
		$CONFIGURE_VARS
		AS="$CC -c $CFLAGS" \
		LD="${TOOLCHAIN_PREFIX}-ld" \
		NM="${TOOLCHAIN_PREFIX}-nm" \
		OBJDUMP="${TOOLCHAIN_PREFIX}-objdump" \
		SIZE="${TOOLCHAIN_PREFIX}-size" \
		CC="${TOOLCHAIN_PREFIX}-gcc" \
		GCC="${TOOLCHAIN_PREFIX}-gcc" \
		CXX="${TOOLCHAIN_PREFIX}-g++" \
		RANLIB="${TOOLCHAIN_PREFIX}-ranlib" \
		STRIP="${TOOLCHAIN_PREFIX}-strip" \
		OBJCOPY="${TOOLCHAIN_PREFIX}-objcopy" \
		OBJDUMP="${TOOLCHAIN_PREFIX}-objdump" \
		SIZE="${TOOLCHAIN_PREFIX}size" \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		CPPFLAGS="$CPPFLAGS" \
		LDFLAGS="$LDFLAGS" \
		AR="${TOOLCHAIN_PREFIX}-ar" \
		PKG_CONFIG="pkg-config --define-variable=prefix=${STAGING_PREFIX} --define-variable=exec_prefix=${STAGING_PREFIX} --define-variable=bindir=${STAGING_PREFIX}/bin" \
		$PKG_BUILD_DIR/configure \
		$CONFIGURE_ARGS \
		$CONFIGURE_VARS
	fi
	if [ -f $PKG_BUILD_DIR/Makefile ]; then
		eval echo make -C $PKG_BUILD_DIR ARCH="$LICHEE_ARCH" AR="$AR" CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="-L$PKG_INSTALL_DIR $LDFLAGS" $TARGET
		${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C $PKG_BUILD_DIR ARCH="$LICHEE_ARCH" AR="$AR" CC="$CC" CFLAGS="-fPIC $CFLAGS" LDFLAGS="-L$PKG_INSTALL_DIR $LDFLAGS" $TARGET
	else
		mk_info ${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C $PKG_BUILD_DIR/src ARCH="$LICHEE_ARCH" AR="$AR" CC="$CC" CFLAGS="-fPIC $CFLAGS" LDFLAGS="-L$PKG_INSTALL_DIR $LDFLAGS" $TARGET
		${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C $PKG_BUILD_DIR/src ARCH="$LICHEE_ARCH" AR="$AR" CC="$CC" CFLAGS="-fPIC $CFLAGS" LDFLAGS="-L$PKG_INSTALL_DIR $LDFLAGS" $TARGET
	fi
	[ "$TARGET" == "clean" ] && return 0
	CFLAGS="$CFLAGS" \
	CXXFLAGS="$CXXFLAGS" \
	LD_FLAGS="$LDFLAGS" \
	${LICHEE_TOP_DIR}/prebuilt/hostbuilt/make4.1/bin/make -C $PKG_BUILD_DIR \
		AR="${TOOLCHAIN_PREFIX}-ar" \
		AS="$CC -c $CFLAGS" \
		LD="${TOOLCHAIN_PREFIX}-ld" \
		NM="${TOOLCHAIN_PREFIX}-nm" \
		OBJDUMP="${TOOLCHAIN_PREFIX}-objdump" \
		SIZE="${TOOLCHAIN_PREFIX}-size" \
		CC="${TOOLCHAIN_PREFIX}-gcc" \
		GCC="${TOOLCHAIN_PREFIX}-gcc" \
		CXX="${TOOLCHAIN_PREFIX}-g++" \
		RANLIB="${TOOLCHAIN_PREFIX}-ranlib" \
		STRIP="${TOOLCHAIN_PREFIX}-strip" \
		OBJCOPY="${TOOLCHAIN_PREFIX}-objcopy" \
		OBJDUMP="${TOOLCHAIN_PREFIX}-objdump" \
		SIZE="${TOOLCHAIN_PREFIX}size" \
		CROSS="$TOOLCHAIN_PREFIX" \
		ARCH="$LICHEE_ARCH"\
		DESTDIR="$PKG_INSTALL_DIR" \
		install

	local ROOTFS=${LICHEE_PLAT_OUT}/rootfs_def
	if [ ! -d $ROOTFS ]; then
		mk_err "$ROOTFS doesn't exist, please build bsp first!"
		exit
	fi
	mk_info "Installing files to $ROOTFS ..."
	while read line; do
		if [ "x$(echo "$line" | grep "define Package/.*/install")" != "x" ]; then
			define_found=true
			continue
		fi
		if [ "$define_found" == "true" ] && [ $(echo "$line" | grep "endef") ]; then
			define_found=false
		elif [ "$define_found" == "true" ]; then
			[ "x$(echo $line | grep \$\(INSTALL_DIR\))" != "x" ] && install -d -m0755 $(echo $line | awk '{print $2}' | sed "s#\$(1)#$ROOTFS#g")
			if [ "x$(echo $line | grep \$\(CP\))" != "x" ]; then
				[ "x$(echo $line | grep PKG_INSTALL_DIR)" != "x" ] && cp  $(echo $line | awk '{print $2}' | sed "s#\$(PKG_INSTALL_DIR)#$PKG_INSTALL_DIR#g") $(echo $line | awk '{print $3}' | sed "s#\$(1)#$ROOTFS#g")
				[ "x$(echo $line | grep PKG_BUILD_DIR)" != "x" ] && cp  $(echo $line | awk '{print $2}' | sed "s#\$(PKG_BUILD_DIR)#$PKG_BUILD_DIR#g") $(echo $line | awk '{print $3}' | sed "s#\$(1)#$ROOTFS#g")
				[ "x$(echo $line | grep "\./")" != "x" ] && cp $(echo $line | awk '{print $2}' | sed "s#\./#$PKG_DIR/#g") $(echo $line | awk '{print $3}' | sed "s#\$(1)#$ROOTFS#g")
			fi
			if [ "x$(echo $line | grep \$\(INSTALL_BIN\))" != "x" ]; then
				[ "x$(echo $line | grep \$\(PKG_INSTALL_DIR\))" != "x" ] && install -m0644 $(echo $line | awk '{print $2}' | sed "s#\$(PKG_INSTALL_DIR)#$PKG_INSTALL_DIR#g") $(echo $line | awk '{print $3}' | sed "s#\$(1)#$ROOTFS#g")
				[ "x$(echo $line | grep \$\(PKG_BUILD_DIR\))" != "x" ] && install -m0644 $(echo $line | awk '{print $2}' | sed "s#\$(PKG_BUILD_DIR)#$PKG_BUILD_DIR#g" | sed "s#\$(PKG_NAME)#$PKG_NAME#g") $(echo $line | awk '{print $3}' | sed "s#\$(1)#$ROOTFS#g")
			fi
		fi
	done < ${PKG_DIR}/Makefile
	mk_info "Installing files to $ROOTFS done"
	return $?
)
}
function build_independent_package()
{
	parse_independent_package_build_para "$@"
	bsp_package_list=$LICHEE_BOARD_CONFIG_DIR/package
	[ "x$STAGING_DIR" == "x" ] && STAGING_DIR=$LICHEE_TOP_DIR/$LICHEE_BSP_STAGING
	if [ -f $bsp_package_list ]; then
		for path in $(cat $bsp_package_list); do
			mk_info "building package $path ..."
			[ -d $LICHEE_TOP_DIR/$path ] && [ -d $LICHEE_TOP_DIR/$LICHEE_BSP_STAGING ] && build_independent_package_once $path all
		done
	fi
}
_check_disclaimer

