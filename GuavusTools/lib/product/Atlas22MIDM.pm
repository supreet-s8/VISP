package Atlas22MIDM;
use lib "./";
# $build=Atlas;
# $version=2.2MIDM;

# Provide in a hash reference of ntp details.
sub ntp {

	my $self=shift;
	my $prop=shift;
	my @cmds=();
	push(@cmds,"no ntp disable",);
	foreach my $server (keys %$prop) {
		push (@cmds, "ntp server $$prop{$server}{ip}");
		if ($$prop{$server}{enable} eq 'yes') {	
			push(@cmds,"no ntp server $$prop{$server}{ip} disable",
				   "ntpdate $$prop{$server}{ip}");
		} else {
		   	push(@cmds,"ntp server $$prop{$server}{ip} disable");
		}
	}

	chomp @cmds;
	return @cmds;

}


# Provide in a hash reference of interfaces and their properties.
sub interface {

	my $self=shift;	
	my $int_hash=shift;
	my @cmds=();
	my @cmd=();
	foreach my $intname(keys %$int_hash) {
		my ($ip, $netmask, $comment, $composed);
		$ip=$$int_hash{$intname}{ip};
		$netmask=$$int_hash{$intname}{subnet};
		#$bonded=$$int_hash{$intname}{bonded}; # Modified
		$comment=undef;
		$comment=$$int_hash{$intname}{comment} if(defined $$int_hash{$intname}{comment});
		$composed=undef;
		$composed=$$int_hash{$intname}{bond} if(defined $$int_hash{$intname}{bond});

		if ($composed=~/\w+/g) {
			$composed=~s/\s//;
			my @count=split /,/,$composed;
			push(@cmd,"bond $intname");
			foreach my $interface (@count) {
			   	my $command="interface $interface bond $intname";
				push (@cmd,"$command",
					   "no interface $interface shutdown",
					   "no interface $interface dhcp");
			}

			push (@cmd,"interface $intname ip address $ip $netmask",
				   "no interface $intname shutdown",
				   "no interface $intname dhcp");
		
		} else {

			push(@cmd,"interface $intname ip address $ip $netmask",
				  "no interface $intname shutdown",
				  "no interface $intname dhcp");
		}
		if (defined $comment) {
			push(@cmd,"interface $intname comment \"$comment\"");

		}

	}
	push (@cmds,@cmd);
	chomp @cmds;
	return @cmds;

}


# Provide in a hash reference of ip-mappings

#sub map {
#	my $self=shift;
#       my $prop=shift;
#       my @cmds=();
#       #my $hosts=$$prop{host};
#       foreach my $host (keys %$prop) {
#               push(@cmds,"ip host $host $$prop{$host}");
#       }
#
#       chomp @cmds;
#       return @cmds;
#}

# Provide in a hash reference of ip gateway and hostnames
sub ip {
	my $self=shift;
	my $prop=shift;
	my @cmds=();
	my $enable=$$prop{'map-hostname'};
	my $hosts=$$prop{host};
	if ($enable eq 'yes') {
		push(@cmds,"ip map-hostname");
	} elsif ($enable eq 'no') {
		push(@cmds,"no ip map-hostname");
	}
	foreach my $host (keys %$hosts) {
		push(@cmds,"ip host $host $$hosts{$host}");
	}

	my $cmd="banner login \"WARNING NOTICE This system is for the use of authorized users only. Individuals using this system without authority, or in excess of their authority, are subject to having all of their activities on this system monitored and recorded by system personnel. In the course of monitoring individuals improperly using this system, or in the course of system maintenance, the activities of authorized users may also be monitored. Anyone using this system expressly consents to such monitoring and is advised that if such monitoring reveals possible evidence of criminal activity, system personnel may provide the evidence of such monitoring to law enforcement officials.\"";

		push(@cmds,"hostname $$prop{hostname}",
			   #"ip name-server $$prop{'name-server'}",
			   "ip default-gateway $$prop{'default-gateway'}",
			   "no web enable",
			   "no web http enable",
			   "$cmd"
		);
	chomp @cmds;
	return @cmds;	
	
}



