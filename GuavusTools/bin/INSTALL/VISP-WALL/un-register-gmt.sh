#!/bin/bash 
#
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for hosts in `/opt/tps/bin/pmx.py subshell hadoop show config | grep 'slave' | awk -F":" '{print $NF}'`
do
echo "===Working on  host $hosts==="
$SSH root@$hosts '/opt/tms/bin/cli -t "en" "conf t" "pmx no register gmountd"'
$SSH root@$hosts '/opt/tms/bin/cli -t "en" "conf t" "pm process tps restart"'
$SSH root@$hosts '/opt/tms/bin/cli -t "en" "conf t" "wr me"'

if [[ `$SSH root@$hosts 'ls /var/run/gmountd.pid'` ]]; then 
	    $SSH root@$hosts "cat /var/run/gmountd.pid | xargs kill -15"
	 fi




echo "==Done on host $hosts==="
echo ""
done

