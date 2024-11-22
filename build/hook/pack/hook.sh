#!/bin/bash

localpath=$(cd $(dirname $0) && pwd)

support_list=(
	10:android10
	11:android11
	12:android12
	13:android13
	14:android13
)

function detect_support_version()
{
	local fw=$(find $localpath -maxdepth 1 -name "*.img")
	local version v h s
	if [ -n "$fw" ]; then
		echo "Start detect firmware version..."
		if [ "$(echo $fw | wc -w )" -gt 1 ]; then
			echo "Multi firmware file find, please check!"
			return 1
		else
			version=$(grep -aob -m 1 "build.version.release=.*" $fw | awk -F= '{print $2}')
			if [ -z "$version" ]; then
				echo "Cannot detect firmware version!"
				return 1
			fi
			for s in ${support_list[@]}; do
				v=$(awk -F: '{print $1}' <<< $s)
				h=$(awk -F: '{print $2}' <<< $s)
				if [ "$version" == "$v" ]; then
					echo "Support image version[$v], hook version[$h] for image: $fw"
					echo $h > $localpath/match_version
					mv $fw $localpath/$h/
					return 0
				fi
			done
		fi
	else
		return 0
	fi
	echo "Cannot find support pack hook for image version[$version]."
	return 1
}

function run_match_hook()
{
	local version success
	local v h s

	detect_support_version
	[ $? -ne 0 ] && return $?

	if [ ! -f $localpath/match_version ]; then
		echo "Maybe no firmware found & no detect version stored, please check!"
		return 1
	fi

	version="$(cat $localpath/match_version | head -n 1)"
	success="false"
	for s in ${support_list[@]}; do
		v=$(awk -F: '{print $1}' <<< $s)
		h=$(awk -F: '{print $2}' <<< $s)
		if [ "$version" == "$h" ]; then
			echo "Use pack hook version: $version"
			success="true"
			break
		fi
	done

	if [ "$success" == "false" ]; then
		echo "Cannot find the matched hook pack implement!"
		return 1
	fi

	[ ! -d $localpath/$version/override ] && \
	[ -d $localpath/override ] && \
	(cd $localpath && ln -sf override $version/override)

	$localpath/$version/pack_hook.sh $@
}

run_match_hook $@
