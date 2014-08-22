#!/bin/bash 
#
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
clear
SSH='ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -l root ';
##########################################################################


function secure {
for i in $col $cmp
do
echo -n "Enabling enhanced security at ${prefix}${i} : "
$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'ssh server security-feature enable' 'wr mem'"
if [[ $? -eq '0' ]]; then 
echo "DONE!"
else
echo "Error: Unable to enable security feature at this node. Skipping..."
fi
done
}

echo ""
echo -e "\e[0;31m\033[1mWARNING\e[0m\033[0m : Enabling enhanced security will block the direct login to machines via admin/root user...!"
echo ""
y=''; while [[ ${y} != 'y' && ${y} != 'n' ]]; do 
read -p "Are you sure to proceed with enabling the enhanced security on all the nodes ? (y/n) : " y
done
echo ""
if [[ ${y} == 'y' ]]; then secure; fi

