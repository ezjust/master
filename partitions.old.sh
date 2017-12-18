#!/bin/bash

#Investigate if mdadm and lvm2 utilities exist
if [ -n "`rpm -qa`" ]; then
  install=`rpm -qa | grep 'mdadm\|lvm' >> /dev/null 2>&1`
else
  install=`dpkg -l | grep 'mdadm\|lvm' >> /dev/null 2>&1`
fi

if [ -n $install ]; then
  echo "------------------------------------------------"
  echo "lvm and raid utilities exist and ready to use!!!"
  echo "------------------------------------------------"
else 
  echo "---------------------------------------------------------------------"
  echo "Please install lvm and raid utilities to continue disks configuration"
  echo "---------------------------------------------------------------------"
  exit
fi

# Figlet utility installation

if [ -d /etc/zypp/ ];then
  infig=`zypper install figlet`
elif [ -d /etc/dpkg/ ]
then
  infig=`apt-get install figlet`
else
  infig=`yum install figlet`
fi

if [ -n `dpkg -l figlet` ]; then
  echo "----------------"
  echo "figlet installed"
  echo "----------------"
elif [ -n `rpm -qa figlet` ]; then
  echo "----------------"
  echo "figlet installed"
  echo "----------------"
else
  echo "----oops, some errors occurs-----"
exit
fi

#Umount partitions and remove all mount points folders, wipe fs

echo "------------------------------";
echo "OPERATIONS with old partitions";
echo "------------------------------";

umount /mnt/mp_ext2
umount /mnt/mp_ext3
umount /mnt/mp_ext4
umount /mnt/mp_xfs
umount /mnt/mp_btrfs
umount /mnt/mp_md0
umount /mnt/mp_lvm3

rm -rf /mnt/*

mdadm --stop /dev/md0
mdadm --remove /dev/md0

wipefs -a /dev/sdb1
wipefs -a /dev/sdb2
wipefs -a /dev/sdb3
wipefs -a /dev/sdb4
wipefs -a /dev/sdc1

wipefs -a /dev/lvm1/lvm1_xfs >> /dev/null 2>&1
lvremove -f /dev/lvm1/lvm1_xfs
wipefs -a /dev/lvm2/lvm2_ext3 >> /dev/null 2>&1
lvremove -f /dev/lvm2/lvm2_ext3
wipefs -a /dev/lvm3/lvm3_ext4 >> /dev/null 2>&1
lvremove -f /dev/lvm3/lvm3_ext4

vgremove -f lvm1
vgremove -f lvm2
vgremove -f lvm3

pvremove -f /dev/sdc2
pvremove -f /dev/sdc3
pvremove -f /dev/sdc4


for i in {1..4}
do

(echo d; echo $i; echo w;) | fdisk /dev/sdb >> /dev/null 2>&1
sleep 0.1
(echo d; echo $i; echo w;) | fdisk /dev/sdc >> /dev/null 2>&1
sleep 0.1

done

sed -i '/mp\|lvm3_ext/d' /etc/fstab;
sed -i '/md0/d' /etc/mdadm/mdadm.conf >> /dev/null 2>&1
sed -i '/md0/d' /etc/mdadm.conf >> /dev/null 2>&1

echo "-----------------------------";
echo "Disks were successfully wiped";
partprobe
lsblk | grep sd[b-e]
echo "-----------------------------";
sleep 10
#Make new partitions of two disks
echo "------------------------------";
echo "=======Creation section=======";
echo "------------------------------";
echo "!!!!!!!!!!!!!!2 disks should be sized at least 2GB!!!!!!!!!!!!!";

(echo n; echo p; echo 1; echo ; echo 1000000; echo n; echo p; echo 2; echo 1000001; echo 2000000; echo n; echo p; echo 3; echo 2000001; echo 3000000; echo n; echo p; echo 4; echo 3000001; echo 4000000; echo w;)  | fdisk /dev/sdb >> /dev/null 2>&1

sleep 0.1

(echo n; echo p; echo 1; echo ; echo 1000000; echo n; echo p; echo 2; echo 1000001; echo 2000000; echo n; echo p; echo 3; echo 2000001; echo 3000000; echo n; echo p; echo 4; echo 3000001; echo 4000000; echo w;) | fdisk /dev/sdc >> /dev/null 2>&1


sleep 0.1

#Create raid and lvm

pvcreate /dev/sdc2
vgcreate lvm1 /dev/sdc2
lvcreate -n lvm1_xfs -l 100%FREE lvm1
pvcreate /dev/sdc3
vgcreate lvm2 /dev/sdc3
lvcreate -n lvm2_ext3 -l 100%FREE lvm2
pvcreate /dev/sdc4
vgcreate lvm3 /dev/sdc4
lvcreate -n lvm3_ext4 -l 100%FREE lvm3

(echo yes;) | mdadm --create --verbose /dev/md0 --level=1 --raid-disks=2 /dev/lvm1/lvm1_xfs /dev/lvm2/lvm2_ext3
 
#Make fs on those partitions (ext2, ext3, ext4, xfs, btrfs)

mkfs.ext2 /dev/sdb1
mkfs.ext3 /dev/sdb2
mkfs.ext4 /dev/sdb3
mkfs.xfs /dev/sdb4
mkfs.btrfs /dev/sdc1
mkfs.xfs /dev/md0
mkfs.ext4 /dev/lvm3/lvm3_ext4


#Create folders for mount and mount available partitions

mkdir /mnt/mp_ext2
mkdir /mnt/mp_ext3
mkdir /mnt/mp_ext4
mkdir /mnt/mp_xfs
mkdir /mnt/mp_btrfs
mkdir /mnt/mp_md0
mkdir /mnt/mp_lvm3

mount /dev/sdb1 /mnt/mp_ext2
mount /dev/sdb2 /mnt/mp_ext3
mount /dev/sdb3 /mnt/mp_ext4
mount /dev/sdb4 /mnt/mp_xfs
mount /dev/sdc1 /mnt/mp_btrfs
mount /dev/md0 /mnt/mp_md0
mount /dev/lvm3/lvm3_ext4 /mnt/mp_lvm3

mdadm --detail --scan >> /etc/mdadm/mdadm.conf >> /dev/null 2>&1
mdadm --detail --scan >> /etc/mdadm.conf >> /dev/null 2>&1

#Edit fstab

cat /proc/mounts | grep 'mp_\|md0' | awk '{print $1,$2,$3}' | awk '{print $0" defaults 0 0"}' >> /etc/fstab
figlet "completed"
