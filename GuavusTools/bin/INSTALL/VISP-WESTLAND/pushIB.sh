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

for i in $col
do
  echo "Pushing IB file..."
  scp -q ./IB/ibs.tgz root@${prefix}$i:/
  if [[ $? -eq '0' ]]; then
     $SSH $prefix{$i} "cd / && /bin/tar -zxvf /ibs.tgz"
  fi
  echo "*********** DONE ***********"
  echo ""
done

