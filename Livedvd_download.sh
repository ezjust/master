#!/bin/bash
#set -x
function get_branch_a_build {
FILE="TC.log"
username="dev-softheme"
branch="$1"
link="https://tc.appassure.com/viewType.html?buildTypeId=AppAssure_Linux_$2"
wget -O "$FILE" --auth-no-challenge --no-check-certificate --http-user=$username --http-passwd=123asdQ $link > /dev/null 2>&1
id=`cat TC.log | grep "build:" | grep -E -o "buildId=[[:digit:]]*" | sort -n -r | cut -d "=" -f2 | sed -n $4p`
build=`cat $FILE | grep -E -o "#$3-$1.[[:digit:]]*" | cut -d "." -f4 | sed -n 1p`
echo "Retrieving of the $branch.$build LiveDVD"
#rm -r $FILE # cleanup html page, since it is not needed anymore

build_link="https://tc.appassure.com/repository/download/AppAssure_Linux_$2/$id:id/rapidrecovery-livedvd-$branch.$build.iso"
error_code=`wget --auth-no-challenge --no-check-certificate --http-user=$username --http-passwd=123asdQ -q --spider $build_link; echo $?`

echo $build_link


    while [[ $error_code -ne 0 ]] && [[ $int -lt 10 ]]; do
	let "int=int+1"
	build=$(($build -1))
	build_link="https://tc.appassure.com/repository/download/AppAssure_Linux_$2/$id:id/rapidrecovery-livedvd-$branch.$build.iso"	
	error_code=`wget --auth-no-challenge --no-check-certificate --http-user=$username --http-passwd=123asdQ -q --spider $build_link; echo $?`
	echo $build_link
	echo "Retrieving of the $branch.$build LiveDVD"
    done

dest_folder="/media/linux_share/LiveDVD_images"
chk_file_ex="$dest_folder/rapidrecovery-livedvd-$branch.$build.iso"
int=0
echo $chk_file_ex
   if [ -f $chk_file_ex ]; then
      echo -e "\e[0;33mFile $branch.$build.iso exists\e[0m"
      return 0
   elif [[ -z $chk_file_ex ]] && [[ $error_code -eq 0 ]]; then
      echo "Retrieving of the $branch.$build LIVEDVD iso has been completed. $branch.$build LiveDVD starts to be downloaded."
      aria2c -d $dest_folder -x 16 --http-user=$username --http-passwd=123asdQ $build_link --allow-overwrite=true --out="rapidrecovery-livedvd-$branch.$build.iso"
      find $dest_folder -name 'rapidrecovery*' -mtime +0 | xargs rm -rf
      return 0
   else
      date=`date`
      echo "$date download of liveDVD $branch.$build.iso failed, id $id doesn't match any build, check TCT for details" >> /var/log/livedvd_error.log
      echo -e "\e[0;31mLiveDVD failed to be downloaded, something wrong with builds on TCT for $branch branch\e[0m" 
      return 1
   fi
}


get_branch_a_build "6.2.0" "Release700_AgentBuilds_Debian8x64" "release" "3"

get_branch_a_build "7.1.0" "RebrandedDevelop_AgentBuilds_Debian8x64" "develop" "1"


#Move LiveDVD to QAshare folder, if it is no need to make such operation, please comment all fields below with #

#dest_folder=/media/linux_share/LiveDVD_images/
#mv rapidrecovery-livedvd-$branch.$build.iso $dest_folder


