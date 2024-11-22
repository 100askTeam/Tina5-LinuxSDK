#!/bin/sh

do_check_vfat(){ # $1 device
	umount /tmp/tempx 2>/dev/null
	mount -t auto $1 /tmp/tempx 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "formating " $1 "to vfat..."
		mkfs.vfat $1
	else
		echo $1 "already format"
		umount /tmp/tempx 2>/dev/null
	fi
}
do_check_ext4(){ # $1 device
	umount /tmp/tempx 2>/dev/null
	mount -t ext4 $1 /tmp/tempx 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "formating " $1 "to ext4..."
		mkfs.ext4 $1
	else
		echo $1 "already format by ext4"
		umount /tmp/tempx 2>/dev/null
	fi
}
do_check_jffs2(){ #1 device
	umount /tmp/tempx 2>/dev/null
	mount -t auto $1 /tmp/tempx 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "formating " $1 "to jffs2..."
		mkdir -p /tmp/jffs2.dir/tmp #mkfs.jffs2 need to point out a directory to copy to image file or local directory(./) defaultly
		mkfs.jffs2 -p -e 0x$(cat /proc/mtd | grep $(basename $1) | awk '{print $3}') -d /tmp/jffs2.dir -o /tmp/jffs2.img
		dd if=/tmp/jffs2.img of=$1
		rm -rf /tmp/jffs2.img /tmp/jffs2.dir
	else
		echo $1 "already format by jffs2"
		umount /tmp/tempx 2>/dev/null
	fi
}
do_check_format_ext4(){ # $1 device
	[ -h $1 ] && {
		lnk=`basename $(readlink $1)`
		#emmc
		[ ${lnk:0:6} = "mmcblk" ] && {
			do_check_ext4 $1
			return
		}
		#nand
		[ ${lnk:0:3} = "ubi" ] && {
			do_check_ext4 $1
			return
		}
		#nor
		[ ${lnk:0:8} = "mtdblock" ] && {
			do_check_jffs2 $1
			return
		}
	}
}
do_check_format_vfat(){ # $1 device
	[ -h $1 ] && {
		lnk=`basename $(readlink $1)`
		#emmc
		[ ${lnk:0:6} = "mmcblk" ] && {
			do_check_vfat $1
			return
		}
		#nand
		[ ${lnk:0:3} = "ubi" ] && {
			do_check_vfat $1
			return
		}
		#nor
		[ ${lnk:0:8} = "mtdblock" ] && {
			do_check_jffs2 $1
			return
		}
	}
}
do_device_node_switch() {
	[ -d /dev/by-name -o -h /dev/by-name/rootfs ] || {
		mkdir -p -m 755 /dev/by-name
		for line in `cat /proc/cmdline`
		do
			if [ ${line%%=*} = 'partitions' ] ; then
				parts=${line##*=}
				part=" "
				while [ "$part" != "$parts" ]
				do
					part=${parts%%:*}
					ln -s "/dev/${part#*@}" "/dev/by-name/${part%@*}"
					parts=${parts#*:}
				done
			fi
		done
	}
}

# eg.. do_format_filesystem /dev/by-name/UDISK vfat
do_format_filesystem() {
    mkdir -p /tmp/tempx

	if [ "$2" = "vfat" ]; then
		do_check_format_vfat $1
	elif [ "$2" = "ext4" ]; then
		do_check_format_ext4 $1
	elif [ "$2" = "jffs2" ]; then
		do_check_jffs2 $1
	fi

    rm -rf /tmp/tempx
}

# eg.. do_mount_filesystem /dev/by-name/UDISK /mnt/UDISK
do_mount_filesystem() {
	[ -h $1 ] && [ -d $2 ] && {
		lnk=`basename $(readlink $1)`
		#emmc
		[ ${lnk:0:6} = "mmcblk" ] && {
			mount -t auto -o rw,async $1 $2
			return
		}
		#nand
		[ ${lnk:0:3} = "ubi" ] && {
			mount -t ubifs -o rw,async $1 $2
			return
		}
		#nor
		[ ${lnk:0:8} = "mtdblock" ] && {
			echo "nor not support mount $1"
			return
		}
	}
}

get_flash_type(){
    local flash="";
    [ -h $1 ] && {
        lnk=`basename $(readlink $1)`
        #emmc
        [ ${lnk:0:6} = "mmcblk" ] && {
            flash="mmcblk"
        }
        #nand
        [ ${lnk:0:3} = "ubi" ] && {
            flash="nand"
        }
        #nor
        [ ${lnk:0:8} = "mtdblock" ] && {
            flash="nor"
        }
    }
    echo "${flash}"
}
