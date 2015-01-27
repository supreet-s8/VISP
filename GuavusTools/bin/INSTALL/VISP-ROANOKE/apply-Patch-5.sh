#!/bin/bash 
#
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for hosts in `/opt/tps/bin/pmx.py subshell hadoop show config | grep  'client\|slave' | awk -F":" '{print $NF}'`
do
echo "===Transferring Patch5 to host $hosts==="
scp -rq /tmp/VISP/GuavusTools/bin/INSTALL//atlas4.0.1.rc3.p5.tgz root@$hosts:/tmp/
echo "Fetching Patch..."
$SSH root@$hosts '/opt/tps/bin/pmx.py subshell patch fetch /tmp/atlas4.0.1.rc3.p5.tgz'
echo "Installing Patch5..."
$SSH root@$hosts '/opt/tps/bin/pmx.py subshell patch install atlas4.0.1.rc3.p5'
echo "==Done on host $hosts==="
echo ""
done
