#!/bin/bash

function build_usage()
{
    printf "Usage: build.sh [args]
    build.sh                       - default build all
    build.sh bootloader            - only build bootloader
    build.sh kernel                - only build kernel
    build.sh buildroot_rootfs      - only build buildroot
    build.sh uboot_menuconfig       - edit uboot menuconfig
    build.sh uboot_saveconfig       - save uboot menuconfig
    build.sh menuconfig            - edit kernel menuconfig
    build.sh saveconfig            - save kernel menuconfig
    build.sh recovery_menuconfig   - edit recovery menuconfig
    build.sh recovery_saveconfig   - save recovery menuconfig
    build.sh buildroot_menuconfig  - edit buildroot menuconfig
    build.sh buildroot_saveconfig  - save buildroot menuconfig
    build.sh clean                 - clean all
    build.sh distclean             - distclean all
    build.sh pack                  - pack firmware
    build.sh pack_debug            - pack firmware with debug info output to card0
    build.sh pack_secure           - pack firmware with secureboot
"

    return 0
}

function pack_usage()
{
    printf "Usage: pack [args]
    pack                           - pack firmware
    pack -d                        - pack firmware with debug info output to card0
    pack -s                        - pack firmware with secureboot
    pack -sd                       - pack firmware with secureboot and debug info output to card0
"
    return 0
}

function build_help()
{
    printf "Invoke . build/quick.sh from your shell to add the following functions to your environment:
    croot                          - Changes directory to the top of the tree
    cbsp                           - Changes directory to the bsp
    cbsptest                       - Changes directory to the bsptest
    ckernel                        - Changes directory to the kernel
    cbrandy                        - Changes directory to the brandy
    cboot                          - Changes directory to the uboot
    cbr                            - Changes directory to the buildroot
    cchips                         - Changes directory to the board
    cconfigs                       - Changes directory to the board's config
    cbin                           - Changes directory to the board's bin
    cdts                           - Changes directory to the kernel's dts
    ckernelout                     - Changes directory to the kernel output
    cout                           - Changes directory to the product's output
    copenssl                       - Changes directory to the product's openssl-1.0.0
"
    build_usage
    pack_usage

    return 0
}

function _load_config()
{
	local cfgkey=$1
	local cfgfile=$2
	local defval=$3
	local val=""

	[ -f "$cfgfile" ] && val="$(sed -n "/^\s*export\s\+$cfgkey\s*=/h;\${x;p}" $cfgfile | sed -e 's/^[^=]\+=//g' -e 's/^\s\+//g' -e 's/\s\+$//g')"
	eval echo "${val:-"$defval"}"
}

function croot()
{
	cd ${TINA_TOPDIR}
}

# same as croot
function cl()
{
	croot
}

# cd current kernel dir
function ckernel()
{
	local dkey="LICHEE_KERN_VER"
	local dval=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1

	cd ${TINA_TOPDIR}/kernel/$dval
}

# same as ck
function ck()
{
	ckernel
}

function ckernelout()
{
	# TODO different linux version
	cd ${TINA_TOPDIR}/out/kernel/build
}

# cd current dts dir
function cdts()
{
	local dkey1="LICHEE_KERN_VER"
	local dkey2="LICHEE_IC"
	local dkey3="LICHEE_BOARD"
	local dkey4="LICHEE_ARCH"
	local dkey5="LICHEE_USE_INDEPENDENT_BSP"

	local dval1=$(_load_config $dkey1 ${TINA_TOPDIR}/.buildconfig)
	local dval2=$(_load_config $dkey2 ${TINA_TOPDIR}/.buildconfig)
	local dval3=$(_load_config $dkey3 ${TINA_TOPDIR}/.buildconfig)
	local dval4=$(_load_config $dkey4 ${TINA_TOPDIR}/.buildconfig)
	local dval5=$(_load_config $dkey5 ${TINA_TOPDIR}/.buildconfig)

	[ -z "$dval1" ] && echo "ERROR: $dkey1 not set in .buildconfig" && return 1
	[ -z "$dval2" ] && echo "ERROR: $dkey2 not set in .buildconfig" && return 1
	[ -z "$dval3" ] && echo "ERROR: $dkey3 not set in .buildconfig" && return 1
	[ -z "$dval4" ] && echo "ERROR: $dkey4 not set in .buildconfig" && return 1

	[ "$dval4" == "riscv64" ] && dval4=riscv
	local dval=${TINA_TOPDIR}/kernel/$dval1/arch/$dval4/boot/dts
	[ "$dval4" == "arm64" ] && dval=$dval/sunxi

	# independent bsp
	[ "$dval5" == "true" ] && dval=${TINA_TOPDIR}/bsp/configs/$dval1/

	cd $dval
}