# Provide in a hash reference of the users and their properties.
sub user {

	my $self=shift;
	my $prop=shift;
	my @cmds=();
	my @cmd=();
	foreach my $user (keys %$prop) {
		my $password="";
		$password=$$prop{$user}{password} if($$prop{$user}{password});
		my $status=$$prop{$user}{status};
		my $capability=undef;
		$capability=$$prop{$user}{capability};
		if ($status eq 'disable') {
			@cmd=("username $user disable");
		} else {
			@cmd=(	"no username $user disable",
				"username $user password $password",
			     );
		}
		if (defined $capability) {
			push(@cmd,"username $user capability $capability");
		}
		push(@cmds,@cmd);
	}
	
	chomp @cmds;
	return @cmds;
} 


# Provide in the collector properties hash reference

sub collector {
	my $self=shift;
        my $prop=shift;
        my @cmds=();
	my $count=0;
	
	my $instance=$$prop{instance};
	#foreach my $instanceID (keys %$instance) {
	#	$count=$count+1;
	#}
	foreach my $instanceID (keys %$instance){
		@cmds=("collector add-instance 1");
		my $adaptor=$$instance{$instanceID};
	foreach my $type (keys %$adaptor) {
		my $UC=uc($type);
		$UC="TCP" if $UC=~/\s*TCPFIX\s*/;
        	push (@cmds,"collector modify-instance 1 add-adaptor $type",
		"collector modify-instance 1 modify-adaptor $type add-port $$adaptor{$type}{port}",
		"collector modify-instance 1 modify-adaptor $type backup-file-system hostname 127.0.0.1",
   		"collector modify-instance 1 modify-adaptor $type backup-file-system port 9000",
		"collector modify-instance 1 modify-adaptor $type backup-file-system user admin",
   		"collector modify-instance 1 modify-adaptor $type bin-size 300",
   		"collector modify-instance 1 modify-adaptor $type drop-alarm-clear-interval 1",
   		"collector modify-instance 1 modify-adaptor $type drop-alarm-raise-interval 1",
   		"collector modify-instance 1 modify-adaptor $type drop-alarm-threshold 10",
   		"collector modify-instance 1 modify-adaptor $type file-format binary",
   		"collector modify-instance 1 modify-adaptor $type file-system hdfs-seq-file",
   		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} adapter-profile none",
   		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} filter-sourceIP disable",
   		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} router-name \"\"",
   		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} socket-IP 0.0.0.0",
   		"collector modify-instance 1 modify-adaptor $type num-bins 2",
   		"collector modify-instance 1 modify-adaptor $type num-objects 100000");
		#if ($count>1) {
		#	my $i=1;
                #	while($i<=$count) {
   		push(@cmds,"collector modify-instance 1 modify-adaptor $type output-directory /data/collector/$instanceID/output/$type/%y/%m/%d/%h/%mi/$$prop{DCName}.$UC.");
		#		$i++;
		#	}

		#} else {
			
		#	push(@cmds,"collector modify-instance $instanceID modify-adaptor $type output-directory /data/collector/output/$type/%y/%m/%d/%h/%mi/$$prop{DCName}.$UC.");
	
		#}
		
   		push(@cmds,"collector modify-instance 1 modify-adaptor $type stack-log-level 0",
   			   "collector modify-instance 1 modify-adaptor $type timeout $$adaptor{$type}{timeout}");
	}

	}	
                push(@cmds,"pm liveness grace-period 600",
			"internal set modify \- /pm/process/collector/term_action value name  /nr/collector/actions/terminate",
   			"pm process collector launch auto",
   			"pm process collector launch enable",
   			"pm process collector launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar",
   			"pm process collector launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib",
   			"pm process collector launch environment set LD_PRELOAD libhoard.so",
   			"pm process collector launch relaunch auto"
                );

                chomp @cmds;
                return @cmds;

}


