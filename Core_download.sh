#!/bin/bash

#preconditions

FILE="TC.log"
username="mbugaiov"
branch="7.0.0"
link="https://tc.appassure.com/viewType.html?buildTypeId=AppAssure_Windows_Develop_FullBuild"
notify="/home/ez/Downloads/agents/develop_core_installer/notify_me.txt"
recipients="3spirit3@ukr.net, alexey.sviderskiy@softheme.com maxim.bugaiov@softheme.com"

download new installer from teamcity
wget --no-check-certificate --user=mbugaiov --password=123asdQQ\!@#$ $link -O "$FILE"
build=`cat $FILE | grep -E -o "#develop-7.0.0.[[:digit:]]*" | cut -d "." -f4 | sed -n 1p`
build_link="https://tc.appassure.com/repository/download/AppAssure_Windows_Develop_FullBuild/latest.lastSuccessful/installers/Core-X64-$branch.$build.exe"
error_code=`wget --no-check-certificate --user=mbugaiov --password=123asdQQ\!@#$ -q --spider $build_link; echo $?`

#looking for valid link on teamcity
while [ $error_code != 0 ]
do
        build=$(($build -1))
        build_link="https://tc.appassure.com/repository/download/AppAssure_Windows_Develop_FullBuild/latest.lastSuccessful/installers/Core-X64-$branch.$build.exe"
        error_code=`wget --no-check-certificate --user=mbugaiov --password=123asdQQ\!@#$ -q --spider $build_link; echo $?`
        echo "Retrieving of the $branch.$build Core"
done

echo "Retrieving of the $branch.$build Core build has been completed. $branch.$build Core starts to be downloaded."
dest_folder="/home/ez/Downloads/agents/develop_core_installer/new_installers"
aria2c -x 16 -d $dest_folder --http-user=$username --http-passwd=123asdQQ\!@#$ $build_link
echo "$branch.$build successfully downloaded." > $notify

#synchronization between folder with new core installers and folder where from files would be moved to windows machine

new_inst="/home/ez/Downloads/agents/develop_core_installer/new_installers/"
chmod -R 755 $new_inst
chown -R ez:ez $new_inst
newfile=`find /home/ez/Downloads/agents/develop_core_installer/new_installers/*.exe -type f -mmin -60 | sort -r | sed -n 1p`
scp $newfile ez@10.10.61.30:/C:/core_builds/Core-X64.exe
find $new_inst -name '*.exe' -mtime +2 | xargs rm -rf
echo "New core installer $branch.$build moved to windows machine" >> $notify

#   core installer bat script execution

ssh ez@10.10.61.30 "C:\core_builds\installation.bat" 

#  notification to email

scp ez@10.10.61.30:/C:/core_builds/successful_job.txt $files.windows_suc_job.txt && cat $files.windows_suc_job.txt >> $notify
cat $notify | mutt -s "DEVELOP CORE UPGRADED!!!" $recipients
exit


