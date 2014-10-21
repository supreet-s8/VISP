#!/bin/bash
# ----------------------------------------------------------------------------------
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
# ----------------------------------------------------------------------------------



function stopnamenodes {

echo "Stopping Jobs on Namenode"
$SSH ${prefix}${col0} "/opt/tps/bin/pmx.py subshell oozie stop jobname all"
echo "Waiting 30 seconds for jobs to terminate"
sleep 30
echo "Terminating any remnant jobs....."
for job in `$SSH ${prefix}${col0} "/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs" | grep -v "^No Jobs" | grep -v "Console" | grep -v "^-" | awk {'print $1'}`; do echo -e "\tStopping remnant job $job" ; $SSH ${prefix}${col0} "/opt/tps/bin/pmx.py subshell oozie stop jobid $job" ; done
clear
echo "Verifying that no jobs exist on the namenode"
$SSH ${prefix}${col0} "/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs"
$SSH ${prefix}${col0} "/opt/tps/bin/pmx.py subshell oozie show coordinator PREP jobs"


}


stopnamenodes
