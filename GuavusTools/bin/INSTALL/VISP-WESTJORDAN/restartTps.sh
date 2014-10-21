#!/bin/bash
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
for hosts in `/opt/tps/bin/pmx.py subshell hadoop show config | grep  'client\|slave' | awk -F":" '{print $NF}'`
do
echo "Restarting TPS on Node ${hosts}......"
$SSH root@$hosts "/opt/tms/bin/cli -t 'en' 'conf t' 'wr mem'"
$SSH root@$hosts "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process tps restart'"
echo "Done on Node ${hosts}......"
done
