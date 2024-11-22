#!/bin/bash

aw_top=${TINA_TOPDIR}
source ${aw_top}/.buildconfig
img_path=${LICHEE_PLAT_OUT}
output_path=${img_path}/aw_pack_src

#echo "aw_top:${aw_top}"
#echo "img_path:${img_path}"
#echo "output_path:${output_path}"

image_dir=image
build_dir=build
device_dir=device/config
tools_dir=tools
out_dir=out
platform_dir=${LICHEE_LINUX_DEV}

#creat dir
rm ${output_path} -r 2>/dev/null
mkdir -p ${output_path}

mkdir -p  ${output_path}/${image_dir}
mkdir -p  ${output_path}/${build_dir}
mkdir -p  ${output_path}/${tools_dir}
mkdir -p  ${output_path}/${out_dir}
mkdir -p  ${output_path}/${platform_dir}

out_image_list=(
boot.img
rootfs.img
rootfs.ext4
rootfs.squashfs
rootfs.ubifs
recovery.img
sunxi.dtb
.buildconfig
arisc
)

function copy_file()
{
	#cp bin dir
	local ic_dir=${output_path}/${device_dir}/chips/${LICHEE_IC}
	mkdir -p ${ic_dir}
	cp -r ${LICHEE_CHIP_CONFIG_DIR}/bin ${ic_dir}

	#cp board config dir
	local board_dir=${ic_dir}/configs
	mkdir -p ${board_dir}
	cp -r ${LICHEE_BOARD_CONFIG_DIR} ${board_dir}
	cp -r ${LICHEE_BOARD_CONFIG_DIR}/../default ${board_dir}

	#cp openwrt boot-resource dir
	local boot_res_dir=${output_path}/${platform_dir}/target/${LICHEE_IC}/${LICHEE_IC}-common/
	mkdir -p ${boot_res_dir}
	cp -r ${aw_top}/${LICHEE_LINUX_DEV}/target/${LICHEE_IC}/${LICHEE_IC}-common/boot-resource ${boot_res_dir}

	#cp usb tools, toc files
	local common_dir=${output_path}/${device_dir}/common
	mkdir -p ${common_dir}
	cp -r ${LICHEE_COMMON_CONFIG_DIR}/tools ${common_dir}
	cp -r ${LICHEE_COMMON_CONFIG_DIR}/toc ${common_dir}

	#cp pack tools
	cp -r ${LICHEE_TOOLS_DIR}/pack ${output_path}/${tools_dir}
	cp -r ${LICHEE_TOOLS_DIR}/build ${output_path}/${tools_dir}

	#cp boot.img rootfs.img and so on
	for file in ${out_image_list[@]} ; do
		cp -r ${LICHEE_PLAT_OUT}/${file} ${output_path}/${image_dir} 2>/dev/null
	done

	#cp pack script
	cp ${aw_top}/build/scripts/independently_pack/aw_pack.sh ${output_path}
	cp ${aw_top}/build/scripts/independently_pack/pack ${output_path}/${build_dir}
	#cp ${aw_top}/build/pack ${output_path}/${build_dir}
	cp ${aw_top}/build/shflags ${output_path}/${build_dir}

	local old_top_dir=${LICHEE_TOP_DIR}
	source ${aw_top}/build/scripts/independently_pack/tmp_buildconfig

	local new_top_dir=${LICHEE_TOP_DIR}
	cp ${aw_top}/build/scripts/independently_pack/tmp_buildconfig ${output_path}/${image_dir}

	local plat_out_dir=${output_path}/${out_dir}/${LICHEE_IC}/${LICHEE_BOARD}/${LICHEE_LINUX_DEV}
	mkdir -p ${plat_out_dir}
	cp ${output_path}/${image_dir}/.buildconfig ${plat_out_dir}/.buildconfig

	#echo "old_top_dir:${old_top_dir}"
	#echo "new_top_dir:${new_top_dir}"
	sed -i "s%${old_top_dir}%${new_top_dir}%g" ${plat_out_dir}/.buildconfig
	local key
	while read line; do
		key=`echo ${line} | awk -F '=' '{print $1}'`
		sed -i "/${key}/d" ${plat_out_dir}/.buildconfig
	done < ${output_path}/${image_dir}/tmp_buildconfig
	cat ${output_path}/${image_dir}/tmp_buildconfig >> ${plat_out_dir}/.buildconfig

}

#main==============================
copy_file

echo '----------partitions image is at----------'
echo -e '\033[0;31;1m'
echo ${output_path}
echo -e '\033[0m'
