#!/bin/bash
#preconditions and variables received from Vsphere API by powershell (file ps_settings in home directory)
macaddress=`cat /home/rapid/ps_settings.txt | grep macaddress | awk -F"=" '{print $2}'`
new_ip=`cat /home/rapid/ps_settings.txt | grep IP | awk -F"=" '{print $2}'`
new_netmask=`cat /home/rapid/ps_settings.txt | grep netmask | awk -F"=" '{print $2}'`
new_gateway=`cat /home/rapid/ps_settings.txt | grep gateway | awk -F"=" '{print $2}'`
dns=`cat /home/rapid/ps_settings.txt | grep dns | awk -F"=" '{print "nameserver="$2}'` 
#checking and set new network settings
local_macaddress=`cat /sys/class/net/*/address | sed -n 1p` # - mac address from system settings
if [[ $local_macaddress == $macaddress ]]; then
   get_net_settings=`ifconfig -a`
   if [ -n "$get_net_settings" ]; then
   interface=`ifconfig -a | sed -n 1p | awk '{print $1}' | tr ':' ' ' ` #getting network interface name
   ifconfig $interface $new_ip netmask $new_netmask  #setting network settings IP, netmask
   route add default gw $new_gateway $interface #setting configuration of new gateway
   else
   echo -e "---------------------------------------------------------------------------------------\nifconfig or/and route utility is/are not installed on the system, please install net-tools pacckage"
   exit 1
   fi
echo -e "$dns" > /etc/resolv.conf # writing new dns nameservers to resolv.cong
else
echo -e "----------------------------------------\nMAC address is not matching with TCT"
exit 1
fi



 
