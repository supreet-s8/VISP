#!/bin/bash

#------------------------------------------------------------------------
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
#------------------------------------------------------------------------

for i in $col $col2
do
  echo ""
  echo "Sharing SSH Keys from ${prefix}${i} onto all computes."
  ../../sshkeytool --src=${prefix}${i} --dest=${prefix}14,${prefix}15,${prefix}16,${prefix}17,${prefix}18,${prefix}19,${prefix}20,${prefix}21,${prefix}22,${prefix}23,${prefix}24,${prefix}25,${prefix}10,${prefix}11,${prefix}12,${prefix}13
  echo "*********** DONE ***********"
  echo ""
done

