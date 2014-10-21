#!/bin/bash
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
for hosts in `/opt/tps/bin/pmx.py subshell hadoop show config | grep  'client\|slave' | awk -F":" '{print $NF}'`
do
echo -n " Working on Node $hosts STATUS: "
$SSH root@$hosts "/opt/tms/bin/cli -t 'en' 'conf t' 'show pm process tps'" | grep status
done
