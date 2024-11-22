#!/bin/bash


# run ./build.sh xxx command
function build()
{
	local mode=$@
	if [ $# -gt 1 ]; then
		echo "too much args"
		return 1
	fi

	if [ "x$mode" == "x" ]; then
		./build.sh
		[ $? -ne 0 ] && return 1
	elif [ "x$mode" == "xbrandy" ]; then
		./build.sh brandy
		[ $? -ne 0 ] && return 1
	elif [ "x$mode" == "xkernel" ]; then
		./build.sh kernel
		[ $? -ne 0 ] && return 1
	elif [ "x$mode" == "xrecovery" ]; then
		./build.sh recovery
		[ $? -ne 0 ] && return 1
	elif [ "x$mode" == "xbuildroot" ]; then
		./build.sh buildroot
		[ $? -ne 0 ] && return 1
	elif [ "x$mode" == "xdistclean" ]; then
		./build.sh distclean
		[ $? -ne 0 ] && return 1
	elif [ "x$mode" == "xclean" ]; then
		./build.sh clean
		[ $? -ne 0 ] && return 1
	elif [ "x$mode" == "xhelp" ]; then
		build_help
		[ $? -ne 0 ] && return 1
	else
		echo "unknown command."
		build_usage
	fi
}


function print_red(){
	echo -e '\033[0;31;1m'
	echo $1
	echo -e '\033[0m'
}

function make_buildroot_recovery_cpio()
{
	local LICHEE_KERN_VER=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_KERN_VER=\(.*\)$/\1/g'p)
	local kernel_dir=${TINA_TOPDIR}/kernel/${LICHEE_KERN_VER}
	#echo "kernel_dir:${kernel_dir}"

	local ARCH=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_ARCH=\(.*\)$/\1/g'p)
	echo "arch:${ARCH}"
	local ramdisk=rootfs.cpio.gz
	if [ x"${ARCH}" = x"riscv" ]; then
		ramdisk=${kernel_dir}/rootfs_rv64.cpio.gz
	else
		ramdisk=${kernel_dir}/rootfs_recovery_32bit.cpio.gz
	fi
	echo "ramdisk:${ramdisk}"

	local br_def=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BR_DEFCONF=\(.*\)$/\1/g'p)
	local br_ota_def=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BR_RAMFS_CONF=\(.*\)$/\1/g'p)
	local br_dir=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BR_DIR=\(.*\)$/\1/g'p)
	local br_out_dir=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BR_OUT=\(.*\)$/\1/g'p)
	echo "br_def:${br_def}"
	echo "br_ota_def:${br_ota_def}"
	echo "br_dir:${br_dir}"
	echo "br_out_dir:${br_out_dir}"

	if [ x"${br_ota_def}" = x"" ]; then
		print_red "should define LICHEE_BR_RAMFS_CONF in Boardconfig.mk"
		print_red "such as: LICHEE_BR_RAMFS_CONF=sunxi_recovery_ramfs_defconfig"
		return 1
	fi

	local build_script="build.sh"
	#rm -rf ${br_out_dir}
	mkdir -p ${br_out_dir}/ramfs
	${TINA_TOPDIR}/build.sh buildroot_rootfs ramfs
	if [ $? -ne 0 ]; then
		echo "build buildroot recovery rootfs failed"
		return 1
	fi

	cp ${br_out_dir}/../ramfs/images/rootfs.cpio.gz ${ramdisk}
}

#to update rootfs_recovery.cpio.gz. some functions from openwrt/build/envsetup.sh
function make_openwrt_recovery_img()
{
	local LICHEE_KERN_VER=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_KERN_VER=\(.*\)$/\1/g'p)
	local kernel_dir=${TINA_TOPDIR}/kernel/${LICHEE_KERN_VER}
	#echo "kernel_dir:${kernel_dir}"

	local ARCH=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_ARCH=\(.*\)$/\1/g'p)
	echo "arch:${ARCH}"
	local ramdisk=rootfs.cpio.gz
	if [ x"${ARCH}" = x"riscv" ]; then
		ramdisk=${kernel_dir}/rootfs_rv64.cpio.gz
	else
		ramdisk=${kernel_dir}/rootfs_recovery_32bit.cpio.gz
	fi
	echo "ramdisk:${ramdisk}"

	${TINA_TOPDIR}/build.sh openwrt_rootfs $@ OTA=_ota
	if [ $? -ne 0 ]; then
		mk_info "build recovery rootfs failed"
		return 1
	fi
	crootfs
	find . | fakeroot cpio -o -Hnewc | gzip > ${ramdisk}
	cd -
}

function swupdate_make_recovery_img()
{
	local LICHEE_LINUX_DEV=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_LINUX_DEV=\(.*\)$/\1/g'p)
	if [ x"${LICHEE_LINUX_DEV}" = x"openwrt" ]; then
		make_openwrt_recovery_img $@
		if [ $? -ne 0 ]; then
			return 1
		fi
	fi

	if [ x"${LICHEE_LINUX_DEV}" = x"buildroot" ]; then
		make_buildroot_recovery_cpio $@
		if [ $? -ne 0 ]; then
			return 1
		fi
	fi

	${TINA_TOPDIR}/build.sh recovery
}

function swupdate_init_key() {
	#T=$(gettop)
	local LICHEE_TOP_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_TOP_DIR=\(.*\)$/\1/g'p)
	local LICHEE_LINUX_DEV=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_LINUX_DEV=\(.*\)$/\1/g'p)
	local LICHEE_IC=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_IC=\(.*\)$/\1/g'p)
	local LICHEE_BOARD=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BOARD=\(.*\)$/\1/g'p)
	local LICHEE_BOARD_CONFIG_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BOARD_CONFIG_DIR=\(.*\)$/\1/g'p)
	cd ${LICHEE_TOP_DIR}
	local password="swupdate"
	local SWUPDATE_CONFIG_DIR=""
	local BUSYBOX_BASEFILE_DIR=""
	if [ x"${LICHEE_LINUX_DEV}" = x"openwrt" ]; then
		SWUPDATE_CONFIG_DIR="${LICHEE_TOP_DIR}/${LICHEE_LINUX_DEV}/target/${LICHEE_IC}/${LICHEE_IC}-${LICHEE_BOARD}/swupdate"
		BUSYBOX_BASEFILE_DIR="${LICHEE_TOP_DIR}/${LICHEE_LINUX_DEV}/target/${LICHEE_IC}/${LICHEE_IC}-${LICHEE_BOARD}/busybox-init-base-files"
		local PROCD_BASEFILE_DIR="${LICHEE_TOP_DIR}/${LICHEE_LINUX_DEV}/target/${LICHEE_IC}/${LICHEE_IC}-${LICHEE_BOARD}/base-files"
	fi
	if [ x"${LICHEE_LINUX_DEV}" = x"buildroot" ]; then
		SWUPDATE_CONFIG_DIR="${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/swupdate"
		BUSYBOX_BASEFILE_DIR="${LICHEE_TOP_DIR}/${LICHEE_LINUX_DEV}/config/${LICHEE_LINUX_DEV}/allwinner/system/busybox-init-base-files"
	fi
	local KEY_DIR="etc"
	mkdir -p $SWUPDATE_CONFIG_DIR
	\cd $SWUPDATE_CONFIG_DIR
	echo "-------------------- init password --------------------"
	if [ "$1" ] ; then
	    password="$1"
	fi
	echo "$password" > swupdate_priv.password
	echo "-------------------- init priv key --------------------"
	openssl genrsa -aes256 -passout file:swupdate_priv.password -out swupdate_priv.pem
	echo "-------------------- init public key --------------------"
	openssl rsa -in swupdate_priv.pem -passin file:swupdate_priv.password -out swupdate_public.pem -outform PEM -pubout
	if [ x"${LICHEE_LINUX_DEV}" = x"openwrt" ]; then
		mkdir -p "$PROCD_BASEFILE_DIR/$KEY_DIR"
		cp swupdate_public.pem "$PROCD_BASEFILE_DIR/$KEY_DIR"
	fi
	mkdir -p "$BUSYBOX_BASEFILE_DIR/$KEY_DIR"
	cp swupdate_public.pem "$BUSYBOX_BASEFILE_DIR/$KEY_DIR"
	echo "-------------------- out files --------------------"
	echo "password:$(pwd)/swupdate_priv.password"
	echo "private key:$(pwd)/swupdate_priv.pem"
	echo "public key:$(pwd)/swupdate_public.pem"
	if [ x"${LICHEE_LINUX_DEV}" = x"openwrt" ]; then
		echo "public key:$PROCD_BASEFILE_DIR/$KEY_DIR/swupdate_public.pem"
	fi
	echo "public key:$BUSYBOX_BASEFILE_DIR/$KEY_DIR/swupdate_public.pem"

	\cd -
}

function swupdate_pack_swu() {

	#T=$(gettop)
	#\cd $T
	local LICHEE_TOP_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_TOP_DIR=\(.*\)$/\1/g'p)
	local LICHEE_PLAT_OUT=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_PLAT_OUT=\(.*\)$/\1/g'p)
	local LICHEE_PACK_OUT_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_PACK_OUT_DIR=\(.*\)$/\1/g'p)
	local LICHEE_LINUX_DEV=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_LINUX_DEV=\(.*\)$/\1/g'p)
	local LICHEE_IC=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_IC=\(.*\)$/\1/g'p)
	local LICHEE_BOARD=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BOARD=\(.*\)$/\1/g'p)
	local LICHEE_BOARD_CONFIG_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BOARD_CONFIG_DIR=\(.*\)$/\1/g'p)
	local LICHEE_BUILD_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BUILD_DIR=\(.*\)$/\1/g'p)
	local LICHEE_BR_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BR_DIR=\(.*\)$/\1/g'p)
	local LICHEE_BR_DEFCONF=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BR_DEFCONF=\(.*\)$/\1/g'p)
	cd ${LICHEE_TOP_DIR}
	local BIN_DIR="${LICHEE_PACK_OUT_DIR}"
	local SWU_DIR="${LICHEE_PLAT_OUT}/swupdate"
	mkdir -p $SWU_DIR
	local SWUPDATE_CONFIG_DIR=""
	if [ x"${LICHEE_LINUX_DEV}" = x"openwrt" ]; then
		SWUPDATE_CONFIG_DIR="${LICHEE_TOP_DIR}/${LICHEE_LINUX_DEV}/target/${LICHEE_IC}/${LICHEE_IC}-${LICHEE_BOARD}/swupdate"
	elif [ x"${LICHEE_LINUX_DEV}" = x"buildroot" ]; then
		SWUPDATE_CONFIG_DIR="${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/swupdate"
	fi
	local SWUPDATE_COMMON_CONFIG_DIR="${LICHEE_BOARD_CONFIG_DIR}/swupdate"
	local SWUPDATE_GENERIC_CONFIG_DIR="${LICHEE_BUILD_DIR}/swupdate"
	#mkdir -p $SWUPDATE_CONFIG_DIR
	#local TARGET_COMMON="$(awk -F "-" '{print $1}' <<< ${TARGET_BOARD})-common"
	local CFG="sw-subimgs$1.cfg"
	#mkdir -p "$SWU_DIR"
	local storage_type_nor=0
	local f="${LICHEE_BOARD_CONFIG_DIR}/sys_config.fex"
	local B="$( awk -F"=" '/^storage_type/{print $2}' $f | sed 's/^[ \t]*//g' | sed 's/\r//g')"

	case $B in
		-1)
			print_red "###storage type error###"
			print_red "###cannot choose boot0, please config storage_type in sys_config ###"
			;;
		*0 | *5)
			local boot0_img=boot0_nand.fex
			;;
		*1 | *2 | *4)
			local boot0_img=boot0_sdcard.fex
			;;
		3)
			local boot0_img=boot0_spinor.fex
			storage_type_nor=1
			;;
		*)
			print_red "###storage type error###"
			print_red "###cannot choose boot0, please config storage_type in sys_config ###"
			;;
	esac
	[ -n "$boot0_img" ] && {
		rm -rf $LICHEE_PLAT_OUT/boot0.img
		dd if=$BIN_DIR/$boot0_img of=$LICHEE_PLAT_OUT/boot0.img
	}
	#local U="$(get_uboot)"
	#if [[ "$U" =~ "2011" ]]; then
	#	local uboot_img=u-boot.fex
	#else
	#	if [ x"$storage_type_nor" = x"1" ]; then
	#		local uboot_img=boot_package_nor.fex
	#	else
	#		local uboot_img=boot_package.fex
	#	fi
	#fi

	#we should get uboot version like 2018,2014,2011 in the future
	if [ x"$storage_type_nor" = x"1" ]; then
		local uboot_img=boot_package_nor.fex
	else
		local uboot_img=boot_package.fex
	fi
	rm -rf $LICHEE_PLAT_OUT/uboot.img
	dd if=$BIN_DIR/$uboot_img of=$LICHEE_PLAT_OUT/uboot.img

	if [ -e $SWUPDATE_CONFIG_DIR/$CFG ]; then
		local SWUPDATE_SUBIMGS="$SWUPDATE_CONFIG_DIR/$CFG"
	elif [ -e $SWUPDATE_COMMON_CONFIG_DIR/$CFG ]; then
		local SWUPDATE_SUBIMGS="$SWUPDATE_COMMON_CONFIG_DIR/$CFG"
	else
		local SWUPDATE_SUBIMGS="$SWUPDATE_GENERIC_CONFIG_DIR/$CFG"
	fi

	unset swota_file_list
	unset swota_copy_file_list

	echo "####$SWUPDATE_SUBIMGS####"
	. $SWUPDATE_SUBIMGS
	echo ${swota_file_list[@]} | sed 's/ /\n/g'
	echo ${swota_copy_file_list[@]} | sed 's/ /\n/g'

	[ ! -f "$SWUPDATE_SUBIMGS" ] && print_red "$SWUPDATE_SUBIMGS not exist!!" &&  return 1

	echo "-------------------- config --------------------"
	echo "subimgs config by: $SWUPDATE_SUBIMGS"
	echo "out dir: $SWU_DIR"

	echo "-------------------- do copy --------------------"
	cp "$SWUPDATE_SUBIMGS" "$SWU_DIR"
	rm -f "$SWU_DIR/sw-subimgs-fix.cfg"

	# files pack into swu
	for line in ${swota_file_list[@]} ; do
		ori_file=$(echo $line | awk -F: '{print $1}')
		base_name=$(basename "$line")
		fix_name=${base_name#*:}
		[ ! -f "$ori_file" ] && print_red "$ori_file not exist!!" && return 1
		cp $ori_file $SWU_DIR/$fix_name
		echo $fix_name >> "$SWU_DIR/sw-subimgs-fix.cfg"
	done

	# files only copy but not pack into swu
	for line in ${swota_copy_file_list[@]} ; do
		ori_file=$(echo $line | awk -F: '{print $1}')
		base_name=$(basename "$line")
		fix_name=${base_name#*:}
		[ ! -f "$ori_file" ] && print_red "$ori_file not exist!!" && return 1
		cp $ori_file $SWU_DIR/$fix_name
		echo $fix_name >> "$SWU_DIR/sw-subimgs-copy.cfg"
	done
	\cd - > /dev/null
	\cd "$SWU_DIR"

	echo "-------------------- do sha256 --------------------"
	cp sw-description sw-description.bk
	[ -f $SWU_DIR/sw-subimgs-fix.cfg ] && {
		while IFS= read -r line
		do
			item="$line"
			if grep -q -E "sha256 = \"@$item\"" sw-description ; then
				echo "sha256 $item"
				item_hash=$(sha256sum "$item" | awk '{print $1}')
				item_size=$(du -b "$item" | awk '{print $1}')
				sed -i "s/\(.*\)\(sha256 = \"@$item\"\)/\1sha256 = \"$item_hash\"/g" sw-description
				sed -i "s/\(.*\)\(size = \"@$item\"\)/\1size = \"$item_size\"/g" sw-description
			fi
		done < "$SWU_DIR/sw-subimgs-fix.cfg"
	}

	[ -f $SWU_DIR/sw-subimgs-copy.cfg ] && {
		while IFS= read -r line
		do
			item="$line"
			if grep -q -E "sha256 = \"@$item\"" sw-description ; then
				echo "sha256 $item"
				item_hash=$(sha256sum "$item" | awk '{print $1}')
				item_size=$(du -b "$item" | awk '{print $1}')
				sed -i "s/\(.*\)\(sha256 = \"@$item\"\)/\1sha256 = \"$item_hash\"/g" sw-description
				sed -i "s/\(.*\)\(size = \"@$item\"\)/\1size = \"$item_size\"/g" sw-description
			fi
		done < "$SWU_DIR/sw-subimgs-copy.cfg"
	}

	diff sw-description.bk sw-description

	echo "-------------------- do sign --------------------"

	local swupdate_need_sign=""
	local def_file=""
	if [ x"${LICHEE_LINUX_DEV}" = x"openwrt" ]; then
		def_file="${LICHEE_TOP_DIR}/${LICHEE_LINUX_DEV}/target/${LICHEE_IC}/${LICHEE_IC}-${LICHEE_BOARD}/defconfig"
	fi

	if [ x"${LICHEE_LINUX_DEV}" = x"buildroot" ]; then
		def_file="${LICHEE_BR_DIR}/configs/${LICHEE_BR_DEFCONF}"
	fi
	echo "defconfig file:${def_file}"
	grep "SWUPDATE_CONFIG_SIGNED_IMAGES=y" "${def_file}" && {
		swupdate_need_sign=1
		echo "need do sign"
	}

	local swupdate_sign_method=""
	local password_para=""
	#for rsa
	local priv_key_file="$SWUPDATE_CONFIG_DIR/swupdate_priv.pem"
	local password_file="$SWUPDATE_CONFIG_DIR/swupdate_priv.password"
	#for cms
	local cert_cert_file="$SWUPDATE_CONFIG_DIR/swupdate_cert.cert.pem"
	local cert_key_file="$SWUPDATE_CONFIG_DIR/swupdate_cert.key.pem"

	[ x$swupdate_need_sign = x"1" ] && {
		echo "add sw-description.sig to sw-subimgs-fix.cfg"
		sed '1 asw-description.sig' -i sw-subimgs-fix.cfg
		grep "SWUPDATE_CONFIG_SIGALG_RAWRSA=y" "${def_file}" && swupdate_sign_method="RSA"
		grep "SWUPDATE_CONFIG_SIGALG_CMS=y" "${def_file}" && swupdate_sign_method="CMS"
		[ -e "$password_file" ] && {
			echo "password file exist"
			password_para="-passin file:$password_file"
		}

		if [ x"$swupdate_sign_method" = x"RSA" ]; then
			echo "generate sw-description.sig with rsa"
			openssl dgst -sha256 -sign "$priv_key_file" $password_para "$SWU_DIR/sw-description" > "$SWU_DIR/sw-description.sig"
		elif [ x"$swupdate_sign_method" = x"CMS" ]; then
			echo "generate sw-description.sig with cms"
			openssl cms -sign -in  "$SWU_DIR/sw-description" -out "$SWU_DIR/sw-description.sig" -signer "$cert_cert_file" \
				-inkey "$cert_key_file" -outform DER -nosmimecap -binary
		fi
	}

	echo "-------------------- do md5sum --------------------"
	local md5_file="cpio_item_md5"
	rm -f $md5_file
	while IFS= read -r line
	do
		md5sum "$line" >> $md5_file
	done < "$SWU_DIR/sw-subimgs-fix.cfg"
	echo "$md5_file" >> sw-subimgs-fix.cfg
	cat $md5_file

	local out_name="${LICHEE_LINUX_DEV}_${LICHEE_IC}_${LICHEE_BOARD}$1.swu"
	echo "-------------------- do cpio --------------------"
	while IFS= read -r line
	do
		echo "$line"
	done < "$SWU_DIR/sw-subimgs-fix.cfg" | cpio -ov -H crc >  "$SWU_DIR/$out_name"

	echo "-------------------- out file in --------------------"
	echo ""
	print_red "$SWU_DIR/$out_name"
	du -sh "$SWU_DIR/$out_name"
	echo ""
	cd ${LICHEE_TOP_DIR}

}

function ota_ab(){
	echo "copy env.cfg"
	cp ${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/env_ab.cfg  ${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/env.cfg -rf
	echo "copy sys_partition.fex"
	cp ${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/sys_partition_ab.fex  ${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/sys_partition.fex
}

function ota_recovery(){
	echo "copy env.cfg"
	cp -f ${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/env-recovery.cfg  ${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/env.cfg
	echo "copy sys_partition.fex"
	cp -f ${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/sys_partition-recovery.fex  ${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_LINUX_DEV}/sys_partition.fex
}

function swupdate_make_delta()
{
	[ $# -lt 2 ] && print_red "usage:swupdate_make_delta base_swu new_swu [output_dir]" && return 1

	local LICHEE_TOP_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_TOP_DIR=\(.*\)$/\1/g'p)
	local LICHEE_PLAT_OUT=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_PLAT_OUT=\(.*\)$/\1/g'p)
	local BIN_DIR="${LICHEE_PLAT_OUT}"
	local SWU_DIR="${BIN_DIR}/swupdate"
	local base_swu=$(readlink -f "$1")
	local new_swu=$(readlink -f "$2")
	local delta_dir="${SWU_DIR}/swupdate_delta"
	[ -n "$3" ] && delta_dir="$3/swupdate_delta"

	echo "base_swu  : $base_swu"
	echo "new_swu   : $new_swu"
	echo "delta_dir : $delta_dir"

	rm -rf "$delta_dir"
	mkdir -p "$delta_dir/base"
	mkdir -p "$delta_dir/base_sig"
	mkdir -p "$delta_dir/new"
	mkdir -p "$delta_dir/delta"

	local md5_file="cpio_item_md5"
	local check=""

	cd "$delta_dir/base"
	cpio -idmv < "$base_swu"
	check=$(md5sum --quiet -c $md5_file)
	[ x"$check" = x"" ] || {
		print_red "check md5 fail"
		md5sum -c $md5_file
		cd -
		return 1
	}
	cd -

	cd "$delta_dir/new"
	cpio -idmv < "$new_swu"
	check=$(md5sum --quiet -c $md5_file)
	[ x"$check" = x"" ] || {
		print_red "check md5 fail"
		md5sum -c $md5_file
		cd -
		return 1
	}
	cd -

	#uncompress *.gz before make delta
	for file in "$delta_dir"/base/*; do
		local filename=$(basename "$file")
		local basefile=$delta_dir/base/$filename
		local newfile=$delta_dir/new/$filename
		if [ x${filename##*.} = x"gz" ]; then
			echo "unzip $basefile"
			gzip -d $basefile
			echo "unzip $newfile"
			gzip -d $newfile
		fi
		if [ x${filename##*.} = x"zst" ]; then
			echo "unzstd $basefile"
			zstd -d $basefile
			echo "unzstd $newfile"
			zstd -d $newfile
		fi
	done

	for file in "$delta_dir"/base/*; do
		local filename=$(basename "$file")
		local basefile=$delta_dir/base/$filename
		local newfile=$delta_dir/new/$filename
		local sigfile=$delta_dir/base_sig/$filename.rdiff.sig
		local deltafile=$delta_dir/delta/$filename.rdiff.delta

		if [ -f "$basefile" ]; then
			${LICHEE_TOP_DIR}/build/swupdate/tools/rdiff signature "$basefile" "$sigfile"
			[ -e "$newfile" ] && {
				echo "prepare $deltafile"
				${LICHEE_TOP_DIR}/build/swupdate/tools/rdiff delta "$sigfile" "$newfile" "$deltafile"
			}
		fi
	done
	ll -h "$delta_dir/delta/"
}

#if break by ctrl + c, please checkout board.dts and mkernel first
function swupdate_make_kernelB_img()
{
	local LICHEE_BOARD_CONFIG_DIR=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_BOARD_CONFIG_DIR=\(.*\)$/\1/g'p)
	local LICHEE_KERN_VER=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_KERN_VER=\(.*\)$/\1/g'p)
	local LICHEE_PLAT_OUT=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_PLAT_OUT=\(.*\)$/\1/g'p)

	local dts_dir=${LICHEE_BOARD_CONFIG_DIR}/${LICHEE_KERN_VER}
	echo "dts dir:${dts_dir}"

	if [ ! -f ${dts_dir}/board-B.dts ]; then
		print_red "should create ${dts_dir}/board-B.dts"
		echo "eg: 1. cp board.dts board-B.dts 2.change board-B.dts node bootargs, set root= to rootfsB"
		return 1
	fi

	echo "copy system A board.dts to .board.dts.backup"
	cp ${dts_dir}/board.dts ${dts_dir}/.board.dts.backup
	cp ${dts_dir}/board-B.dts ${dts_dir}/board.dts

	echo "copy system A sunxi.dtb to .sunxi.dtb.backup"
	cp ${LICHEE_PLAT_OUT}/sunxi.dtb ${LICHEE_PLAT_OUT}/.sunxi.dtb.backup
	echo "copy system A boot.img to .boot.img.backup"
	cp ${LICHEE_PLAT_OUT}/boot.img ${LICHEE_PLAT_OUT}/.boot.img.backup
	echo "create new boot.img for system B"
	${TINA_TOPDIR}/build.sh kernel

	echo "copy boot.img to bootB.img"
	cp ${LICHEE_PLAT_OUT}/boot.img ${LICHEE_PLAT_OUT}/bootB.img

	echo "recover board.dts,sunxi.dtb and boot.img for system A"
	mv ${dts_dir}/.board.dts.backup ${dts_dir}/board.dts
	mv ${LICHEE_PLAT_OUT}/.boot.img.backup ${LICHEE_PLAT_OUT}/boot.img
	mv ${LICHEE_PLAT_OUT}/.sunxi.dtb.backup ${LICHEE_PLAT_OUT}/sunxi.dtb
}

### MAIN ###

# check top of SDK
if [ ! -f "${TINA_TOPDIR}/build/.tinatopdir" ]; then
	echo "ERROR: Not found .tinatopdir"
	return -1;
fi