# Provide in the reference of a hash of cluster properties.
sub cluster {
	my $self=shift;
	my $prop=shift;
	my @cmds=();
	foreach my $id (keys %$prop) {
	@cmds=(
		"cluster id $id",
		"cluster name $$prop{$id}{name}",
		"cluster interface $$prop{$id}{interface}",
		"cluster expected-nodes $$prop{$id}{'expected-nodes'}",
		"cluster master address vip $$prop{$id}{master}{address} $$prop{$id}{master}{subnet}",
		"cluster master interface $$prop{$id}{master}{interface}",
		"cluster enable"
	      );
	}
	
	chomp @cmds;
	return @cmds;
}

# Provide in the reference of a hash of hadoop elements.
sub hadoop {

	my $self=shift;
	my $prop=shift;
	my @cmds=();

	@cmds=(
		"pmx register backup_hdfs",
		"pmx register hadoop",
		"pmx register drbd",
		"pmx register oozie",
		# Configure HDFS Settings
		"pmx set backup_hdfs namenode UNINIT"
	);

	my $clients=$$prop{clients};
	foreach my $client (keys %$clients) {
		# Add the ICN IP Address of each Collector node as a client to the HDFS service
		my $cmd="pmx set hadoop client $$clients{$client}";
		push(@cmds,$cmd);
	}

	my $slaves=$$prop{slaves};
	foreach my $slave (keys %$slaves) {
		# Add the ICN IP Address of each Compute node as a Hadoop Slave
		my $cmd="pmx set hadoop slave $$slaves{$slave}";
		push(@cmds,$cmd);
	}

	# Configure Hadoop Master to utilize the Hadoop Name node Cluster VIP
	push(@cmds,"pmx set hadoop master $$prop{master}{ip}",
		   "pmx set hadoop namenode UNINIT",
		   "pmx set hadoop oozieServer $$prop{master}{ip}"
		   );
	chomp @cmds;
	return @cmds;

}

sub drbd {
	my $self=shift;
	my $prop=shift;
	my @cmds=();

	# Configure DRDB
	#@cmds=("pmx");
	# Hostname and ICN IP address of first name node
	foreach my $host (keys %$prop) {
		if ($host eq 'self') {
			push(@cmds,"pmx set drbd selfip $$prop{self}{ip}");
		} else {
			push(@cmds, "pmx set drbd $host $$prop{$host}{hostname}",
				  , "pmx set drbd $host"."ip $$prop{$host}{ip}");
		}
	}


	# DRBD wait time
	push (@cmds,"pmx set drbd waittime 300");
	#push (@cmds,"quit");

	chomp @cmds;
	return @cmds;
}


# Provide in the reference of hash for SM section.
sub sm {
	my $slef=shift;
	my $prop=shift;
	my @cmds=();

	# Configure Storage on both Name Nodes
	@cmds=(	"sm service create PS::BLOCKING:1",
		"sm service modify PS::BLOCKING:1 service-info ps-server-1",
		"sm service-info create ps-server-1",
		"sm service-info modify ps-server-1 host $$prop{instaNode}{ip}",
		"sm service-info modify ps-server-1 port 11111",
		"sm service-info modify ps-server-1 service-type TCP_SOCKET"
		);
	
	chomp @cmds;
	return @cmds;

}

