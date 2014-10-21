#!/bin/bash
clear
echo " Taking config Backup of each system  and sending it to debug server"

rm -rf config_backup
mkdir config_backup
cd config_backup
for i in 11 13 15 17 19 21 23 25
do
ssh -q root@192.168.10.$i '/opt/tms/bin/cli -t "en" "conf t" "show runn"' > 192.168.10.$i.txt
echo "Config backup of 192.168.10.$i"
done
cd ..
a=`hostname | awk -F"-" '{print $1}'`
b=`date +%d-%m-%y`

tar -czf config-backup-$a-$b.tar.gz config_backup
echo " when prompt provide the password of debug server"
scp config-backup-$a-$b.tar.gz   debug@50.204.88.45:/data/ftp/support/VISP/Backup_logs 


