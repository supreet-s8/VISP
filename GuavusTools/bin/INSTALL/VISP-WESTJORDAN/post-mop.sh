#!/bin/bash


clear
echo "########################################################################"
echo "#				POST MOP CHECKS			             #"
echo "########################################################################"

function check_process()
{
curCmd=0

curCmd=$((curCmd + 1))
if ((curCmd > lastCmd )); then
	echo "*******************************************************"
	echo "    Command [$curCmd] : Java process ";
	echo "*******************************************************"
	ps -ef | grep java | grep -v grep | awk '{print $NF}'
	echo "	${bold}Expected output"
echo " 		 ${bold}org.apache.hadoop.hdfs.server.datanode.DataNode"
echo " 		 ${bold}org.apache.hadoop.hdfs.server.namenode.NameNode"
echo " 		 ${bold}org.apache.hadoop.hdfs.server.namenode.NameNode"
echo "  	      	 ${bold}org.apache.hadoop.hdfs.server.namenode.SecondaryNameNode"
echo " 		 ${bold}org.apache.hadoop.mapred.JobTracker"
echo "  	      	 start";

	read -p "Continue (y): "
	[ "$REPLY" != "y" ] && exit 0
	clear
fi

curCmd=$((curCmd + 1))
if (( curCmd > lastCmd )); then
	echo "*******************************************************"
	echo "    Command [$curCmd] : Checking Hadoop report  ";
	echo "*******************************************************"
		hadoop dfsadmin -report | head -12 
	echo "		${bold}Expected output"
	echo "			   DFS Remaining: xxxxxxx ( x TB)"
	echo "			   DFS Used: yyyyyyy ( y GB)"

	read -p "Continue (y): "
	[ "$REPLY" != "y" ] && exit 0
	clear
fi

curCmd=$((curCmd + 1))
if (( curCmd > lastCmd )); then
        echo "*******************************************************"
        echo "    Command [$curCmd] : Check hadoop filesystem healthy  ";
        echo "*******************************************************"
                hadoop fsck / | tail -25
       
echo " " 
	echo " 	Expected output"
        echo "		Status: HEALTHY"
	echo " 		Total size:      x B"
	echo " 		Total dirs:      x"
	echo " 		Total files:     x (Files currently being written: x)"
	echo " 		Total blocks (validated):        x (avg. block size x B)"
	echo " 		Minimally replicated blocks:     x (100.0 %)"
	echo "	        Over-replicated blocks:  x (x.x %)"
	echo " 		Under-replicated blocks: x (x.x %)"
	echo "		Mis-replicated blocks:            x (x.x %)"
	echo " 		Default replication factor:      x"
	echo " 		Average block replication:       x.x"
	echo " 		Corrupt blocks:          x"
	echo "		Missing replicas:                x (x.x %)"
	echo " 		Number of data-nodes:            x"
	echo " 		Number of racks:         x"
	echo "		FSCK ended at Wed Feb 13 04:59:39 GMT 2013 in 157 milliseconds"
	echo "		The filesystem under path '/' is HEALTHY"
     

        read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0
	clear
fi

curCmd=$((curCmd + 1))
if (( curCmd > lastCmd )); then
        echo "*******************************************************"
        echo "    Command [$curCmd] : Check Collector Process  ";
        echo "*******************************************************"
             
	for i in `/opt/tps/bin/pmx.py subshell hadoop show config | grep -w 'client' | awk -F ":" '{print $NF}'`
	do
		echo " $i"
		ssh  -q root@$i '/opt/tms/bin/cli -t "en" "show pm process collector" | grep -i status'
	done
echo " "


        echo "  ${bold}Expected output"
         echo "     	Current status:  running"


        read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0
	clear
fi

curCmd=$((curCmd + 1))
if (( curCmd > lastCmd )); then
        echo "*******************************************************"
        echo "    Command [$curCmd] :  Verify that each data node has unique storage disk mounted  ";
        echo "*******************************************************"

        for i in `/opt/tps/bin/pmx.py subshell hadoop show config | grep -w 'slave' | awk -F ":" '{print $NF}'`
        do
        echo -n "Working on $i " 
	ssh -q root@$i '/opt/tms/bin/cli -t "en" "conf t" "show tps fs"' | grep -i "uuid"
	done

echo " "
        echo " Example:"
	echo "     Working on 192.168.0.74 UUID: ff419380-4ad3-4a12-b6c0-6acf2e3db329"
	echo "     Working on 192.168.0.77 UUID: 0702507f-07ff-4580-b008-0a9781677ca1"
	echo "     Working on 192.168.0.80 UUID: e5ab4b64-f6a9-44dd-b133-bbcd8941012e"
	echo "     Working on 192.168.0.90 UUID: c5db3f63-1bb8-4f06-bdbf-d1b2a76b19aa"
	echo "     Working on 192.168.0.93 UUID: 50a3-0eee-4a8f-9025-80f105fd67a3"
	echo "     Working on 192.168.0.96 UUID: 5b2bcca4-2c81-40fc-896d-d925ba1ae928"

	echo "*Note: Look for the UUID and that has to be unique for each node. If there is any duplicity, please escalate to GVS as this needs to be fixed before proceeding for upgrade."

        read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0
	clear
	
fi

curCmd=$((curCmd + 1))
if (( curCmd > lastCmd )); then
        echo "*******************************************************"
        echo "    Command [$curCmd] :   Verify that data is present in HDFS  ";
        echo "*******************************************************"

        echo "#          SYSTEM CURRENT DATE & TIME  " `date`                    #"
        hadoop dfs -ls /data/collector/{1,2,3,4}/output/{ipfix,pilotPacket,tcpfix}/`date +%Y`/`date +%m`/`date +%d`/`date +%H` 2>/dev/null

echo " "
        echo " SYSTEM CURRENT DATE & TIME   Wed Feb 13 05:21:08 UTC 2013"
	echo ""
	read -p "Continue (y): "
	[ "$REPLY" != "y" ] && exit 0
        clear
fi

curCmd=$((curCmd + 1))
if (( curCmd > lastCmd )); then
        echo "*******************************************************"
        echo "    Command [$curCmd] : Check oozie jobs -  ";
        echo "*******************************************************"
        /opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs | awk '{print $2}' | grep -v ID |grep -v "^$"| uniq -c  
	/opt/tps/bin/pmx.py subshell oozie show coordinator PREP jobs | awk '{print $2}' | grep -v ID |grep -v "^$"| uniq -c     
	echo " "

        read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0
        clear

fi
}
 check_process

echo "*********** POST MOP CHECKS COMPLETED *************"
