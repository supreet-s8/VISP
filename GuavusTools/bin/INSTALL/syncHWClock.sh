#!/bin/bash

#----------------------------------------------------------------------
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
#----------------------------------------------------------------------

for i in $col $cmp $col2
do
  echo "Syncing HW Clock on ${prefix}${i}"
  ssh -q -l root ${prefix}${i} "mount -o remount,rw / && [[ -L /dev/rtc ]] || ln -s /dev/rtc0 /dev/rtc" 
  ssh -q -l root ${prefix}${i} "hwclock --systohc && hwclock --show && date"
  if [[ $? -ne 0 ]]
  then
    printf "Unable to setup HW clock on ${prefix}${i}\n"
  fi
done
