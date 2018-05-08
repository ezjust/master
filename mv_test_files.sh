#!/bin/bash

#set -x

echo -e "\e[33mSpecify partition's mount points to copy there test files.\e[0m\nMultiple partitions separates by coma. For example /mnt/test1,/mnt/test2\nOr leave empty to copy test files to all mounted partitions.\nIn this case system partitions /boot, /boot/efi, swap etc will be ignored, except root / partition, file will be located into /home :"
read -p "" mount
echo -e "\e[33mSpecify destination filename, for example test.txt\e[0m\nWARNING: use single filename for every iteration:"
read -p "" test_file

echo -e "\e[33mSpecify file size in MB\e[0m, for example 10 or 100 or 19:"
read -p "" size

if [[ -z $test_file ]]; then
	echo "No filename provided. Pleae specify filename next time"
	exit 1
fi

if [[ -z $mount ]]; then
	mount=($(cat /proc/mounts | grep "/dev/sd" | awk '{print $2}' | grep -vE "*boot*|*dev*|*sys*|*proc*|*tmp*|*var*|*usr*"))
fi

if [[ -z $size ]]; then
	size=100
	echo "Size of file was not set mannualy, it will be used by default as 100MB"
fi

for i in "${mount[@]}"; do

	if [[ "$i" == '/' ]]; then
		path="/tmp/$test_file"
		dd if=/dev/urandom of=$path bs=1M count=$size
	else
		path="$i/$test_file"
		dd if=/dev/urandom of=$path bs=1M count=$size
	fi

	echo -e "`date +\"%m-%d-%y %T\"` `md5sum $path`\n--------------------------------------------------" >> files_md5sums

done


exit 0

