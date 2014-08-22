#!/bin/bash
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
col=`/opt/tps/bin/pmx.py subshell hadoop show config | grep  'client' | awk -F":" '{print $NF}'`
for hosts in $col
do
echo "===Working on host $hosts==="
$SSH root@$hosts 'drbd-overview'
#echo "==Done on host $hosts==="
echo ""
done
