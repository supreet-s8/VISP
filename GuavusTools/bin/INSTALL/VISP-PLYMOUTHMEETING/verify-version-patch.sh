#!/bin/bash 

SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for hosts in `/opt/tps/bin/pmx.py subshell hadoop show config | grep  'client\|slave' | awk -F":" '{print $NF}'`
do
echo "===Working on host $hosts==="
$SSH root@$hosts '/opt/tms/bin/cli -t "en" "show version" | grep "Build ID"'
$SSH root@$hosts '/opt/tps/bin/pmx.py subshell patch show all patches'
echo ""
done
