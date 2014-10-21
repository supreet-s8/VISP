#!/bin/bash
#----------------------------------------------------------------------------
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
#----------------------------------------------------------------------------


function ICN {

clear
echo "------- CHECKING BUILD VERSION TO TEST ICN CONNECTIVITY WITH ALL NODES -----------"
for i in $cmp $col $col2
do
  echo -n "Version on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID" || echo ""
done

read -p "Continue (y): "
[[ "$REPLY" != "y" ]] && exit 0 
clear

}

ICN

