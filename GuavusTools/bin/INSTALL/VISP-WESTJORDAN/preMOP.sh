#!/bin/bash

IPS="$PWD/IP.sh"
function getHosts()
{
  source ${IPS}
  if [[ $? -ne 0 ]]
  then
    printf "Unable to read source for IP Address List\nCannot continue"
    exit 255
  fi
}
# Get Hosts
getHosts

SSH='ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -l root ';
clear
echo "------- CHECKING BUILD VERSION -----------"
for i in $col $cmp $col2
do
  echo -n "Version on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID" || echo ""
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING HDFS STATUS -----------"
$SSH ${COLVIP} "/opt/hadoop/bin/hadoop dfsadmin -report" | head -12

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING HADDOP PROCESS STATUS -----------"
$SSH ${COLVIP} "ps -ef " | grep java | grep -v grep | awk '{print $NF}'

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
#echo "------- CHECKING INCOMING DATA STATE -----------"

#FILES=0
#echo -n "Waiting for HTTP record files from Allot......."
#while [[ ${FILES} -eq "0"  ]]
#do
#  FILES=`$SSH ${COLVIP} "find /data/pnsa/http -mmin -1 | wc -l " `
#done
#echo -e "done\nRecieved ${FILES} http record files"

#FILES=0
#echo -n "Waiting for PILOT record files from Allot......."
#while [[ ${FILES} -eq "0"  ]]
#do
#  FILES=`$SSH ${COLVIP} "find /data/pnsa/pilot -mmin -1 | wc -l " `
#done
#echo -e "done\nRecieved ${FILES} pilot record files"
#
#read -p "Continue (y): "
#[ "$REPLY" != "y" ] && exit 0 
#clear

echo "------- CHECKING DRBD STATES ---------"
for i in $col ; do
  $SSH ${prefix}${i} "drbd-overview"
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "VISP HEALTH CHECK COMPLETE" 

