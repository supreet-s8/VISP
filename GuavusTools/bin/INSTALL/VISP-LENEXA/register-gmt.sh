#!/bin/bash 
#
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for hosts in `/opt/tps/bin/pmx.py subshell hadoop show config | grep 'slave' | awk -F":" '{print $NF}'`
do
echo "===Register Gmountd on  host $hosts==="
$SSH root@$hosts '/opt/tms/bin/cli -t "en" "conf t" "pmx  register gmountd"'
$SSH root@$hosts '/opt/tms/bin/cli -t "en" "conf t" "wr me"'
echo "==Done on host $hosts==="
echo ""
done
