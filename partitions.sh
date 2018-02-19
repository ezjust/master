#!/bin/bash
#set -x

#Preconditions
version=$(cat /etc/os-release | grep VERSION_ID | awk -F "=" '{print $2}' | tr -d '"' | cut -d "." -f1 | bc -l)

#Search for disks those would be used in whole script

lsblk
echo -e "Please insert disks for partitions creation.\nSeparate them by coma, like \e[1m/dev/sdb,/dev/sdc,/dev/sdd\nNOTE \e[0mthere should be three disks with minimum 2GB space on each\nOR \e[1mpress "ENTER" to use default array of disks\e[0m"
read varname

if [[ -z $varname ]]; then
array=(/dev/sdb /dev/sdc /dev/sdd)
echo -e "Disks would be set by default\ndisk1=${array[0]}\ndisk2=${array[1]}\ndisk3=${array[2]}"
else
IFS=', ' read -r -a array <<< "$varname"
echo -e "disk1=${array[0]}\ndisk2=${array[1]}\ndisk3=${array[2]}"
fi

disk1="${array[0]}"
disk2="${array[1]}"
disk3="${array[2]}"

#Loading dots part;)

#function loading {

while [ -z "$finecho" ];
do
    finecho=$(cat /tmp/finecho 2>> /dev/null)
    if [ -n "$finecho" ]; then
    	rm -rf /tmp/finecho
	break
    else
    	echo -ne "$1.\r"
    	sleep 0.5
    	echo -ne "$1..\r"
    	sleep 0.5
    	echo -ne "$1...\r"
    	sleep 0.5
    	echo -ne "\r\033[K"
    	echo -ne "$1\r"
    	sleep 0.5
    fi
done &
#}

#loading "Wait for a while, script is in progress" &

#Investigate if mdadm and lvm2 utilities exist

utils_yum=$(yum search btrfs 2> /dev/null | grep -F "x86_64" | cut -d "." -f1)
utils_zyp=$(zypper search -s btrfs 2> /dev/null | grep -F "x86_64" | awk -F "|" '{print $2}' | tr -d '[:blank:]') 
utils_apt=$(apt-cache show btrfs* 2> /dev/null | grep "Source:" | awk -F ": " '{print $2}' | sort -n | sed -n 1p) 

# Function could be created with many arguments it is $1 and then it is uses below with check_codes "rpm -qa" (where check_codes - function name, "rpm -qa" $1 argument)

function check_codes {
        utils=(mdadm lvm2 parted gcc) ;
	for i in "${utils[@]}"; do
        	$1 | grep $i ; ccodes+=($?) ;
        done
	uniq_code=$(echo ${ccodes[@]} | sed 's/ /\n/g' | sort -ur | sed -n 1p)
        }

if [ -n "`rpm -qa 2> /dev/null`" ]; then

	utils+=($utils_yum)

	check_codes "rpm -qa >> /dev/null 2>&1"

	if [ "$uniq_code" -gt "0" -a -n "$utils_yum" ]; then
	yum -y update >> /dev/null 2>&1
	yum -y install ${utils[@]} >> /dev/null 2>&1
	echo -e "\e[1mSTEP1 lvm2,mdadm,parted,btrfs-progs(tools),gcc are installed, \e[30;48;5;82mcompleted\e[0m"

	elif [ "$uniq_code" -gt "0" ]; then
	zypper update >> /dev/null 2>&1
	unset utils
	utils=(mdadm lvm2 parted gcc)
	utils+=($utils_zyp)
	
	check_codes "rpm -qa >> /dev/null 2>&1"

	zypper -n -y install ${utils[@]} >> /dev/null 2>&1
	echo -e "\e[1mSTEP1 lvm2,mdadm,parted,btrfs-progs(tools),gcc are installed, \e[30;48;5;82mcompleted\e[0m"
	
	else 
	echo -e "STEP1 lvm2,mdadm,parted,btrfs-progs,gcc utilities were installed EARLIER, \e[1mskipped!!!"
	fi
