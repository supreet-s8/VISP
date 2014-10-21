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
echo "------- CHECKING PATCH -----------"
for i in $col $cmp $col2
do
  echo -n "Version on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tps/bin/pmx.py subshell patch show all patches " | grep atlas2.2.rc5
  echo "============= DONE =============="
  echo ""
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