# cd current product out dir
function cout()
{
	local dkey1="LICHEE_IC"
	local dkey2="LICHEE_BOARD"
	local dkey3="LICHEE_LINUX_DEV"
	local dval1=$(_load_config $dkey1 ${TINA_TOPDIR}/.buildconfig)
	local dval2=$(_load_config $dkey2 ${TINA_TOPDIR}/.buildconfig)
	local dval3=$(_load_config $dkey3 ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval1" ] && echo "ERROR: $dkey1 not set in .buildconfig" && return 1
	[ -z "$dval2" ] && echo "ERROR: $dkey2 not set in .buildconfig" && return 1
	[ -z "$dval3" ] && echo "ERROR: $dkey3 not set in .buildconfig" && return 1

	cd ${TINA_TOPDIR}/out/${dval1}/${dval2}/${dval3}
}

# cd brandy dir
function cbrandy()
{
	local dkey="LICHEE_BRANDY_DIR"
	local dval=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1
	cd $dval
}

function carisc()
{
	cd ${TINA_TOPDIR}/brandy/arisc
}

function cboot()
{
	local dkey1="LICHEE_BRANDY_DIR"
	local dval1=$(_load_config $dkey1 ${TINA_TOPDIR}/.buildconfig)
	local dkey2="LICHEE_BRANDY_UBOOT_VER"
	local dval2=$(_load_config $dkey2 ${TINA_TOPDIR}/.buildconfig)

	[ -z "$dval1" ] && echo "ERROR: $dkey1 not set in .buildconfig" && return 1
	if [ -z $dval2 ];then
		cd $dval1/u-boot-2018
	else
		cd $dval1/u-boot-$dval2
	fi
}

function cbootbsp()
{
	local dkey="LICHEE_BRANDY_DIR"
	local dval=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)

	[ -z "$dval" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1
	cd $dval/u-boot-bsp
}

function cboot0()
{
	local dkey="LICHEE_BRANDY_DIR"
	local dval=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1
	[ -d $dval/spl ] && cd $dval/spl && return 0
	[ -d $dval/spl-pub ] && cd $dval/spl-pub && return 0
	echo "ERROR: spl or spl-pub not found"
}

function copensbi()
{
	local dkey="LICHEE_BRANDY_DIR"
	local dval=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1
	cd $dval/opensbi
}

# cd current product dir
function cchips()
{
	local dkey="LICHEE_IC"
	local dval=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1

	cd ${TINA_TOPDIR}/device/config/chips/${dval}
}

# cd current board config dir
function cconfigs()
{
	local dkey="LICHEE_BOARD_CONFIG_DIR"
	local dval=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1
	cd $dval
}

# same as cconfigs
function cbd()
{
	cconfigs
}

function cbin()
{
	local dkey1="LICHEE_IC"
	local dkey2="LICHEE_BOARD"
	local dval1=$(_load_config $dkey1 ${TINA_TOPDIR}/.buildconfig)
	local dval2=$(_load_config $dkey2 ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval1" ] && echo "ERROR: $dkey1 not set in .buildconfig" && return 1
	[ -z "$dval2" ] && echo "ERROR: $dkey2 not set in .buildconfig" && return 1

	local bins=
	local bin_index1="${TINA_TOPDIR}/device/config/chips/${dval1}/bin"
	local bin_index2="${TINA_TOPDIR}/device/config/chips/${dval1}/configs/${dval2}/bin"
	[ -d ${bin_index1} ] && bins=(${bins[@]} ${bin_index1})
	[ -d ${bin_index2} ] && bins=(${bins[@]} ${bin_index2})
	[ 0 -eq ${#bins[@]} ] && echo "ERROR: Not found bin." && return -1

	# if only one
	[ 1 -eq ${#bins[@]} ] && cd ${bins[0]} && return 0

	local index=
	# if more, and $1 is not null
	# $1 must be number and not eq 0, or not to drop
	echo "$1" | grep [^0-9] >/dev/null || index=$1
	if [ -n "$index" ] ; then
		[ 0 -eq "$index" ] && index= || index=$(($index-1))
		local bin=${bins[${index}]}
		[ -d ${bin} ] && cd ${bin}
		return 0
	fi

	# choose one
	local i=1
	local choice=
	for choice in ${bins[@]}
	do
		echo " $i. $choice"
		i=$(($i+1))
	done
	echo -n "Which would you like? : "
	read index
	index=$(($index-1))

	local bin=${bins[${index}]}
	[ -d ${bin} ] && cd ${bin}
	return 0;
}

# cd buildroot dir
function cbr()
{
	local dkey="LICHEE_BR_DIR"
	local dval=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$dval" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1
	cd $dval
}

# cd bsp dir
function cbsp()
{
	cd ${TINA_TOPDIR}/bsp
}

# cd bsp dir
function copenssl()
{
	cd ${TINA_TOPDIR}/platform/allwinner/openssl/openssl-1.0.0
}

# cd bsptest dir
function cbsptest()
{
	cd ${TINA_TOPDIR}/test/bsptest
}

# cd bsp dir
function cbuild()
{
	cd ${TINA_TOPDIR}/build
}

# cd dsp dir
function cdsp()
{
	cd ${TINA_TOPDIR}/rtos/lichee/dsp
}

# cd rtos dir
function crtos()
{
	cd ${TINA_TOPDIR}/rtos/lichee/rtos
}

# cd rtos-hal dir
function crtos-hal()
{
	cd ${TINA_TOPDIR}/rtos/lichee/rtos-hal
}

######## FUNCTION #########

function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}

function mgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o \( -regextype posix-egrep -iregex '(.*\/Makefile|.*\/Makefile\..*|.*\.make|.*\.mak|.*\.mk|.*\.bp)' -o -regextype posix-extended -regex '(.*/)?soong/[^/]*.go' \) -type f \
        -exec grep --color -n "$@" {} +
}


# print current .buildconfig
function printconfig()
{
	cat ${TINA_TOPDIR}/.buildconfig
}

# save uboot .config to xxx_defconfig
function uboot_saveconfig()
{
	${TINA_TOPDIR}/build.sh uboot_saveconfig $@
}

# run uboot menuconfig
function uboot_menuconfig()
{
	${TINA_TOPDIR}/build.sh uboot_menuconfig $@
}


# save kernel .config to xxx_defconfig
function saveconfig()
{
	${TINA_TOPDIR}/build.sh saveconfig $@
}

# run kernel menuconfig
function menuconfig()
{
	${TINA_TOPDIR}/build.sh menuconfig $@
}

# load kernel xxx_defconfig to .config
function loadconfig()
{
	${TINA_TOPDIR}/build.sh loadconfig $@
}

function mboot0
{
    if [ -d ${TINA_TOPDIR}/brandy/brandy-2.0/spl ];then
        ${TINA_TOPDIR}/build.sh bootloader spl force
    else
        ${TINA_TOPDIR}/build.sh bootloader spl-pub force
    fi
}

function muboot
{
    ${TINA_TOPDIR}/build.sh bootloader uboot force
}

function mboot
{
    ${TINA_TOPDIR}/build.sh bootloader all force
}

function mkernel
{
    ${TINA_TOPDIR}/build.sh kernel
}

function marisc
{
    ${TINA_TOPDIR}/build.sh arisc
}

function mrtos
{
    ${TINA_TOPDIR}/build.sh rtos $@
}

function pack()
{
    check_tina_topdir || return -1
    [ ! -e ${TINA_TOPDIR}/.buildconfig ] && \
	echo  "Not found .buildconfig,  Please lunch." &&  \
	return -1;

    local chip=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_CHIP=\(.*\)$/\1/g'p)
    local platform=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_LINUX_DEV=\(.*\)$/\1/g'p)
    local lichee_ic=$(cat ${TINA_TOPDIR}/.buildconfig | \
	    sed -n 's/^.*LICHEE_IC=\(.*\)$/\1/g'p)

    local lichee_board=$(cat ${TINA_TOPDIR}/.buildconfig | \
	    sed -n 's/^.*LICHEE_BOARD=\(.*\)$/\1/g'p)

    local lichee_kernel_ver=$(cat ${TINA_TOPDIR}/.buildconfig | \
	    sed -n 's/^.*LICHEE_KERN_VER=\(.*\)$/\1/g'p)

    local flash=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_FLASH=\(.*\)$/\1/g'p)

    local debug=uart0
    local sigmode=none
    local verity=
    local mode=normal
    local programmer=none
    local tar_image=none
    unset OPTIND

    while getopts "dsvmwih" arg
    do
        case $arg in
            d)
                debug=card0
                ;;
            s)
                sigmode=secure
                ;;
            v)
                verity="--verity"
                ;;
            m)
                mode=dump
                ;;
            w)
                programmer=programmer
                ;;
            i)
                tar_image=tar_image
                ;;
            h)
                pack_usage
                return 0
                ;;
            ?)
            return 1
            ;;
        esac
    done

	echo "${TINA_TOPDIR}/build/pack -c $chip -i ${lichee_ic} -p ${platform} -b ${lichee_board} -k $lichee_kernel_ver -d $debug -v $sigmode -m $mode -w $programmer -n ${flash} ${verity}"
	cd ${TINA_TOPDIR}/build/
	./pack -c $chip -i ${lichee_ic} -p ${platform} -b ${lichee_board} -k $lichee_kernel_ver -d $debug -v $sigmode -m $mode -w $programmer -n ${flash} ${verity}

	local pack_alone=$(cat ${TINA_TOPDIR}/.buildconfig | sed -n 's/^.*LICHEE_INDEPENDENT_PACK=\(.*\)$/\1/g'p)
	[ "${pack_alone}" = "y" ] && {
		${TINA_TOPDIR}/build/scripts/independently_pack/collect_files.sh
	}
	cd ${TINA_TOPDIR}
}

