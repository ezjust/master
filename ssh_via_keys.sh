#!/bin/bash
#Specify variables by prompting and install sshpass
apt-get -y install sshpass >> /dev/null 2>&1
echo -e "Specify IP address of destanation host:"
read dest_server
echo -e "Specify ssh use to the remote host:"
read user
echo -e "Specify ssh password to the remote host:"
read -s pass

#Create id_rsa key
dir="~/.ssh"
if [ -d "$dir" ]; then
ssh-keygen -t rsa -N "" -f $dir/id_rsa
\cp $dir/id_rsa* /root/.ssh/
else
mkdir -p $dir
ssh-keygen -t rsa -N "" -f $dir/id_rsa
\cp $dir/id_rsa* /root/.ssh/
fi
#copy id_rsa to remote server and check it works
sshpass -p $pass ssh-copy-id -i $dir/id_rsa $user@$dest_server
check1="echo $?"
if [ -n "$check1" ]; then
ssh $user@$dest_server date
echo "!!!SSH successfully configured via rsa keys!!!"
else
echo "something went wrong, check sshpass is installed id_rsa is available into $dir directory"
fi
exit 0

