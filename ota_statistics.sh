#!/bin/bash
dlist="$HOME/test/devices_list"
ota_list="$HOME/test/OTA_new1"
parsed_data="$HOME/test/parsed_ota_data"
date=`date '+%Y-%m-%d_%H:%M'`
#i=0
ota_pro1=0
ota_pro2=0
ota_pro3=0
ota_pro3_3=0
ota_flc=0
ota_slc=0
ota_jbox=0
ota_orion=0
while read p; do
	mac=`echo $p | cut -d "[" -f2 | cut -d "]" -f1`
	if grep -q -i $mac $dlist; then
		dtype=`cat $dlist | grep -i $mac | awk {'print $1'}`
		ota_count=`cat $ota_list | grep $mac | awk -F'[][]' -v n=2 '{ print $(2*n) }' | awk -F'#' {'print $2'}`
		if grep -q -i $mac $ota_list; then
		echo $dtype $mac $ota_count >> $parsed_data$date
		fi
		if echo $dtype | grep -i -q "jbox"; then
			echo $mac
		fi
		if echo $dtype | grep -i -q "pro1"; then
			ota_pro1=$(($ota_pro1+$ota_count))
		elif echo $dtype | grep -i -q "pro2"; then
                        ota_pro2=$(($ota_pro2+$ota_count))
		elif echo $dtype | grep -i -q "pro3" | grep -v -i "pro3b3"; then
                        ota_pro3=$(($ota_pro3+$ota_count))
		elif echo $dtype | grep -i -q "pro3b3"; then
                        ota_pro3_3=$(($ota_pro3_3+$ota_count))
		elif echo $dtype | grep -i -q "flc"; then
                        ota_flc=$(($ota_flc+$ota_count))
		elif echo $dtype | grep -i -q "slc"; then
                        ota_slc=$(($ota_slc+$ota_count))
		elif echo $dtype | grep -i -q "orion"; then
                        ota_orion=$(($ota_orion+$ota_count))
		elif echo $dtype | grep -i -q "jbox"; then
                        ota_jbox=$(($ota_jbox+$ota_count))
		#i=$((i+1))
		#echo $i
		fi
	else 
		echo "unknown device $mac"
	fi
done < $ota_list
echo -e "In this OTA jenkins job were performed:\n"
echo -e "PRO1=$ota_pro1\nPRO2=$ota_pro2\nPRO3=$ota_pro3\nPRO3b3=$ota_pro3_3\nJBOX=$ota_jbox\nORION=$ota_orion\nFLC=$ota_flc\nSLC=$ota_slc"