# Provide in the SNMP server properties hash reference
sub snmp {

	my $self=shift;
	my $prop=shift;
	my @cmds=();

	@cmds=(
		"snmp-server community $$prop{server}{community} ro",
		"snmp-server enable",
		"snmp-server enable communities",
		"snmp-server enable traps",
		"snmp-server host $$prop{server}{ip} traps version 2c $$prop{server}{community}",
		"snmp-server listen enable",
		"snmp-server location $$prop{server}{location}",
		"snmp-server traps community $$prop{server}{community}",
		"snmp-server traps event HDFS-namenode-status",
		"snmp-server traps event collector-data-resume",
		"snmp-server traps event collector-dropped-flow-alarm-cleared",
		"snmp-server traps event collector-dropped-flow-thres-crossed",
		"snmp-server traps event cpu-util-high",
		"snmp-server traps event cpu-util-ok",
		"snmp-server traps event disk-io-high",
		"snmp-server traps event disk-space-low",
		"snmp-server traps event disk-space-ok",
		"snmp-server traps event insta-adaptor-down",
		"snmp-server traps event interface-down",
		"snmp-server traps event interface-up",
		"snmp-server traps event liveness-failure",
		"snmp-server traps event memusage-high",
		"snmp-server traps event memusage-ok",
		"snmp-server traps event netusage-ok",
		"snmp-server traps event netusage-high",
		"snmp-server traps event no-collector-data",
		"snmp-server traps event paging-high",
		"snmp-server traps event paging-ok",
		"snmp-server traps event process-crash",
		"snmp-server traps event process-relaunched",
		"snmp-server traps event test-trap",
		#"snmp-server traps event unexpected-cluster-join",
		#"snmp-server traps event unexpected-cluster-leave",
		#"snmp-server traps event unexpected-cluster-size",
		"snmp-server traps event unexpected-shutdown",
		"stats alarm disk_io enable",
		"stats alarm intf_util enable",
		"stats alarm memory_pct_used enable",	
		"snmp-server traps event data-process-time-exceeded",
		"snmp-server traps event data-process-time-exceeded-alarm-cleared",
		"snmp-server traps event data-receive-fail-alarm-cleared",
		"snmp-server traps event data-receive-failed",
		"snmp-server traps event data-transfer-fail-alarm-cleared",
		"snmp-server traps event data-transfer-failed",
		"snmp-server traps event input-data-missing-task-failed",
		"snmp-server traps event input-data-missing-task-ok",	
		"stats alarm disk_io rising error-threshold 81920",
		"stats alarm disk_io rising clear-threshold 51200",
		"stats alarm intf_util rising error-threshold 1572864000",
		"stats alarm intf_util rising clear-threshold 1258291200",
		"internal set modify - /stats/config/alarm/cpu_util_indiv/trigger/node_pattern value name /system/cpu/all/busy_pct",
		"internal set modify - /stats/config/sample/disk_io/interval value duration_sec 3600",
		"pm process statsd restart"
	);
	
	chomp @cmds;
	return @cmds;
}



