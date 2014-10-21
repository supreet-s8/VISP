#!/bin/bash
#-------------------------------------------------------------------------
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
#-------------------------------------------------------------------------
clear

HEALTH="/data/healthcheck"

DCNAME=`cli -t "en" "show running-config full" | grep destIpfixRecords | grep path | grep "value value string" | head -1 | awk '{print $NF}' | awk -F/ '{print $3}'`

`perl -pi -e "s/10.136.239.147/$sapcnp0/" $PWD/192.168.10.10.json`

`perl -pi -e "s/10.136.239.147/$sapcnp0/" $PWD/192.168.10.11.json`

`perl -pi -e "s/\/data\/healthcheck\/inbox\/192.168.10.10/\/data\/healthcheck\/inbox\/$DCNAME\-192.168.10.10/" $PWD/192.168.10.10.json`

`perl -pi -e "s/\/data\/healthcheck\/inbox\/192.168.10.11/\/data\/healthcheck\/inbox\/$DCNAME\-192.168.10.11/" $PWD/192.168.10.11.json`

REMOTE="/data/healthcheck/inbox/$DCNAME"

### Health Check ###

for i in $col

do 

echo "Registering Health Check Client Service on Namenode $prefix$i"
$SSH $prefix$i "/opt/tps/bin/pmx.py register healthcheck_client"

echo "Creating local health check directory."
$SSH $prefix$i "/bin/mkdir -p $HEALTH"

echo "Copying cooked properties file."
scp -q $PWD/$prefix$i.json root@$prefix$i:$HEALTH/healthcheck_client_config.json

echo "Creating remote logs directory at SAP NEC."
$SSH $sapcnp1 "/bin/mkdir -p $REMOTE-$prefix$i"
  if [[ $? -ne 0 ]]
  then
    printf "Error: Unable to create remote logs directory $REMOTE/$prefix$i on $sapcnp1\n"
  fi

$SSH $sapcnp2 "/bin/mkdir -p $REMOTE-$prefix$i"
  if [[ $? -ne 0 ]]
  then
    printf "Error: Unable to create remote logs directory $REMOTE/$prefix$i on $sapcnp2\n"
  fi

echo "============================================================="
done

###

