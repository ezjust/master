#!/bin/bash
set -x
#BE SURE THAT PREVIOUSLY ssh_via_keys.sh has been PERFORMED SUCCESSFULLY, if yes then dest_server and rsync_server should be not null

#Preconditions

dest_server="192.168.1.12"
rsync_user="ez"
pwd=`pwd`
rsync_folder="/home/$rsync_user/rsync"
recipients="3spirit3@ukr.net, morgun70@ukr.net"
<<<<<<< HEAD
recipients_attach="3spirit3@ukr.net"
=======

>>>>>>> 22dabad699435d898cfe4e01265673c42f76009d
#Check availability of rsync on both servers (works only for debian based OS's), make synchronization via RSYNC

if [ -n "$dest_server" ] && [ -n "$rsync_user" ]; then
soutil_chk=$(dpkg -l | grep rsync)
deutil_chk=$(ssh $rsync_user@$dest_server "rpm -qa | grep rsync")

	if [ -n "$soutil_chk" ] && [ -n "$deutil_chk" ]; then
		echo -e "\e[0m. Rsync utilities are installed in both source and destination ($dest_server) servers\nSynchronization Started"
		rsync_chk_up=$(rsync -avEim --delete $rsync_folder $rsync_user@$dest_server:/home/$rsync_user/)	
		if [ $? -eq 0 ]; then
			if [ -n "$rsync_chk_up" ]; then
<<<<<<< HEAD
				rsync -avrz $rsync_folder $rsync_user@$dest_server:/home/$rsync_user/
				last_com=$(echo $?)
				new_files=(`find $rsync_folder ! -name "*.*" -type f -cmin -10`)
=======
				rsync_stdout=$(rsync -avrz $rsync_folder $rsync_user@$dest_server:/home/$rsync_user/)
				last_com=$(echo $?)
>>>>>>> 22dabad699435d898cfe4e01265673c42f76009d
			else
				echo -e "\e[1mSkipped.\e[0m \e[96mNo new data available for send\e[0m"
				exit 0
			fi
		else
			echo -e " \e[91mOOps someting went wrong!!!unknown error, check rsync mannually\e[0m"
		fi	
	elif [ -n "$soutil_chk" ]; then
		echo "\e[91mfailed\e[0m. Rsync is not installed on destanation $dest_server server, make utility installation first"
		exit 1
	elif [ -n "$deutil_chk" ]; then
		echo "\e[91mfailed\e[0m. Rsync is not installed on source server, make utility installation first"
		exit 1												  
	fi
fi

echo $rsync_stdout

#Inform by mail and send last log file 
#Mutt install and configure to send mails
<<<<<<< HEAD
{
mkdir -p ~/.mutt/cache/headers
mkdir ~/.mutt/cache/bodies
touch ~/.mutt/certificates
cp ~/muttrc ~/.mutt/muttrc
} 2> /dev/null
mutt_check=$(dpkg -l | grep mutt)
if [ -z "$mutt_check" ]; then
        apt-get -y install mutt
fi

DATE=$(date +%Y-%m-%d)
if [[ $last_com -gt 0 ]]; then
	echo -e "\e[91mfailed\e[0m. Errors were occured on the file synchronization see info below:"
	echo "Errors were occured on the file synchronization." | mutt -s "Synchronization FAILED $DATE" $recipients
	exit 1
elif [[ $last_com -eq 0 ]] && [ -n "$new_files" ]; then
	echo -e "\e[1mNew Data has been successfully send to $dest_server\nyou could find new Data into $rsync_folder\nList of synchronized files:\n$new_files\e[0m"
	echo -e "New Data has been successfully send to $dest_server\nyou could find new Data into $rsync_folder\nSynchronized files:\n${new_files[@]}" | mutt -s "Synchronization COMPLETED $DATE" $recipients
	if [ -n "$recipients_attach" ]; then
	echo -e "New Data has been successfully send to $dest_server\nyou could find new Data into $rsync_folder\nSynchronized files:\n${new_files[@]}" | mutt -s "Synchronization COMPLETED $DATE" -a ${new_files[@]} -- $recipients_attach
	fi
=======

mkdir -p ~/.mutt/cache/headers
mkdir ~/.mutt/cache/bodies
touch ~/.mutt/certificates
cp  $dir/muttrc ~/.mutt/muttrc

mutt_check=$(dpkg -l | grep mutt)
if [ -z "$mutt_check"]; then
        apt-get -y install mutt
fi

DATE=$(date +%Y-%m-%d)
if [[ $last_com -gt 0 ]]; then
	mutt_mess=$(echo -e "\e[91mfailed\e[0m. Errors were occured on the file synchronization see info below:\n$rsync_stdout")
	echo -e "Errors were occured on the file synchronization see info below:\n$rsync_stdout" | mutt -s "Synchronization FAILED $DATE" $recipients
	exit 1
elif [[ $last_com -eq 0 ]]; then
	mutt_mess=$(echo -e "\e[1mNew Data has been successfully send to $dest_server\nyou could find new Data into $rsync_folder\nDetails provided below:\n$rsync_stdouti\e[0m")
	echo -e "New Data has been successfully send to $dest_server\nyou could find new Data into $rsync_folder\nDetails provided below:\n$rsync_stdout" | mutt -s "Synchronization COMPLETED $DATE" $recipients
>>>>>>> 22dabad699435d898cfe4e01265673c42f76009d
	exit 0
fi

