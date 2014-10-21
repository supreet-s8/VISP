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

function bytes {

for i in $col $cmp $col2
do 
  echo "Executing.... at $prefix$i"
  $SSH $prefix$i "/bin/echo 131072 > /proc/sys/vm/min_free_kbytes"
  $SSH $prefix$i "/bin/echo 268435456 > /proc/sys/vm/dirty_background_bytes"
  echo "Done...!"
done

}

function cmpNoop {

for i in $cmp
do 
  echo "Executing.... at $prefix$i"
  DMLIST=`$SSH $prefix$i "/sbin/multipath -ll" | grep -i iscsi | awk '{ print $3 }' | sort`
 
  for x in ${DMLIST}
    do 
        echo "Executing for $x"
	$SSH $prefix$i "/bin/echo noop > /sys/block/$x/queue/scheduler"
    done
	echo "Verifying NOOP entry"
  for x in ${DMLIST}
    do
	$SSH $prefix$i "/bin/cat /sys/block/$x/queue/scheduler"
    done
  echo "Done...!"
  
done

}

echo "*********** Pushing proc parameters *************"
bytes
echo "*********** Pushing compute specific parameters *************"
cmpNoop
