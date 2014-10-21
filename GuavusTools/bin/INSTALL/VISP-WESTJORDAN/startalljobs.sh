#!/bin/bash
SSH="ssh -q -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
vip=`/opt/tps/bin/pmx.py subshell hadoop show config | grep  'master' | awk -F":" '{print $NF}'`
for hosts in $vip
do
                echo "-- Checking no oozie job is running  on  $hosts --"
	$SSH root@$hosts "/opt/tps/bin/pmx.py subshell oozie stop jobname all"
	for job in `$SSH root@$hosts "/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs" | grep -v "^No Jobs" | grep -v "Console" | grep -v "^-" | awk {'print $1'}`; do echo -e "\tStopping remnant job $job" ; $SSH root@$hosts  "/opt/tps/bin/pmx.py subshell oozie stop jobid $job" ; done
	$SSH root@$hosts  "/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs"
	$SSH root@$hosts  "/opt/tps/bin/pmx.py subshell oozie show coordinator PREP jobs"
done


for hosts in $vip
do
                echo "-- Now starting OOZIE jobs one by one  $hosts --"
	$SSH root@$hosts "/opt/tps/bin/pmx.py subshell oozie run job all"
	sleep 60
done


for hosts in $vip
do
                echo "Verify that the Jobs is running properly on the Master Collector  $hosts --"
        $SSH root@$hosts "/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs" | awk '{print $2}' | grep -v ID |grep -v "^$"| uniq -c | sort
echo " -------------------------------------------"
	$SSH root@$hosts "/opt/tps/bin/pmx.py subshell oozie show coordinator PREP jobs" | awk '{print $2}' | grep -v ID |grep -v "^$"| uniq -c | sort  

        sleep 60
done
