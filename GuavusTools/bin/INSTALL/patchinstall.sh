#!/bin/bash
#----------------------------------------------------------------------------
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
SSH='ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -l root ';
#----------------------------------------------------------------------------


function applypatch {

clear
echo "------- CHECKING BUILD VERSION -----------"
for i in $cmp $col $col2
do
  echo -n "Version on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID" || echo ""
done

read -p "Continue (y): "
[[ "$REPLY" != "y" ]] && exit 0 
clear

echo "------- INSTALLING PATCH ON ALL NODES -----------"
for i in $cmp $col $col2
do
  /usr/bin/scp -q /tmp/VISP/GuavusTools/bin/INSTALL/atlas4.0.1.rc3.p1.tgz root@${prefix}${i}:/tmp 
    echo "Mounting ${prefix}${i} in read-write mode"
    $SSH ${prefix}${i} "mount -o remount,rw /"
    $SSH ${prefix}${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/atlas4.0.1.rc3.p1.tgz"
    $SSH ${prefix}${i} "/opt/tps/bin/pmx.py subshell patch install atlas4.0.1.rc3.p1"
    $SSH ${prefix}${i} "/opt/tps/bin/pmx.py subshell patch show all patches" | grep atlas4.0.1.rc3.p1
    echo "-------------- Done --------------------------"
done

}

applypatch

echo "------- VERIFYING PATCH LEVEL ON ALL NODES -----------"
echo ""
for i in $col $col2 $cmp
do  
    echo "Checking node ${prefix}${i} for Patch Level."
    $SSH ${prefix}${i} "/opt/tps/bin/pmx.py subshell patch show all patches" | grep atlas4.0.1.rc3.p1
    echo "-------------- Done --------------------------"
    echo ""
done
    

read -p "Continue (y): "
[[ "$REPLY" != "y" ]] && exit 0
clear

