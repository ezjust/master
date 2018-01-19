#!/bin/bash
#set -x
#Search for disks those would be used in whole script

lsblk
echo -e "!!!Please insert disks for partitions creation.\nSeparate them by coma, like /dev/sdb,/dev/sdc,/dev/sdd\nNOTE there should be three disks with minimum 2GB space on each!!!\nOR press "ENTER" to use default array of disks"
read varname

if [[ -z $varname ]]; then
array=(/dev/sdb /dev/sdc /dev/sdd)
echo -e "Disks would be set by default\ndisk1=${array[0]}\ndisk2=${array[1]}\ndisk3=${array[2]}"
else
IFS=', ' read -r -a array <<< "$varname"
echo -e "disk1=${array[0]}\ndisk2=${array[1]}\ndisk3=${array[2]}"
disk1="${array[0]}"
disk2="${array[1]}"
disk3="${array[2]}"
fi

#Investigate if mdadm and lvm2 utilities exist

utils_yum=$(yum search btrfs | grep -F "x86_64" | cut -d "." -f1 >> /dev/null 2>&1)
utils_zyp=$(zypper search -s btrfs | grep -F "x86_64" | awk -F "|" '{print $2}' | tr -d '[:blank:]' >> /dev/null 2>&1)
utils_apt=$(apt-cache show btrfs* | grep "Source:" | awk -F ": " '{print $2}' | sort -n | sed -n 1p >> /dev/null 2>&1) 

# Function could be created with many arguments it is $1 and then it is uses below with check_codes "rpm -qa" (where check_codes - function name, "rpm -qa" $1 argument)

function check_codes {
        utils=(mdadm lvm2 parted gcc) ;
	for i in "${utils[@]}"; do
        	$1 | grep $i ; ccodes+=($?) ;
        done
	uniq_code=$(echo ${ccodes[@]} | sed 's/ /\n/g' | sort -ur | sed -n 1p)
        }i

if [ -n "`rpm -qa`" ]; then

	centos_release="cat /etc/centos-release"	
	utils+=($utils_yum)

	check_codes "rpm -qa"

	if [ "$uniq_code" -gt "0" -a -n "$centos_release" ]; then
	yum update >> /dev/null 2>&1
	yum -y install ${utils[@]} >> /dev/null 2>&1
	echo "STEP1 lvm2,mdadm,parted,btrfs-progs(tools),gcc are installed, completed"

	elif [ "$uniq_code" -gt "0" ]; then
	zypper update >> /dev/null 2>&1
	unset utils
	utils=(mdadm lvm2 parted gcc)
	utils+=($utils_zyp)
	
	check_codes "rpm -qa"

	zypper -n -y install ${utils[@]} >> /dev/null 2>&1
	echo "STEP1 lvm2,mdadm,parted,btrfs-progs(tools),gcc are installed, completed"
	
	else 
	echo "STEP1 lvm2,mdadm,parted,btrfs-progs,gcc utilities were installed EARLIER, skipped!!!"
	fi
else	
	apt-get update >> /dev/null 2>&1
	utils+=($utils_apt)

	check_codes "dpkg -l"

 	if [ "$uniq_code" -gt "0" ]; then
        apt-get -y ${utils[@]} >> /dev/null 2>&1
        echo "STEP1 lvm2,mdadm,parted,btrfs-progs(tools),gcc are installed, completed"
	else
        echo "STEP1 lvm2,mdadm,parted,btrfs-progs(tools),gcc utilities were installed EARLIER, skipped!!!"
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

umount -a >> /dev/null 2>&1

umount /mnt/mp_unaligned_xfs >> /dev/null 2>&1
umount /mnt/mp_ext3 >> /dev/null 2>&1
umount /mnt/mp_ext4 >> /dev/null 2>&1
umount /mnt/mp_xfs >> /dev/null 2>&1
umount /mnt/mp_btrfs >> /dev/null 2>&1
umount /mnt/mp_lvm1_xfs >> /dev/null 2>&1
umount /mnt/mp_lvm2_ext3 >> /dev/null 2>&1
umount /mnt/mp_md0 >> /dev/null 2>&1
umount /mnt/mp_unaligned_ext3 >> /dev/null 2>&1
umount /mnt/mp_unaligned_ext4 >> /dev/null 2>&1
umount /mnt/mp_unaligned_btrfs >> /dev/null 2>&1

