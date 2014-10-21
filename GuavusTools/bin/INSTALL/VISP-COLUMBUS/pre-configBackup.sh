#!/bin/bash

clear #clear the screen

a=$(hostname)
b=`echo $a | awk -F "-" '{print $1}'`


`/bin/mkdir -p /data/pre-config-2.2.rc4/$b`
IP=`/opt/tps/bin/pmx.py subshell hadoop show config  | grep 'client\|slave' | awk '{print $NF}'`

	for i in $IP
	 do
	
		echo "Taking config backup of atals2.2.rc4 from $i"
		ssh -q root@$i '/opt/tms/bin/cli -t "en" "show running full"' > /data/pre-config-2.2.rc4/$b/$i.cli
		echo "Done on $i"

	done

#Making tar of config backup

	echo "Making tar of configs"
	cmd="/bin/tar -czf /data/"$b"_configbackup.tar.gz  /data/pre-config-2.2.rc4/"$b
	`$cmd`
	echo "Done" 

#scp of the tar 

echo "Transfer tar file to the Guavus debug server"
echo "when prompted please provide the password of debug user"
scp -q /data/"$b"_configbackup.tar.gz debug@64.251.14.133:~/PNSARC4ConfigBackup/atlas2.2.rc4/

echo "Done"

#echo "Deleting tar and directory which we have created above"
cmd1="rm -rf /data/"$b"_configbackup.tar.gz  /data/pre-config-2.2.rc4/"$b 
`$cmd1`


