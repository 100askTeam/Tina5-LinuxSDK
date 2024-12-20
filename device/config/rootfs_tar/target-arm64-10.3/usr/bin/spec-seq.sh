#!/bin/sh

get_total()
{
    df -k ${dir} 2>/dev/null | tail -n 1 | awk '{print $2}'
}

get_free()
{
    df -k ${dir} 2>/dev/null | tail -n 1 | awk '{print $4}'
}

get_ddr()
{
    awk '/^MemTotal/{print $2}' /proc/meminfo
}

get_flash()
{
    df -k ${dir} 2>/dev/null | tail -n 1 | awk '{print $1}'
}

get_fs()
{
    df -T ${dir} 2>/dev/null | tail -n 1 | awk '{print $2}'
}

get_r_speed()
{
    grep "kB *reclen" -A 1 $1 | tail -n 1 | awk '{print $5}'
}

get_w_speed()
{
    grep "kB *reclen" -A 1 $1 | tail -n 1 | awk '{print $3}'
}

get_test_size()
{
    # suggest 2 times bigger than free ddr
    local size_k="$(( ${ddr_k} * 2 ))"

    # if no enough space in flash, set to 1 times bigger than free ddr
    [ "${size_k}" -gt "${free_k}" ] && size_k="$(( ${ddr_k} * 1 ))"

    # if still no enough space in flash, set to 95% of free flash
    [ "${size_k}" -gt "${free_k}" ] && size_k=$(( ${free_k} * 95 / 100 ))

    # if vfat-fs and bigger than 3.9G, set around 3.9G
    [ "${fs}" = "vfat" -a "${size_k}" -gt $(( 3 * 1024 * 1024 + 921 * 1024 )) ] \
        && size_k=$(( 3 * 1024 * 1024 + 921 * 1024 ))

    # iozone创建文件会是 buffer 的倍数
    # 例如，测试文件大小为 4101KB，
    # 如果buffer为4M，则实际创建 4096KB的文件
    # 如果buffer为4K，则实际创建 4100KB的文件
    size_k=$(( ${size_k} / ${blk} * ${blk} ))

    echo ${size_k}
}

get_info()
{
    tt_base="/spec/storage/seq"
    #dir=`mjson_fetch ${tt_base}/check_directory`
    #blk=`mjson_fetch ${tt_base}/block_size_kb`
    #avg=`mjson_fetch ${tt_base}/times_for_average`
    #fast=`mjson_fetch ${tt_base}/fast_mode`
    #dir="/mnt"
    blk=4096
    #avg=3
    fast=false
    total_k="$(get_total)"
    free_k="$(get_free)"
    ddr_k="$(get_ddr)"
    fs="$(get_fs)"
    flash="$(get_flash)"

    [ -z "${dir}" ] \
        && echo "Lose directory, set in default: /mnt/UDISK" \
        && dir="/mnt/UDISK"
    [ -z "${blk}" ] \
        && echo "Lose block size, set in default: 4M" \
        && blk=4096
    [ -z "${avg}" ] \
        && echo "Lose times for average, set in default: 3" \
        && avg=3
    [ -z "${fast}" ] && fast="false"

    ! [ -d "${dir}" ] \
        && echo "No Found: ${dir}, quit!!" \
        && exit 1

    # test size depends on free flash, total ddr fs and blk.
    test_k="$(get_test_size)"

    echo "------------------- INFO -------------------"
    echo "fast mode: ${fast}"
    echo "ddr total size: ${ddr_k} KB"
    echo "flash device: ${flash}"
    echo "flash device fs: ${fs}"
    echo "flash device size: ${total_k} KB"
    echo "flash device free: ${free_k} KB"
    echo "test directory: ${dir}"
    echo "test file size: ${test_k} KB"
    echo "test block size: ${blk} KB"
    echo "test times for average: ${avg}"
    echo "------------------- END -------------------"
}

wait_end()
{
    local size=$1
    local sec=0
    while true
    do
        if [ $(( ${sec} % 10 )) -eq 0 ]; then
            echo -ne "\r$2 .         "
            echo -ne "\b\b\b\b\b\b\b\b\b"
        else
            echo -n '.'
        fi
        [ -d "/proc/$!" ] || break
        sleep 1
        sec=$(( sec + 1 ))
    done
    echo " OK (${size}KB in ${sec}s)"
    echo
}

do_test()
{
    # if flash used space is over 1/2 for MLC/TLC, the speed will drop.
    # So, we should ensure that flash used space is over 1/2
    if [ "${fast}" != "true" ]; then
        # if flash used space is over 1/2 for MLC/TLC, the speed will drop.
        # So, we should ensure that flash used space is over 1/2
        cnt=$(( (${free_k} - ${test_k}) / 512 * 95 / 100 ))
        [ "${cnt}" -gt "$(( ${free_k} / 2 ))" ] && cnt=$(( ${free_k} / 2 ))
        dd if=/dev/zero of=${dir}/dd.fill bs=512K conv=fsync count=${cnt} &>/dev/null &
        wait_end "$(( ${cnt} * 512 ))" "filling"
    fi

    log="/tmp/spec-seq.log"
    args="-a -i 0 -i 1 -o -e -+r -s ${test_k}k -r ${blk}k -f ${dir}/iozone.tmp"
    r_speed_sum_k=0
    w_speed_sum_k=0
    for one in $(seq ${avg})
    do
        echo
        echo "=========== the ${one} times ==========="
        # free memory
        echo
        echo "clear cache"
        echo "sync"
        time sync
        echo 3 > /proc/sys/vm/drop_caches
        echo

        # do test
        rm ${log} &>/dev/null
        iozone ${args} | tee ${log}
        r_speed_sum_k="$(( ${r_speed_sum_k} + $(get_r_speed ${log}) ))"
        w_speed_sum_k="$(( ${w_speed_sum_k} + $(get_w_speed ${log}) ))"
    done
    rm -f ${log}
    rm -f ${dir}/dd.fill

    r_speed_k=$(( ${r_speed_sum_k} / ${avg} ))
    w_speed_k=$(( ${w_speed_sum_k} / ${avg} ))
    echo "------------------- SEQ SPEED -------------------"
    echo "seq read: ${r_speed_k} KB/s"
    echo "seq write: ${w_speed_k} KB/s"
    echo "------------------- end -------------------"
}

# ====================== begin here ======================
if [ $# -ne 2 ];then
    echo "pls input: $0 directory test_times, for example: $0 /mnt 3"
    exit 1
else
    dir=$1
    avg=$2
fi
get_info
do_test
