#!/bin/bash
#set -x
#BE SURE THAT PREVIOUSLY ssh_via_keys.sh has been PERFORMED SUCCESSFULLY, if yes then dest_server and rsync_server should be not null

#Preconditions

dest_server="10.10.23.185"
rsync_user="rapid"
pwd=`pwd`
rsync_folder="/home/$rsync_user/rsync"

#Check availability of rsync on both servers (works only for debian based OS's), make synchronization via RSYNC

if [ -n "$dest_server" ] && [ -n "$rsync_user" ]; then
soutil_chk=$(dpkg -l | grep rsync)
deutil_chk=$(ssh $rsync_user@$dest_server "rpm -qa | grep rsync")

	if [ -n "$soutil_chk" ] && [ -n "$deutil_chk" ]; then
		echo -e "\e[1mSTEP1 finished\e[0m. Rsync utilities are installed in both source and destination ($dest_server) servers\nSynchronization Started"
		crea_file=$(find /home/rapid/rsync -cmin -10)
		if [ -n "$crea_file" ]; then
			rsync -avrz $rsync_folder $rsync_user@$dest_server:/home/$rsync_user/
			last_com="echo $?"
		else
		echo -e "\e[1mSTEP1 Skipped.\e[0m \e[96mNo new data available for send\e[0m"
		exit 0
		fi	
	elif [ -n "$soutil_chk" ]; then
		echo "\e[1mSTEP1 \e[91mfailed\e[0m. Rsync is not installed on destanation $dest_server server, make utility installation first"
		exit 1
	elif [ -n "$deutil_chk" ]; then
		echo "\e[1mSTEP1 \e[91mfailed\e[0m. Rsync is not installed on source server, make utility installation first"
		exit 1												  
	fi
fi
#Inform by mail and send last log file 

if [[ $last_com -gt 0 ]]; then
	echo -e "\e[1mSTEP2 \e[91mfailed\e[0m. Errors were occured on the file synchronization see info below:\n$rsync_stdout"
	exit 1
elif [[ $last_com -eq 0 ]]; then
	echo -e "\e[1mSTEP2 finished\e[0m. New Data has been successfully send to $dest_server\n you could find new Data into $rsync_folder\nDetails provider below:\n$rsync_stdout"
	exit 0
fi

