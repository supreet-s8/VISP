#!/bin/bash 
#
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for hosts in `/opt/tps/bin/pmx.py subshell hadoop show config | grep 'slave' | awk -F":" '{print $NF}'`
do
echo "==Checking Gmounted Process on $hosts==="
echo  "ProcessID - "
 $SSH root@$hosts "ps -ef | grep gmountd | grep -v grep"  | awk '{print $2}'
done


