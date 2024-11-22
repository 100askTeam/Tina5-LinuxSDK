#!/bin/bash

function pack()
{
	local cfg_dir="$(pwd)/image"
	echo "cfg_dir:${cfg_dir}----"
    [ ! -e ${cfg_dir}/.buildconfig ] && \
	echo  "Not found .buildconfig,  Please lunch." &&  \
	return -1;

    local chip=$(cat ${cfg_dir}/.buildconfig | sed -n 's/^.*LICHEE_CHIP=\(.*\)$/\1/g'p)
    local platform=$(cat ${cfg_dir}/.buildconfig | sed -n 's/^.*LICHEE_LINUX_DEV=\(.*\)$/\1/g'p)
    local lichee_ic=$(cat ${cfg_dir}/.buildconfig | \
	    sed -n 's/^.*LICHEE_IC=\(.*\)$/\1/g'p)

    local lichee_board=$(cat ${cfg_dir}/.buildconfig | \
	    sed -n 's/^.*LICHEE_BOARD=\(.*\)$/\1/g'p)

    local lichee_kernel_ver=$(cat ${cfg_dir}/.buildconfig | \
	    sed -n 's/^.*LICHEE_KERN_VER=\(.*\)$/\1/g'p)

    local flash=$(cat ${cfg_dir}/.buildconfig | sed -n 's/^.*LICHEE_FLASH=\(.*\)$/\1/g'p)

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

	echo "pack -c $chip -i ${lichee_ic} -p ${platform} -b ${lichee_board} -k $lichee_kernel_ver -d $debug -v $sigmode -m $mode -w $programmer -n ${flash} ${verity}"
	./build/pack -c $chip -i ${lichee_ic} -p ${platform} -b ${lichee_board} -k $lichee_kernel_ver -d $debug -v $sigmode -m $mode -w $programmer -n ${flash} ${verity}
}

pack "$@"