else	
	apt-get update >> /dev/null 2>&1
	utils+=($utils_apt)

	check_codes "dpkg -l >> /dev/null 2>&1"

 	if [ "$uniq_code" -gt "0" ]; then
        apt-get -y ${utils[@]} >> /dev/null 2>&1
        echo -e "\e[1mSTEP1 lvm2,mdadm,parted,btrfs-progs(tools),gcc are installed, \e[30;48;5;82mcompleted\e[0m"
	else
        echo -e "\e[1mSTEP1 lvm2,mdadm,parted,btrfs-progs(tools),gcc utilities were installed EARLIER, \e[1mskipped!!!"
        fi
fi

unset ccodes

#Figlet utility installation

#pwd=$(pwd)
#wget ftp://ftp.figlet.org/pub/figlet/program/unix/ >> /dev/null 2>&1
#fig_link=$(cat index.html | grep "tar.gz" | sort -r | sed -n 1p | grep -oP '"\K.*?(?=")')
#wget $fig_link >> /dev/null 2>&1
#tar -xzvf figlet*.tar.gz >> /dev/null 2>&1
#cd figlet*
#make >> /dev/null 2>&1
#make install >> /dev/null 2>&1

#if [ $? -eq 0 ]; then
#find $pwd -name "figlet*.gz" -exec rm -rf {} \; >> /dev/null 2>&1
#find $pwd -name "index*.html*" -exec rm -rf {} \; >> /dev/null 2>&1

#figlet="/usr/local/bin/figlet -f slant"

#$figlet "test"
#else
#echo "error occured on figlet compiling, check gcc compiler and logs"
#fi


#Umount partitions and remove all mount points folders, wipe fs

