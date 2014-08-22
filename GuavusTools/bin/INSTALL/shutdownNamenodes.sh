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

function halt {

clear
echo "------- ISSUING RELOAD HALT ON COLLECTOR NODES -----------"
for i in $col2 $col
do
  echo "Working on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'reload halt' "
  echo "Done"
done

read -p "Continue (y): "
[[ "$REPLY" != "y" ]] && exit 0
clear

}

halt

