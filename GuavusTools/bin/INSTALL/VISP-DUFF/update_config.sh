#!/bin/bash
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
for hosts in `/opt/tps/bin/pmx.py subshell hadoop show config | grep  client | awk -F":" '{print $NF}'`
do
#echo "Restarting TPS on Node ${hosts}......"
#$SSH root@$hosts "/opt/tms/bin/cli -t 'en' 'conf t' 'wr mem'"
#$SSH root@$hosts "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process tps restart'"
#echo "Done on Node ${hosts}......"
$SSH root@$hosts "perl -pi -e 's/<configuration>/<configuration>\n\t<property>\n\t\t\<name>fs.hdfs.impl.disable.cache<\/name>\n\t\t<value>true<\/value>\n\t\t<description>Dont cache hdfs filesystem instances.<\/description>\n\t<\/property>/' /opt/samples/hadoop_conf/core-site.xml.template"
echo "Done on $hosts"
done