# Provide reference of a hash for Oozie section properties
sub oozie {
        my $self=shift;
        my $prop=shift;
        my @cmds=();
        push (@cmds,	"pmx set oozie namenode $$prop{namenode}{hostname}",
			"pmx set oozie oozieServer $$prop{namenode}{vip}",
			"pmx set oozie sshHost 127.0.0.1",
			"pmx set oozie snapshotPath /data/snapshots");
	my $jobs=$$prop{job};
	my $commonPath=$$prop{dataset}{common}{attribute}{path};
	foreach my $job(keys %$jobs) {
		push (@cmds, "pmx subshell oozie add job $job $$jobs{$job}{name} $$jobs{$job}{path}");
		my $attributes=$$jobs{$job}{attribute};
			foreach my $attribute (keys %$attributes) {
				push (@cmds, "pmx subshell oozie set job $job attribute $attribute $$attributes{$attribute}");
				
			}
		my $actions=$$jobs{$job}{action};
			foreach my $action (keys %$actions) {
				next if($action=~/ExporterAction/ && $job=~/CubeExporter/);
				push (@cmds, "pmx subshell oozie set job $job action $action attribute timeout $$actions{$action}{attribute}{timeout}");
			}
		push (@cmds, "pmx subshell oozie set job $job attribute jobEnd 2099-12-31T00:00Z");
	}
	
	push (@cmds,	
			"pmx subshell oozie add dataset midm_subib",
			"pmx subshell oozie set dataset midm_subib attribute startOffset 47",
			"pmx subshell oozie set dataset midm_subib attribute frequency 60",
			"pmx subshell oozie set dataset midm_subib attribute endOffset 24",
			"pmx subshell oozie set dataset midm_subib attribute doneFile distcp_DONE",
			"pmx subshell oozie set dataset midm_subib attribute outputOffset 0",


			"pmx subshell oozie set dataset midm_subib attribute path /data/$commonPath/SubscriberIB/%Y/%M/%D/%H",

			#"pmx subshell oozie set dataset midm_subib attribute startTime 2012-03-01T00:00Z",
			"pmx subshell oozie set dataset midm_subib attribute pathType hdfs",

			"pmx subshell oozie add dataset midm_wngibcp",
			"pmx subshell oozie set dataset midm_wngibcp attribute startOffset 0",
			"pmx subshell oozie set dataset midm_wngibcp attribute frequency 60",
			"pmx subshell oozie set dataset midm_wngibcp attribute endOffset 0",
			"pmx subshell oozie set dataset midm_wngibcp attribute doneFile _DONE",
			"pmx subshell oozie set dataset midm_wngibcp attribute outputOffset 0",
			"pmx subshell oozie set dataset midm_wngibcp attribute path /MIDM_IB/WNGIB/wngIB.map",

			#"pmx subshell oozie set dataset midm_wngibcp attribute startTime 2012-03-01T00:00Z",
			"pmx subshell oozie set dataset midm_wngibcp attribute pathType hdfs",

			"pmx subshell oozie add dataset midm_ipfix",
			"pmx subshell oozie set dataset midm_ipfix attribute startOffset 576",
			"pmx subshell oozie set dataset midm_ipfix attribute frequency 5",
			"pmx subshell oozie set dataset midm_ipfix attribute endOffset 289",
			"pmx subshell oozie set dataset midm_ipfix attribute doneFile _DONE",
			"pmx subshell oozie set dataset midm_ipfix attribute outputOffset 0",

			"pmx subshell oozie set dataset midm_ipfix attribute path /data/$commonPath/ipfix/%Y/%M/%D/%H/%mi",

			#"pmx subshell oozie set dataset midm_ipfix attribute startTime 2012-03-01T00:00Z",
			"pmx subshell oozie set dataset midm_ipfix attribute pathType hdfs",

			"pmx subshell oozie add dataset midm_out",
			"pmx subshell oozie set dataset midm_out attribute startOffset 0",
			"pmx subshell oozie set dataset midm_out attribute frequency 1",
			"pmx subshell oozie set dataset midm_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset midm_out attribute endOffset 0",
			"pmx subshell oozie set dataset midm_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset midm_out attribute outputOffset 0",

			"pmx subshell oozie set dataset midm_out attribute path /data/output/$commonPath/Midm/%Y/%M/%D",
			#"pmx subshell oozie set dataset midm_out attribute startTime 2012-03-01T00:00Z",
			"pmx subshell oozie set dataset midm_out attribute pathType hdfs",

			"pmx subshell oozie set job MidmEnr attribute jobType MidmCubeJob",
			"pmx subshell oozie set job MidmEnr attribute jobLocation /opt/etc/oozie/MidmCubes",

			"pmx subshell oozie set job MidmEnr action WngIBcpAction attribute ibName /MIDM_IB/WNGIB/wngIB.map",
			"pmx subshell oozie set job MidmEnr action WngIBcpAction attribute srcDataset midm_wngibcp",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute outputDataset midm_out",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute jarFile /opt/tms/java/CubeCreator-atlas2.1.jar",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute mainClass com.guavus.mapred.midm.job.enr.MidmCubeCreator",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute configFile /opt/etc/oozie/MidmCubes/MidmCubes.json",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute inputDatasets midm_ipfix",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute subIBDatasets midm_subib",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute inclusionListDataset midm_out_inc_list",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute prevJobName MidmInclusionListWait",
			#"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute timeout 0",
			"pmx subshell oozie add dataset midm_enr_local",
			"pmx subshell oozie set dataset midm_enr_local attribute startOffset 0",
			"pmx subshell oozie set dataset midm_enr_local attribute endOffset 0",
			"pmx subshell oozie set dataset midm_enr_local attribute doneFile _DONE",
			"pmx subshell oozie set dataset midm_enr_local attribute outputOffset 0",
			"pmx subshell oozie set dataset midm_enr_local attribute path /data/local/$commonPath/MidmEnr/%Y/%M/%D",
			"pmx subshell oozie set dataset midm_enr_local attribute pathType local",
			"pmx subshell oozie set dataset midm_enr_local attribute frequency 1",
			"pmx subshell oozie set dataset midm_enr_local attribute frequencyUnit day",
			#"pmx subshell oozie set dataset midm_enr_local attribute startTime 2012-03-01T00:00Z",

			"pmx subshell oozie add dataset midm_enr_final",
			"pmx subshell oozie set dataset midm_enr_final attribute startOffset 0",
			"pmx subshell oozie set dataset midm_enr_final attribute endOffset 0",
			"pmx subshell oozie set dataset midm_enr_final attribute doneFile _DONE",
			"pmx subshell oozie set dataset midm_enr_final attribute outputOffset 0",
			"pmx subshell oozie set dataset midm_enr_final attribute path /data/output/MidmEnr/%Y/%M/%D",
			"pmx subshell oozie set dataset midm_enr_final attribute pathType hdfs",
			"pmx subshell oozie set dataset midm_enr_final attribute frequency 1",
			"pmx subshell oozie set dataset midm_enr_final attribute frequencyUnit day",
			#"pmx subshell oozie set dataset midm_enr_final attribute startTime 2012-03-01T00:00Z",

			"pmx subshell oozie add dataset midm_agg_final",
			"pmx subshell oozie set dataset midm_agg_final attribute startOffset 0",
			"pmx subshell oozie set dataset midm_agg_final attribute endOffset 0",
			"pmx subshell oozie set dataset midm_agg_final attribute doneFile _DONE",
			"pmx subshell oozie set dataset midm_agg_final attribute outputOffset 0",
			"pmx subshell oozie set dataset midm_agg_final attribute path /data/output/$commonPath/MidmAgg/%Y/%M/%D",
			"pmx subshell oozie set dataset midm_agg_final attribute pathType hdfs",
			"pmx subshell oozie set dataset midm_agg_final attribute frequency 1",
			"pmx subshell oozie set dataset midm_agg_final attribute frequencyUnit day",
			#"pmx subshell oozie set dataset midm_agg_final attribute startTime 2012-03-01T00:00Z",

			"pmx subshell oozie add dataset midm_agg_local",
			"pmx subshell oozie set dataset midm_agg_local attribute startOffset 0",
			"pmx subshell oozie set dataset midm_agg_local attribute endOffset 0",
			"pmx subshell oozie set dataset midm_agg_local attribute doneFile _DONE",
			"pmx subshell oozie set dataset midm_agg_local attribute outputOffset 0",
			"pmx subshell oozie set dataset midm_agg_local attribute path /data/local/$commonPath/MidmAgg/%Y/%M/%D",
			"pmx subshell oozie set dataset midm_agg_local attribute pathType local",
			"pmx subshell oozie set dataset midm_agg_local attribute frequency 1",
			"pmx subshell oozie set dataset midm_agg_local attribute frequencyUnit day",
			#"pmx subshell oozie set dataset midm_agg_local attribute startTime 2012-03-01T00:00Z",

			"pmx subshell oozie set job MidmData attribute jobType MidmDataTransferJob",
			"pmx subshell oozie set job MidmData attribute jobLocation /opt/etc/oozie/MidmDataTransfer",
			"pmx subshell oozie set job MidmData action AggCopyAndZipAction attribute destDataset midm_agg_final",
			#"pmx subshell oozie set job MidmData action AggCopyAndZipAction attribute timeout -1",
			"pmx subshell oozie set job MidmData action AggCopyAndZipAction attribute srcDataset midm_out",
			"pmx subshell oozie set job MidmData action AggCopyAndZipAction attribute localDataset midm_agg_local",
			"pmx subshell oozie set job MidmData action AggCopyAndZipAction attribute configFile /opt/etc/oozie/MidmCubes/MidmCubes.json",
			"pmx subshell oozie set job MidmData action EnrCopyAndZipAction attribute destDataset midm_enr_final",
			#"pmx subshell oozie set job MidmData action EnrCopyAndZipAction attribute timeout -1",
			"pmx subshell oozie set job MidmData action EnrCopyAndZipAction attribute srcDataset midm_out",
			"pmx subshell oozie set job MidmData action EnrCopyAndZipAction attribute localDataset midm_enr_local",

			"pmx subshell oozie set job CleanupMidmCubes attribute frequencyUnit day",
			"pmx subshell oozie set job CleanupMidmCubes action CleanupAction attribute cleanupOffset 3",
			"pmx subshell oozie set job CleanupMidmCubes action CleanupAction attribute cleanupDatasets midm_out",
			"pmx subshell oozie set job CleanupRaw attribute frequencyUnit day",
			"pmx subshell oozie set job CleanupRaw action CleanupDatasetAction attribute cleanupOffset 30",
			"pmx subshell oozie set job CleanupRaw action CleanupDatasetAction attribute cleanupDatasets midm_ipfix",
			"pmx subshell oozie set job CleanupRaw action CleanupDatasetAction attribute cleanupDatasets midm_subib",
			"pmx subshell oozie set job MidmInclusionListWait action WaitForInclusionList attribute outputDataset midm_out_inc_list",
			"pmx subshell oozie set job MidmInclusionListWait action WaitForInclusionList attribute inputDataset midm_inc_listadd dataset midm_out_inc_list",
			"pmx subshell oozie set dataset midm_out_inc_list attribute startOffset 0",
			"pmx subshell oozie set dataset midm_out_inc_list attribute frequency 1",
			"pmx subshell oozie set dataset midm_out_inc_list attribute endOffset 0",
			"pmx subshell oozie set dataset midm_out_inc_list attribute frequencyUnit day",
			"pmx subshell oozie set dataset midm_out_inc_list attribute path /data/output/MidmInclusionList/%Y/%M/%D",
			#"pmx subshell oozie set dataset midm_out_inc_list attribute startTime 2012-06-20T08:00Z",
			"pmx subshell oozie set dataset midm_out_inc_list attribute pathType hdfsadd dataset midm_inc_list",
			"pmx subshell oozie set dataset midm_inc_list attribute startOffset 0",
			"pmx subshell oozie set dataset midm_inc_list attribute frequency 1",
			"pmx subshell oozie set dataset midm_inc_list attribute endOffset 0",
			"pmx subshell oozie set dataset midm_inc_list attribute frequencyUnit day",
			"pmx subshell oozie set dataset midm_inc_list attribute path /data/input/MidmInclusionList/%Y/%M/%D",
			#"pmx subshell oozie set dataset midm_inc_list attribute startTime 2012-06-20T08:00Z",
			"pmx subshell oozie set dataset midm_inc_list attribute pathType hdfs",
			"pmx subshell oozie set job MidmProcessTime action CalProcessTime attribute lastMidmJobName MidmEnr",
			"pmx subshell oozie set job MidmProcessTime action CalProcessTime attribute maxTime 14",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute subIBDatasets midm_subib",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute inclusionListDataset midm_out_inc_list",
			"pmx subshell oozie set job MidmEnr action MidmMapRedAction attribute prevJobName MidmInclusionListWait"
				);

	chomp @cmds;
        return @cmds;
}

sub ssh {

        my $self=shift;
        my $prop=shift;
        my @cmds=("ssh client global host-key-check no");
        $usernames=$$prop{key};
        foreach my $user (keys %$usernames) {
                push(@cmds,
                                "ssh client user $user identity $$prop{key}{$user} generate"
                        );
        }

        chomp @cmds;
        return @cmds;

}

1;

