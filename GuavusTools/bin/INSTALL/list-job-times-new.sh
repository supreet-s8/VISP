#!/bin/bash
COL1VIP=`/opt/tps/bin/pmx.py subshell hadoop show config | grep  'master' | awk -F":" '{print $NF}'| sed -e 's/\s//g'`
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for i in `$SSH root@$COL1VIP "/opt/tps/bin/pmx.py subshell oozie show config all | grep jobStart" | awk -F'/jobStart' '{print $1}' | sed -e 's/^\s*//g'`
do 
printf "$i\t\t: "
$SSH root@$COL1VIP "/opt/hadoop/bin/hadoop dfs -cat /data/$i/done.txt 2>/dev/null"
if [[ $? -ne '0' ]]; then echo "JOB, YET TO RUN!"; fi
done
