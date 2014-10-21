#!/bin/bash
# ----------------------------------------------------------------------------------
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
SSH='ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -l root '
# ----------------------------------------------------------------------------------

function startcollector {

echo  "-- Starting Collector Service --"
for i in $col 
do
echo " Working on Node ${prefix}${i}"
$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process collector launch auto'"
$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'wr mem'"
$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process collector restart'"
done

echo "------- CHECKING COLLECTOR SERVICE IN 30 SECONDS -----------"
sleep 30
for i in $col 
do
echo -n " Working on Node ${prefix}${i}. STATUS: "
$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'show pm process collector'" | grep status
done
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

}


startcollector