function umount_parts {
	{
	umount -a

	umount /mnt/mp_xfs
	umount /mnt/mp_ext3
	umount /mnt/mp_ext4
	umount /mnt/mp_unaligned_$1
	umount /mnt/mp_unaligned_$3
	umount /mnt/mp_lvm1_ext3
	umount /mnt/mp_lvm2_xfs
	umount /mp_lvm5_ext4_mirrored
	umount /mnt/mp_md0_ext4
	umount /mnt/mp_md1_xfs
	umount /mnt/mp_unaligned_ext3
	umount /mnt/mp_unaligned_ext4
	umount /mnt/mp_unaligned_$2


	rm -rf /mnt/*

	mdadm --stop /dev/md0
	mdadm --remove /dev/md0
	mdadm --stop /dev/md1
	mdadm --remove /dev/md1


	wipefs -a ${disk1}1
	wipefs -a ${disk1}2
	wipefs -a ${disk1}3
	wipefs -a ${disk1}4
	wipefs -a ${disk2}1
	wipefs -a ${disk3}1
	wipefs -a ${disk3}2
	wipefs -a ${disk3}3

	wipefs -a /dev/lvm1/lvm1_ext3
	lvremove -f /dev/lvm1/lvm1_ext3
	wipefs -a /dev/lvm1/lvm2_xfs
	lvremove -f /dev/lvm1/lvm2_xfs
	wipefs -a /dev/lvm2_stripped/lvm3_ext4
	lvremove -f /dev/lvm2_stripped/lvm3_ex4
	wipefs -a /dev/lvm2_stripped/lvm4_xfs
	lvremove -f /dev/lvm2_stripped/lvm4_xfs
	wipefs -a /dev/lvm3/lvm5_ext4_mirrored
	lvremove -f /dev/lvm3_mirrored/lvm5_ext4_mirrored

	vgremove -f lvm1
	vgremove -f lvm2_stripped
	vgremove -f lvm3_mirrored

	pvremove -f ${disk2}2
	pvremove -f ${disk2}3
	pvcreate -f ${disk2}5
	pvcreate -f ${disk2}6
	pvcreate -f ${disk2}7
	pvcreate -f ${disk2}8
	pvcreate -f /dev/md2

	mdadm --stop /dev/md2
	mdadm --remove /dev/md2
	
	} >> /dev/null 2>&1

}


if [ -n "$utils_zyp" -a "$version" -lt 12 ] || [ -n "$utils_yum" -a "$version" -lt 7  ] || [ -n "$utils_apt" -a "$version" -lt 8 ]; then

umount_parts "ext3" "xfs" "ext4"

else

umount_parts "ext2" "btrfs" "xfs"

fi

sync; echo 1 > /proc/sys/vm/drop_caches

partprobe


for i in {1..8}
do

(echo d; echo $i; echo w;) | fdisk $disk1 >> /dev/null 2>&1
sleep 0.2
(echo d; echo $i; echo w;) | fdisk $disk2 >> /dev/null 2>&1
sleep 0.2
(echo d; echo $i; echo w;) | fdisk $disk3 >> /dev/null 2>&1
sleep 0.2


done
{
sed -i '/mp\|lvm/d' /etc/fstab;
sed -i '/md/d' /etc/mdadm/mdadm.conf
sed -i '/md/d' /etc/mdadm.conf
} >> /dev/null 2>&1
echo -e "\e[1mSTEP2 Disks were successfully wiped, \e[30;48;5;82mcompleted\e[0m"

partprobe >> /dev/null 2>&1

#Make new partitions on disks

(echo n; echo p; echo 1; echo ; echo 1000000; echo n; echo p; echo 2; echo 1000001; echo 2000000; echo n; echo p; echo 3; echo 2000001; echo 3000000; echo n; echo p; echo 4; echo 3000011; echo 4000000; echo w;)  | fdisk -u $disk1 >> /dev/null 2>&1

sleep 0.2

(echo n; echo p; echo 1; echo 2500; echo 1000000; echo n; echo p; echo 2; echo 1000001; echo 2000000; echo n; echo p; echo 3; echo 2000001; echo 2999999; echo n; echo e; echo 3002048; echo 4000000; echo n; echo ; echo 3290000; echo n; echo ; echo 3490000; echo n; echo ; echo 3790000; echo n; echo ; echo 4000000; echo w;) | fdisk -u $disk2 >> /dev/null 2>&1

sleep 0.2

(echo n; echo p; echo 1; echo 3000; echo 999999; echo n; echo p; echo 2; echo 1000000; echo 1999999; echo n; echo p; echo 3; echo 2000000; echo 2999999; echo n; echo e; echo 4; echo 3002048; echo 4000000; echo n; echo ; echo 3290000; echo n; echo ; echo 3490000; echo n; echo ; echo 3790000; echo n; echo ; echo 4000000; echo w;)  | fdisk -u $disk3 >> /dev/null 2>&1

sleep 0.2

function parts_creation {

#Create raid and lvm
	{
	pvcreate ${disk2}2
	pvcreate ${disk2}3
	vgcreate lvm1 ${disk2}2 ${disk2}3
	lvcreate -n lvm1_ext3 -l 50%FREE lvm1
	lvcreate -n lvm2_xfs -l 50%FREE lvm1

	pvcreate ${disk2}5
	pvcreate ${disk2}6
	vgcreate lvm2_stripped ${disk2}5 ${disk2}6
	lvcreate -i 2 -n lvm3_ext4 -l 50%FREE lvm2_stripped
	lvcreate -i 2 -n lvm4_xfs -l 50%FREE lvm2_stripped

	(echo yes;) | mdadm --create --verbose /dev/md0 --level=1 --raid-disks=2 ${disk3}5 ${disk3}6
	(echo yes;) | mdadm --create --verbose /dev/md1 --level=0 --raid-disks=2 /dev/lvm2_stripped/lvm3_ext4 /dev/lvm2_stripped/lvm4_xfs
	(echo yes;) | mdadm --create --verbose /dev/md2 --level=0 --raid-disks=2 ${disk3}7 ${disk3}8

	pvcreate ${disk2}7
	pvcreate ${disk2}8
	#pvcreate /dev/md2
	#vgcreate lvm3 /dev/md2 ${disk2}7 ${disk2}8
	vgcreate lvm3_mirrored ${disk2}7 ${disk2}8
	#lvcreate -L 300MB -T lvm3/thinpool
	#lvcreate -n lvm5_ext4 -V 300M --thin lvm3/thinpool
	lvcreate -m1 -n lvm5_ext4_mirrored -l 40%FREE lvm3_mirrored

 
#Make fs on those partitions (ext2, ext3, ext4, xfs, btrfs)

		
	mkfs.xfs ${disk1}1 
	mkfs.ext3 ${disk1}2
	mkfs.ext4 ${disk1}3
	mkfs.$1 ${disk1}4
	mkfs.$3 ${disk2}1
	mkfs.ext3 /dev/lvm1/lvm1_ext3
	mkfs.xfs /dev/lvm1/lvm2_xfs
	mkfs.ext4 /dev/lvm3_mirrored/lvm5_ext4_mirrored
	mkfs.ext4 /dev/md0
	mkfs.xfs /dev/md1
	mkfs.ext3 /dev/md2
	mkfs.ext3 ${disk3}1
	mkfs.ext4 ${disk3}2
	mkfs.$2 ${disk3}3


#Create folders for mount and mount available partitions

	mkdir /mnt/mp_xfs 
	mkdir /mnt/mp_ext3
	mkdir /mnt/mp_ext4
	mkdir /mnt/mp_unaligned_$1
	mkdir /mnt/mp_unaligned_$3
	mkdir /mnt/mp_lvm1_ext3 
	mkdir /mnt/mp_lvm2_xfs
	#mkdir /mnt/mp_thin_lvm5_ext4
	mkdir /mnt/mp_lvm5_ext4_mirrored
	mkdir /mnt/mp_md0_ext4
	mkdir /mnt/mp_md1_xfs
	mkdir /mnt/mp_md2_ext3
	mkdir /mnt/mp_unaligned_ext3
	mkdir /mnt/mp_unaligned_ext4
	mkdir /mnt/mp_unaligned_$2

	mount ${disk1}1 /mnt/mp_xfs
	mount ${disk1}2 /mnt/mp_ext3
	mount ${disk1}3 /mnt/mp_ext4
	mount ${disk1}4 /mnt/mp_unaligned_$1
	mount ${disk2}1 /mnt/mp_unaligned_$3
	mount /dev/lvm1/lvm1_ext3 /mnt/mp_lvm1_ext3
	mount /dev/lvm1/lvm2_xfs /mnt/mp_lvm2_xfs
	mount /dev/lvm3_mirrored/lvm5_ext4_mirrored /mnt/mp_lvm5_ext4_mirrored
	mount /dev/md0 /mnt/mp_md0_ext4
	mount /dev/md1 /mnt/mp_md1_xfs
	mount /dev/md2 /mnt/mp_md2_ext3

	mount ${disk3}1 /mnt/mp_unaligned_ext3
	mount ${disk3}2 /mnt/mp_unaligned_ext4
	mount ${disk3}3 /mnt/mp_unaligned_$2

	} >> /dev/null 2>&1

}
#Edit fstab 

if [ -n "$utils_zyp" -a "$version" -lt 12 ] || [ -n "$utils_yum" -a "$version" -lt 7  ] || [ -n "$utils_apt" -a "$version" -lt 8 ]; then

parts_creation "ext3" "xfs" "ext4"

else

parts_creation "ext2" "btrfs" "xfs" 

fi

{
cp /etc/mdadm/mdadm.conf /etc/mdadm.conf
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
mdadm --detail --scan >> /etc/mdadm.conf 
} 2> /dev/null

mounts=(`cat /proc/mounts | grep 'mp_' | awk '{print $1}' | tr '\n' ' '`)

for i in "${mounts[@]}"; do
        uuid=$(blkid -o export $i | grep "^UUID=")
        mpoint=$(cat /proc/mounts | grep $i | awk '{print $2,$3}' | awk '{ print $0" defaults 0 0"}')
        echo -e "$uuid $mpoint\n" >> /etc/fstab
done


echo -e "\e[1mSTEP3 Disks have been partitioned, \e[30;48;5;82mcompleted\e[0m"
echo 1 > /tmp/finecho
sleep 1 
echo -e "\e[30;48;5;82mFinished!\e[0m"
exit 0