function fastboot_config()
{
	cconfigs

	local dts="board.dts"
	[ ! -f ${dts} ] && {
		echo "ERROR: no board.dts"
		return 1
	}

	#check is a symbolic link
	[ -h ${dts} ] && {
		dts=$(readlink ${dts})
	}
	#echo "dts:${dts}"

	local tmp_file=".dts_tmp"
	local dram_size
	echo -n "Please input dram size [M]:"
	read dram_size

	if (echo -n $dram_size | grep -q -e "^[0-9][0-9]*$"); then
		echo "dram_size:${dram_size} M bytes"
	else
		echo "Please input number"
		return 1
	fi

	local dram_size_bytes=$(( $dram_size * 1024 * 1024 ))
	local hex_num="0x$(printf "%x" "$((10#$dram_size_bytes))")"
	#echo "dram hex num:${hex_num}"

	echo "add memory node to $dts"
	local dram_node="
	memory@40000000 {
		device_type = \"memory\";
		reg = <0x00000000 0x40000000 0x00000000 ${hex_num}>;
	};"

	local dkey="LICHEE_FLASH"
	local flash_type=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$flash_type" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1

	dkey="LICHEE_KERN_VER"
	local kern_ver=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$kern_ver" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1

	dkey="LICHEE_LINUX_DEV"
	local linux_dev=$(_load_config $dkey ${TINA_TOPDIR}/.buildconfig)
	[ -z "$linux_dev" ] && echo "ERROR: $dkey not set in .buildconfig" && return 1

	local env_file=""
	local env_file_list=(
			${kern_ver}/env-$(echo ${kern_ver} | awk -F '-' '{print $2}').cfg
			${kern_ver}/env.cfg
			${kern_ver}/env_nor.cfg
			env.cfg
			env_nor.cfg
	)
	for file in ${env_file_list[@]}; do
		[ -f ${file} ] && {
			env_file=${file}
			break
		}
	done
	#echo "env_file:${env_file}"

	if [ x"${env_file}" = x"" ]; then
		echo "ERROR: no env.cfg in $(pwd)" && return 1
	fi

	local boot_args_list=(
		earlyprintk
		console
		boot_partition
		root_partition
	)

	for key in ${boot_args_list[@]}; do
		export ${key}="$(grep "${key}=" -m 1 ${env_file} | awk -F '=' '{print $2}')"
		#echo "${key}=${!key}"
	done


	local part_file="sys_partition.fex"
	local dev_name="mmcblk0p"
	local dev_num="0"
	local partitions root_dev
	local boot_type="2"
	[ x"${flash_type}" = x"nor" ] && {
		echo "nor flash"
		part_file="sys_partition_nor.fex"
		dev_name="mtdblock"
		boot_type="3"
	}

	local part_file_list=(
		${linux_dev}/${part_file}
		${kern_ver}/${part_file}
		${part_file}
	)
	for file in ${part_file_list[@]}; do
		[ -f ${file} ] && {
			part_file=${file}
			break
		}
	done
	#echo "part_file:${part_file}"

	[ ! -f ${part_file} ] && {
		echo "ERROR: no ${part_file} in $(pwd)" && return 1
	}

	local tmp_part_file="sys_partition.tmp"
	cp ${part_file} ${tmp_part_file}
	sed -i '/^[\r;]/d' ${tmp_part_file}
	sed -i 's/[ "\r]//g' ${tmp_part_file}

	[ -z "$(grep "UDISK" ${tmp_part_file})" ] && {
		echo -e "\033[47;34m warning no UDISK in ${part_file} \033[0m"
	}

	local part_name_list=$(grep "name" ${tmp_part_file} | awk -F '=' '{print $2}')
	for name in ${part_name_list[@]}; do
		dev_num=$(( dev_num + 1 ))
		#echo "part name:${name}, num:${dev_num}"
		if [ x"${dev_num}" = x"1" ]; then
			partitions=${name}@${dev_name}${dev_num}
		else
			partitions=${partitions}:${name}@${dev_name}${dev_num}
		fi

		[ x"${name}" = x"${root_partition}" ] && {
			root_dev=/dev/${dev_name}${dev_num}
		}
	done
	#echo "root=${root_dev} partitions=${partitions}"

	local chosen_node="
	chosen {
		bootargs = \"earlyprintk=${earlyprintk} initcall_debug=0 console=${console} loglevel=8 root=${root_dev} rootwait init=/init rdinit=/rdinit partitions=${partitions} coherent_pool=16K boot_type=${boot_type} gpt=1\";
	};"

	echo "${chosen_node}""${dram_node}" > ${tmp_file}
	local line=$(grep "compatible" -n -m 1 ${dts} | head -n 1 | awk -F: '{print $1}')
	#add chosen and memory node to dts
	sed -i "${line} r $tmp_file" ${dts}
	rm ${tmp_part_file}
	rm $tmp_file

	#enable sdc2 or spi nor
	local node_status
	if [ x"${flash_type}" = x"nor" ]; then
		node_status=$(awk '/spi0 {/,/}/ {print NR ": " $0}' board.dts | grep "status")
	else
		node_status=$(awk '/sdc2 {/,/}/ {print NR ": " $0}' board.dts | grep "status")
	fi
	#echo "node status:${node_status}"
	line=$(echo ${node_status} | awk -F ':' '{print $1}')
	#echo "status line:${line}"
	sed -i "${line}s/disabled/okay/" ${dts}

	cd - > /dev/null
}

### MAIN ###

# check top of SDK
if [ ! -f "${TINA_TOPDIR}/build/.tinatopdir" ]; then
	echo "ERROR: Not found .tinatopdir"
	return -1;
fi

if [ ! -f $1 ] && [ $1 == "build_help" ] ; then
	build_help
fi
