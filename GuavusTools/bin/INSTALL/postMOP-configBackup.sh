#!/bin/bash

clear #clear the screen

a=$(hostname)
b=`echo $a | awk -F "-" '{print $1}'`

CPDIR="support/VISP"
BKPDIR="/data/visp"

`/bin/mkdir -p $BKPDIR/$b`
IP=`/opt/tps/bin/pmx.py subshell hadoop show config  | grep 'client\|slave' | awk '{print $NF}'`

	for i in $IP
	 do
	
		echo "Taking PostMOP config backup from $i"
		ssh -q root@$i '/opt/tms/bin/cli -t "en" "show running full"' > $BKPDIR/$b/$i.cli
		echo "Done on $i"

	done

#Making tar of config backup

	echo "Making tar of configs"
	cmd="/bin/tar -czf /data/${b}_postMOPconfigbackup.tar.gz  ${BKPDIR}/${b}"
	`$cmd`
	echo "Done" 

#scp of the tar 

TARGET=''
read -p "Provide server IP to push configuration backup at : " TARGET
if [[ "$TARGET" == "" ]]; then echo "No target provided. Committing Exit!"; exit; fi

USER=''
read -p "Provide username to to login/scp the file to $TARGET : " USER
if [[ "$USER" == "" ]]; then echo "No target provided. Committing Exit!"; exit; fi

#echo "Transfer tar file to the Guavus debug server"
echo "Provide password when prompted for."
#scp -q /data/"$b"_postMOPconfigbackup.tar.gz debug@50.204.88.45:~/${CPDIR}/
scp -q /data/"$b"_postMOPconfigbackup.tar.gz ${USER}@${TARGET}:~/
echo "Done!"

#echo "Deleting tar and directory which we have created above"
cmd1="/bin/rm -rf /data/${b}_postMOPconfigbackup.tar.gz  ${BKPDIR}/${b}" 
`$cmd1`