rm -rf /mnt/* >> /dev/null 2>&1

mdadm --stop /dev/md0 >> /dev/null 2>&1
mdadm --remove /dev/md0 >> /dev/null 2>&1

wipefs -a ${disk1}1 >> /dev/null 2>&1
wipefs -a ${disk1}2 >> /dev/null 2>&1
wipefs -a ${disk1}3 >> /dev/null 2>&1
wipefs -a ${disk1}4 >> /dev/null 2>&1
wipefs -a ${disk2}1 >> /dev/null 2>&1
wipefs -a ${disk3}1 >> /dev/null 2>&1
wipefs -a ${disk3}2 >> /dev/null 2>&1
wipefs -a ${disk3}3 >> /dev/null 2>&1

wipefs -a /dev/lvm1/lvm1_xfs >> /dev/null 2>&1
lvremove -f /dev/lvm1/lvm1_xfs >> /dev/null 2>&1
wipefs -a /dev/lvm2/lvm2_ext3 >> /dev/null 2>&1
lvremove -f /dev/lvm2/lvm2_ext3 >> /dev/null 2>&1

vgremove -f lvm1 >> /dev/null 2>&1
vgremove -f lvm2 >> /dev/null 2>&1

pvremove -f ${disk2}2 >> /dev/null 2>&1
pvremove -f ${disk2}3 >> /dev/null 2>&1


for i in {1..4}
do

(echo d; echo $i; echo w;) | fdisk $disk1 >> /dev/null 2>&1
sleep 0.2
(echo d; echo $i; echo w;) | fdisk $disk2 >> /dev/null 2>&1
sleep 0.2
(echo d; echo $i; echo w;) | fdisk $disk3 >> /dev/null 2>&1
sleep 0.2


done

sed -i '/mp\|lvm/d' /etc/fstab; >> /dev/null 2>&1
sed -i '/md/d' /etc/mdadm/mdadm.conf >> /dev/null 2>&1
sed -i '/md/d' /etc/mdadm.conf >> /dev/null 2>&1

echo "STEP2 Disks were successfully wiped, completed"

partprobe >> /dev/null 2>&1
lsblk 
echo "-----------------------------"

#Make new partitions on disks

(echo n; echo p; echo 1; echo 3000; echo 1000000; echo n; echo p; echo 2; echo 1000001; echo 2000000; echo n; echo p; echo 3; echo 2000001; echo 3000000; echo n; echo p; echo 4; echo 3000001; echo 4000000; echo w;)  | fdisk $disk1 >> /dev/null 2>&1

sleep 0.2

(echo n; echo p; echo 1; echo ; echo 1000000; echo n; echo p; echo 2; echo 1000001; echo 2000000; echo n; echo p; echo 3; echo 2000001; echo 2999999; echo n; echo p; echo 4; echo 3000000; echo 4000000; echo w;) | fdisk $disk2 >> /dev/null 2>&1

sleep 0.2

(echo n; echo p; echo 1; echo 25000; echo 999999; echo n; echo p; echo 2; echo 1000000; echo 1999999; echo n; echo p; echo 3; echo 2000000; echo 2999999; echo n; echo p; echo 4; echo 3000000; echo 4000000; echo w;)  | fdisk $disk3 >> /dev/null 2>&1

sleep 0.2


#Create raid and lvm

pvcreate ${disk2}2 >> /dev/null 2>&1
vgcreate lvm1 ${disk2}2 >> /dev/null 2>&1
lvcreate -n lvm1_xfs -l 100%FREE lvm1 >> /dev/null 2>&1
pvcreate ${disk2}3 >> /dev/null 2>&1
vgcreate lvm2 ${disk2}3 >> /dev/null 2>&1
lvcreate -n lvm2_ext3 -l 100%FREE lvm2 >> /dev/null 2>&1

(echo yes;) | mdadm --create --verbose /dev/md0 --level=1 --raid-disks=2 ${disk2}4 ${disk3}4 
 
#Make fs on those partitions (ext2, ext3, ext4, xfs, btrfs)

mkfs.xfs ${disk1}1
mkfs.ext3 ${disk1}2
mkfs.ext4 ${disk1}3
mkfs.xfs ${disk1}4
mkfs.btrfs ${disk2}1
mkfs.xfs /dev/lvm1/lvm1_xfs 
mkfs.ext3 /dev/lvm2/lvm2_ext3
mkfs.ext4 /dev/md0
mkfs.ext3 ${disk3}1
mkfs.ext4 ${disk3}2
mkfs.btrfs ${disk3}3



#Create folders for mount and mount available partitions

mkdir /mnt/mp_unaligned_xfs >> /dev/null 2>&1
mkdir /mnt/mp_ext3 >> /dev/null 2>&1
mkdir /mnt/mp_ext4 >> /dev/null 2>&1
mkdir /mnt/mp_xfs >> /dev/null 2>&1
mkdir /mnt/mp_btrfs >> /dev/null 2>&1
mkdir /mnt/mp_lvm1_xfs >> /dev/null 2>&1
mkdir /mnt/mp_lvm2_ext3 >> /dev/null 2>&1
mkdir /mnt/mp_md0_ext4 >> /dev/null 2>&1
mkdir /mnt/mp_unaligned_ext3 >> /dev/null 2>&1
mkdir /mnt/mp_unaligned_ext4 >> /dev/null 2>&1
mkdir /mnt/mp_unaligned_btrfs >> /dev/null 2>&1

mount ${disk1}1 /mnt/mp_unaligned_xfs >> /dev/null 2>&1
mount ${disk1}2 /mnt/mp_ext3 >> /dev/null 2>&1
mount ${disk1}3 /mnt/mp_ext4 >> /dev/null 2>&1
mount ${disk1}4 /mnt/mp_xfs >> /dev/null 2>&1
mount ${disk2}1 /mnt/mp_btrfs >> /dev/null 2>&1
mount /dev/lvm1/lvm1_xfs /mnt/mp_lvm1_xfs >> /dev/null 2>&1
mount /dev/lvm2/lvm2_ext3 /mnt/mp_lvm2_ext3 >> /dev/null 2>&1
mount /dev/md0 /mnt/mp_md0_ext4 >> /dev/null 2>&1
mount ${disk3}1 /mnt/mp_unaligned_ext3 >> /dev/null 2>&1
mount ${disk3}2 /mnt/mp_unaligned_ext4 >> /dev/null 2>&1
mount ${disk3}3 /mnt/mp_unaligned_btrfs >> /dev/null 2>&1

cp /etc/mdadm/mdadm.conf /etc/mdadm.conf
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
mdadm --detail --scan >> /etc/mdadm.conf 

#Edit fstab

cat /proc/mounts | grep 'mp_\|md0' | awk '{print $1,$2,$3}' | awk '{print $0" defaults 0 0"}' >> /etc/fstab

echo "STEP3 Disks have been partitioned, completed"
exit 0
