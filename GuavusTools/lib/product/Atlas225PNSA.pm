package Atlas225PNSA;
use lib "./";
# $build=Atlas;
# $version=2.2PNSA;

# Provide in a hash reference of ntp details.
sub ntp {

	my $self=shift;
	my $prop=shift;
	my @cmds=();
	push(@cmds,"no ntp disable","ssh client global host-key-check no");
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
			   #"ip default-gateway $$prop{'default-gateway'}",
			   "no web enable",
			   "no web http enable",
			   "no web https enable",
			   "no telnet-server enable",
			   "no virt enable",			   
			   "$cmd"
		);
		
		
	push (@cmds,

		"ip filter chain FORWARD clear",
		"ip filter chain INPUT clear",
		"ip filter chain OUTPUT clear",
		"ip filter chain INPUT policy ACCEPT",
		"ip filter chain INPUT rule append tail target ACCEPT dup-delete in-intf lo",

	);
	
	my $filter=$$prop{filter}{input}{accept};
		foreach my $source (keys %$filter) {
		push (@cmds, 	"ip filter chain INPUT rule append tail target ACCEPT protocol udp dest-port 5353 source-addr $$filter{$source} /32",
				"ip filter chain INPUT rule append tail target ACCEPT dup-delete source-addr $$filter{$source} /32 dest-port 8080 protocol tcp"
				);
		
	}		

	my $port=$$prop{filter}{port}{accept};
		foreach my $sourceP (keys %$port) {
                push (@cmds, 	"ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50060 source-addr $$port{$sourceP} /32",
				"ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50071 source-addr $$port{$sourceP} /32",
				"ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50076 source-addr $$port{$sourceP} /32"
			);
        }


	push (@cmds,	
		"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 13 icmp-code 0",
		"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 14 icmp-code 0",
		"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 17 icmp-code 0",
		"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 18 icmp-code 0",

		"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 13 icmp-code 0",
		"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 14 icmp-code 0",
		"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 17 icmp-code 0",
		"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 18 icmp-code 0",	      

		"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 13",
		"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 14",
		"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 17",
		"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 18",

		"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 13",
		"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 14",
		"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 17",
		"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 18",

# Disabled for now --
		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50030",
		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50060",
		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50070",
		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50071",
		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50076",
		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50075",
		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50090",
		"ip filter chain INPUT rule append tail target DROP protocol udp dest-port 5353",
		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 8080",
		"ip filter enable", 
	      
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
	push (@cmds, "aaa authentication attempts lockout max-fail 3");	
	chomp @cmds;
	return @cmds;
} 


# Provide in the collector properties hash reference

sub collector {
	my $self=shift;
        my $prop=shift;
        my @cmds=();
	#my $count=0;

        my $dcname=$$prop{DCName};	
	my $instance=$$prop{instance};
	#foreach my $instanceID (keys %$instance) {
	#	$count=$count+1;
	#}
	@cmds=("collector add-instance 1");
	foreach my $instanceID (keys %$instance){
		my $adaptor=$$instance{$instanceID};
	foreach my $type (keys %$adaptor) {
		my $UC=uc($type);

		# ----------------------------------------------
		# TCPFIX - (fixed)
		#$UC="TCP" if $UC=~/\s*TCPFIX\s*/;
		# PILOT Packet - Still takes the name as RADIUS
		$UC="RADIUS" if $UC=~/\s*PILOTPACKET\s*/;
		# ----------------------------------------------

        	push (@cmds,"collector modify-instance 1 add-adaptor $type",
			#"collector modify-instance 1 modify-adaptor $type attribute-binning disable",
			"collector modify-instance 1 modify-adaptor $type add-file-if f1",
			"collector modify-instance 1 modify-adaptor $type auto-bin-slide enable",
			"collector modify-instance 1 modify-adaptor $type backup-file-system hostname 127.0.0.1",
			"collector modify-instance 1 modify-adaptor $type backup-file-system port 9000",
			"collector modify-instance 1 modify-adaptor $type backup-file-system user admin",
			"collector modify-instance 1 modify-adaptor $type bin-size 300",
			"collector modify-instance 1 modify-adaptor $type drop-alarm-clear-interval 1",
			"collector modify-instance 1 modify-adaptor $type drop-alarm-raise-interval 1",
			"collector modify-instance 1 modify-adaptor $type drop-alarm-threshold 10",
			"collector modify-instance 1 modify-adaptor $type file-format binaryCompression",
			"collector modify-instance 1 modify-adaptor $type file-system hdfs-seq-file",
			"collector modify-instance 1 modify-adaptor $type modify-file-if f1 adapter-profile \"\"",
			"collector modify-instance 1 modify-adaptor $type modify-file-if f1 compression gzip",
			"collector modify-instance 1 modify-adaptor $type modify-file-if f1 file-format $$adaptor{$type}{fileFormat}",
			"collector modify-instance 1 modify-adaptor $type modify-file-if f1 input-directory $$adaptor{$type}{inputPath}",
			"collector modify-instance 1 modify-adaptor $type modify-file-if f1 sync-wait-period 0",
			"collector modify-instance 1 modify-adaptor $type modify-file-if f1 timezone \"\"",
			"collector modify-instance 1 modify-adaptor $type no-data-alarm-repeat 900",
			"collector modify-instance 1 modify-adaptor $type num-bins 2",
			"collector modify-instance 1 modify-adaptor $type num-objects 5000000",
			"collector modify-instance 1 modify-adaptor $type output-directory /data/output/pnsa/$type/%y/%m/%d/%h/%mi/$dcname.$UC.",
			"collector modify-instance 1 modify-adaptor $type prorate disable",
			"collector modify-instance 1 modify-adaptor $type timeout 600",
			"collector modify-instance 1 modify-adaptor $type peak-flow-alarm-clear-interval 1",
			"collector modify-instance 1 modify-adaptor $type peak-flow-alarm-raise-interval 1",
			"collector modify-instance 1 modify-adaptor $type peak-flow-alarm-threshold 60000",
			"collector modify-instance 1 modify-adaptor $type stack-log-level 0"
			);

	}

	}	
                push(@cmds,"collector modify-instance 1 modify-adaptor pilotPacket modify-file-if f1 filename-format *_*_*_*_%YYYY%MM%DD%hh%mm%ss_B40_*.bin.gz",
			"collector modify-instance 1 modify-adaptor pilotPacket modify-file-if f1 transfer-filename-fmt *_*_*_*_%YYYY%MM%DD%hh%mm%ss_B40_*.bin.gz.tmp",
			"collector modify-instance 1 modify-adaptor ipfix modify-file-if f1 filename-format *_*_*_*_%YYYY%MM%DD%hh%mm%ss_HDR_*.csv.gz",
			"collector modify-instance 1 modify-adaptor ipfix modify-file-if f1 transfer-filename-fmt *_*_*_*_%YYYY%MM%DD%hh%mm%ss_HDR_*.csv.gz.tmp",
			"collector modify-instance 1 modify-adaptor ipfix attribute-binning enable",
			"collector modify-instance 1 modify-adaptor pilotPacket attribute-binning disable",
			"pm liveness grace-period 600",
			"internal set modify \- /pm/process/collector/term_action value name  /nr/collector/actions/terminate",
   			"pm process collector launch auto",
   			"pm process collector launch enable",
			"pm process collector liveness hung-count 4",
   			"pm process collector launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar:/opt/tms/java/MemSerializer.jar",
   			"pm process collector launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib",
   			#"pm process collector launch environment set LD_PRELOAD \"\"",
			#"no pm process collector launch environment set LD_PRELOAD",
   			"pm process collector launch relaunch auto",
			"pm process collector terminate",
			
			"internal set modify - /nr/collector/instance/1/adaptor/ipfix/max_bin_file_size value uint32 1",
			"internal set modify - /pm/process/collector/term_action value name  /nr/collector/actions/terminate",
			"internal set modify - /stats/config/chd/interval_average_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_average_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_average_flow_hour/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_dropped_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_dropped_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_dropped_flow_hour/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_max_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_max_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_max_flow_hour/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_prorated_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_prorated_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_prorated_flow_hour/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_total_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_total_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_total_flow_hour/calc_partial value bool false",

                );

# ----- Temporary placeholder to disable insta process in PNSA builds ------
# ---------- DONE ---------


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
		"pm process collector liveness hung-count 4",
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
		"internal set create - /tps/process/hadoop/attribute/mapred.child.java.opts/value value string \"\-Xmx4096m \-verbose\:gc \-XX\:\+PrintGCDetails \-XX\:\+PrintGCDateStamps\"",
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
#		"snmp-server host $$prop{server}{ip} traps version 2c $$prop{server}{community}",
		"snmp-server listen enable",
		"snmp-server location $$prop{server}{location}",
		"snmp-server traps community $$prop{server}{community}",
		"no snmp-server community public",
		"snmp-server traps event no-collector-data",
		"snmp-server traps event collector-data-resume",
		"snmp-server traps event collector-dropped-flow-alarm-cleared",
		"snmp-server traps event collector-dropped-flow-thres-crossed",
		"snmp-server traps event data-transfer-fail-alarm-cleared",
		"snmp-server traps event data-transfer-failed",
		"snmp-server traps event data-transfer-stall",
		"snmp-server traps event data-transfer-stall-alarm-cleared",
		"snmp-server traps event invalid-record-thresh-trap",
		"snmp-server traps event invalid-record-thresh-cleared",
		"snmp-server traps event cpu-util-high",
		"snmp-server traps event cpu-util-ok",
		"snmp-server traps event disk-io-high",
		"snmp-server traps event disk-io-ok",
		"snmp-server traps event disk-space-low",
		"snmp-server traps event disk-space-ok",
		"snmp-server traps event interface-down",
		"snmp-server traps event interface-up",
		"snmp-server traps event memusage-high",
		"snmp-server traps event memusage-ok",
		"snmp-server traps event netusage-high",
		"snmp-server traps event netusage-ok",
		"snmp-server traps event paging-high",
		"snmp-server traps event paging-ok",
		"snmp-server traps event process-crash",
		"snmp-server traps event process-relaunched",
		"snmp-server traps event long-time-taken-to-transfer-data",
		"snmp-server traps event long-time-taken-to-transfer-data-alarm-cleared",
		"snmp-server traps event test-trap",
		"snmp-server traps event unexpected-shutdown",
		"no snmp-server traps event process-exit",
		"no snmp-server traps event smart-warning",
		"stats alarm disk_io enable",
		"stats alarm intf_util enable",
		"stats alarm memory_pct_used enable",
		"stats alarm disk_io rising error-threshold 81920",
		"stats alarm disk_io rising clear-threshold 51200",
		"stats alarm intf_util rising error-threshold 1572864000",
		"stats alarm intf_util rising clear-threshold 1258291200",
		"stats alarm paging rising error-threshold 16000",
		"internal set modify - /stats/config/alarm/paging/trigger/type value string chd",
		"internal set modify - /stats/config/chd/paging/time/interval_length value duration_sec 300",
		"internal set modify - /stats/config/alarm/cpu_util_indiv/trigger/node_pattern value name /system/cpu/all/busy_pct",
		"internal set modify - /stats/config/sample/disk_io/interval value duration_sec 3600",
		"internal set create - \"/stats/config/alarm/fs_mnt/trigger/node_patterns/\\\\/system\\/fs\\\\/mount\\/\\\\\\\\\\\\/data\\\\/bytes-percent-free\" value name \"/system/fs/mount/\\/data/bytes-percent-free\"",
		"internal set create - \"/stats/config/alarm/fs_mnt/trigger/node_patterns/\\\\/system\\/fs\\\\/mount\\/\\\\\\\\\\\\/data\\\\\\\\\\\\/hadoop-admin\\\\/bytes-percent-free\" value name \"/system/fs/mount/\\/data\\/hadoop-admin/bytes-percent-free\"",

	);

	my $snmpsrv=$$prop{server};
	foreach my $entry(keys %$snmpsrv) {
		# Sucks!! 
		next if ($entry !~ m/\d+/);
		push (@cmds, "no snmp-server host $$snmpsrv{$entry}{ip} disable");
		push (@cmds, "snmp-server host $$snmpsrv{$entry}{ip} traps version 2c $$prop{server}{community}");
	}
	
	push (@cmds ,"pm process statsd restart");
#TEMP
	push (@cmds, "pm process insta terminate");
	push (@cmds, 	"no pm process insta launch enable",
			"no pm process insta launch relaunch auto",);
	push (@cmds, "no snmp-server traps event insta-adaptor-down");
	push (@cmds, "no cmc server enable");
	push (@cmds, "no cmc client enable");

#####	
	chomp @cmds;
	return @cmds;
}



# Provide reference of a hash for Oozie section properties
sub oozie {
        my $self=shift;
        my $prop=shift;
        my @cmds=();
	my $Dset=`date "+%Y-%m-%dT%H:00Z"`;
        push (@cmds,	"pmx set oozie namenode $$prop{namenode}{hostname}",
			"pmx set oozie oozieServer $$prop{namenode}{vip}",
			"pmx set oozie sshHost 127.0.0.1",
			"pmx set oozie snapshotPath /data/snapshots");
	my $jobs=$$prop{job};
	my $commonAttributes=$$prop{dataset}{common}{attribute};
	my $count=$$prop{collector}{component}{count};
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
		push (@cmds, "pmx subshell oozie set job $job attribute jobStart $Dset");
		push (@cmds, "pmx subshell oozie set job $job attribute jobEnd 2099-12-31T00:00Z");
	}
	
	push (@cmds,	"pmx subshell oozie set job PnsaSubscriberIb action SubscriberIBCreator attribute binaryInput true",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberIBCreator attribute outputDataset pnsa_subib",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberIBCreator attribute inputDatasets pnsa_radius",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberIBCreator attribute selfIpCleanupDataset pnsa_selfipcleanup1",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberIBCreator attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberIBCreator attribute mainClass com.guavus.mapred.atlas.job.subscriberib.SubscriberIBCreator",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberIBCreator attribute configFile /opt/etc/oozie/AtlasCubes/SubscriberIBCreator.xml",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibIpPortCleanup attribute binaryInput true",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibIpPortCleanup attribute outputDataset pnsa_ipportcleanup",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibIpPortCleanup attribute inputDatasets pnsa_subib",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibIpPortCleanup attribute mainClass com.guavus.mapred.atlas.job.SubscriberibIpPortCleanup.Main",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibIpPortCleanup attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibIpPortCleanup attribute configFile /opt/etc/oozie/AtlasCubes/AtlasCubes.xml",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibSelfIpCleanup attribute binaryInput true",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibSelfIpCleanup attribute outputDataset pnsa_selfipcleanup",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibSelfIpCleanup attribute inputDatasets pnsa_ipportcleanup",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibSelfIpCleanup attribute mainClass com.guavus.mapred.atlas.job.SubscriberibSelfIpCleanup.Main",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibSelfIpCleanup attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberibSelfIpCleanup attribute configFile /opt/etc/oozie/AtlasCubes/AtlasCubes.xml",
			"pmx subshell oozie set job PnsaSubscriberIb action SubscriberIBCreator attribute invalidRecordsThreshold 10",
			"pmx subshell oozie set job PnsaSubscriberIb attribute lastSuccessPath /data/local/LastSuccessfulOutput",
		

			"pmx subshell oozie set job Ipfixcp1 action DistcpAction attribute destDataset destIpfixRecords",
			"pmx subshell oozie set job Ipfixcp1 action DistcpAction attribute safeDelay 5100",
			"pmx subshell oozie set job Ipfixcp1 action DistcpAction attribute destNamenode $$commonAttributes{destNamenode}",
			"pmx subshell oozie set job Ipfixcp1 action DistcpAction attribute retryCount -1",
			"pmx subshell oozie set job Ipfixcp1 action DistcpAction attribute srcNamenode $$commonAttributes{srcNamenode}", 
			"pmx subshell oozie set job Ipfixcp1 action DistcpAction attribute srcDataset srcIpfixRecords",
			"pmx subshell oozie set job Ipfixcp1 action DistcpAction attribute retrySleep 60",
			"pmx subshell oozie set job Ipfixcp1 action DistcpAction attribute flags -overwrite",
			
			
			"pmx subshell oozie set job Ipfixcp2 action DistcpAction attribute destDataset destIpfixRecords",
			"pmx subshell oozie set job Ipfixcp2 action DistcpAction attribute safeDelay 5100",
                        "pmx subshell oozie set job Ipfixcp2 action DistcpAction attribute destNamenode $$commonAttributes{destNamenode}",
                        "pmx subshell oozie set job Ipfixcp2 action DistcpAction attribute retryCount -1",
                        "pmx subshell oozie set job Ipfixcp2 action DistcpAction attribute srcNamenode $$commonAttributes{srcNamenode}",
                        "pmx subshell oozie set job Ipfixcp2 action DistcpAction attribute srcDataset srcIpfixRecords",
                        "pmx subshell oozie set job Ipfixcp2 action DistcpAction attribute retrySleep 60",
                        "pmx subshell oozie set job Ipfixcp2 action DistcpAction attribute flags -overwrite",


			"pmx subshell oozie set job Ipfixcp3 action DistcpAction attribute destDataset destIpfixRecords",
			"pmx subshell oozie set job Ipfixcp3 action DistcpAction attribute safeDelay 5100",
                        "pmx subshell oozie set job Ipfixcp3 action DistcpAction attribute destNamenode $$commonAttributes{destNamenode}",
                        "pmx subshell oozie set job Ipfixcp3 action DistcpAction attribute retryCount -1",
                        "pmx subshell oozie set job Ipfixcp3 action DistcpAction attribute srcNamenode $$commonAttributes{srcNamenode}",
                        "pmx subshell oozie set job Ipfixcp3 action DistcpAction attribute srcDataset srcIpfixRecords",
                        "pmx subshell oozie set job Ipfixcp3 action DistcpAction attribute retrySleep 60",
                        "pmx subshell oozie set job Ipfixcp3 action DistcpAction attribute flags -overwrite",
		
			
			"pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute destDataset destSubscriberIB",
			"pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute destNamenode $$commonAttributes{destNamenode}",
			"pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute retryCount -1",
			"pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute srcNamenode $$commonAttributes{srcNamenode}",
			"pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute srcDataset srcSubscriberIB",
			"pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute retrySleep 120",
			"pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute flags -overwrite",
			"pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute safeDelay 5100",

 
			"pmx subshell oozie set job Radiuscp action DistcpAction attribute destDataset destRadiusRecords",
			"pmx subshell oozie set job Radiuscp action DistcpAction attribute destNamenode $$commonAttributes{destNamenode}",
			"pmx subshell oozie set job Radiuscp action DistcpAction attribute retryCount -1",
			"pmx subshell oozie set job Radiuscp action DistcpAction attribute srcNamenode $$commonAttributes{srcNamenode}",
			"pmx subshell oozie set job Radiuscp action DistcpAction attribute srcDataset srcRadiusRecords",
			"pmx subshell oozie set job Radiuscp action DistcpAction attribute retrySleep 60",
			"pmx subshell oozie set job Radiuscp action DistcpAction attribute flags -overwrite",
			"pmx subshell oozie set job Radiuscp action DistcpAction attribute safeDelay 5100",
	
			
			"pmx subshell oozie set job CleanupCollector attribute frequencyUnit hour",
			"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupOffset 12",
			"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets srcRadiusRecords",
			"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets srcIpfixRecords",


			"pmx subshell oozie set job CleanupSubIb attribute frequencyUnit hour",
			"pmx subshell oozie set job CleanupSubIb action CleanupAction attribute cleanupOffset 18",
			"pmx subshell oozie set job CleanupSubIb action CleanupAction attribute cleanupDatasets pnsa_subib",
			"pmx subshell oozie set job CleanupSubIb action CleanupAction attribute cleanupDatasets pnsa_selfipcleanup",
			"pmx subshell oozie set job CleanupSubIb action CleanupAction attribute cleanupDatasets pnsa_ipportcleanup",


			"pmx subshell oozie set job CleanupLogs attribute frequencyUnit day",
			"pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute cleanupOffset 15",
		# Intentionally put in the Namenode VIP to be consistent across upgraded sites, However, it needs to be ICN IPs of both namenodes. Plan to fix this in RC5 P3 MOP #
			"pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute collectorIPs $$prop{namenode}{vip}",


			"pmx subshell oozie set job BackupDistcp action BackupDistcpAction attribute bucketSize 3",
			"pmx subshell oozie set job BackupDistcp action BackupDistcpAction attribute safeDelay 39600",
			"pmx subshell oozie set job BackupDistcp action BackupDistcpAction attribute maxParallelThreads 1",
			"pmx subshell oozie set job BackupDistcp action BackupDistcpAction attribute destNamenode $$commonAttributes{destNamenode}",
			
			
			"pmx subshell oozie set job CleanupResidual attribute frequencyUnit day",
			"pmx subshell oozie set job CleanupResidual action CleanupDatasetAction attribute cleanupOffset 15",
			"pmx subshell oozie set job CleanupResidual action CleanupDatasetAction attribute cleanupDatasets srcIpfixResidual",
			"pmx subshell oozie set job CleanupResidual action CleanupDatasetAction attribute cleanupDatasets srcRadiusResidual",
			"pmx subshell oozie set job CleanupResidual action CleanupDatasetAction attribute cleanupDatasets pnsa_subib_residual",
			"pmx subshell oozie set job CleanupResidual action CleanupDatasetAction attribute cleanupDatasets pnsa_selfipcleanup_residual",
			"pmx subshell oozie set job CleanupResidual action CleanupDatasetAction attribute cleanupDatasets pnsa_ipportcleanup_residual",
			"pmx subshell oozie set job CleanupResidual action CleanupDatasetAction attribute leaveDonefile false",


		);



	push (@cmds,	"pmx subshell oozie add dataset pnsa_ipportcleanup_residual",
			"pmx subshell oozie set dataset pnsa_ipportcleanup_residual attribute startOffset 0",
			"pmx subshell oozie set dataset pnsa_ipportcleanup_residual attribute frequency 60",
			"pmx subshell oozie set dataset pnsa_ipportcleanup_residual attribute endOffset 0",
			"pmx subshell oozie set dataset pnsa_ipportcleanup_residual attribute doneFile _DONE",
			"pmx subshell oozie set dataset pnsa_ipportcleanup_residual attribute outputOffset 0",
			"pmx subshell oozie set dataset pnsa_ipportcleanup_residual attribute path /data/output/SubscriberIBIpPortCleanup/%Y/%M/%D/",
			"pmx subshell oozie set dataset pnsa_ipportcleanup_residual attribute pathType hdfs",

			"pmx subshell oozie add dataset pnsa_subib_residual",
			"pmx subshell oozie set dataset pnsa_subib_residual attribute startOffset 0",
			"pmx subshell oozie set dataset pnsa_subib_residual attribute frequency 60",
			"pmx subshell oozie set dataset pnsa_subib_residual attribute endOffset 0",
			"pmx subshell oozie set dataset pnsa_subib_residual attribute doneFile _DONE",
			"pmx subshell oozie set dataset pnsa_subib_residual attribute outputOffset 0",
			"pmx subshell oozie set dataset pnsa_subib_residual attribute path /data/output/SubscriberIB/%Y/%M/%D/",
			"pmx subshell oozie set dataset pnsa_subib_residual attribute pathType hdfs",

			"pmx subshell oozie add dataset srcIpfixResidual",
			"pmx subshell oozie set dataset srcIpfixResidual attribute startOffset 0",
			"pmx subshell oozie set dataset srcIpfixResidual attribute frequency 5",
			"pmx subshell oozie set dataset srcIpfixResidual attribute endOffset 0",
			"pmx subshell oozie set dataset srcIpfixResidual attribute doneFile _DONE",
			"pmx subshell oozie set dataset srcIpfixResidual attribute outputOffset 0",
			"pmx subshell oozie set dataset srcIpfixResidual attribute path /data/output/pnsa/ipfix/%Y/%M/%D/",
			"pmx subshell oozie set dataset srcIpfixResidual attribute pathType hdfs",

			"pmx subshell oozie add dataset srcRadiusResidual",
			"pmx subshell oozie set dataset srcRadiusResidual attribute startOffset 0",
			"pmx subshell oozie set dataset srcRadiusResidual attribute frequency 5",
			"pmx subshell oozie set dataset srcRadiusResidual attribute endOffset 0",
			"pmx subshell oozie set dataset srcRadiusResidual attribute doneFile _DONE",
			"pmx subshell oozie set dataset srcRadiusResidual attribute outputOffset 0",
			"pmx subshell oozie set dataset srcRadiusResidual attribute path /data/output/pnsa/pilotPacket/%Y/%M/%D/",
			"pmx subshell oozie set dataset srcRadiusResidual attribute pathType hdfs",
			
			"pmx subshell oozie add dataset pnsa_selfipcleanup",
			"pmx subshell oozie set dataset pnsa_selfipcleanup attribute startOffset 1",
			"pmx subshell oozie set dataset pnsa_selfipcleanup attribute frequency 60",
			"pmx subshell oozie set dataset pnsa_selfipcleanup attribute endOffset 1",
			"pmx subshell oozie set dataset pnsa_selfipcleanup attribute doneFile _DONE",
			"pmx subshell oozie set dataset pnsa_selfipcleanup attribute outputOffset 0",
			"pmx subshell oozie set dataset pnsa_selfipcleanup attribute path /data/output/SubscriberIBSelfIpCleanup/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset pnsa_selfipcleanup attribute pathType hdfs",

			"pmx subshell oozie add dataset pnsa_selfipcleanup1",
                        "pmx subshell oozie set dataset pnsa_selfipcleanup1 attribute startOffset 1",
                        "pmx subshell oozie set dataset pnsa_selfipcleanup1 attribute frequency 60",
                        "pmx subshell oozie set dataset pnsa_selfipcleanup1 attribute endOffset 1",
                        "pmx subshell oozie set dataset pnsa_selfipcleanup1 attribute doneFile _DONE",
                        "pmx subshell oozie set dataset pnsa_selfipcleanup1 attribute outputOffset 0",
                        "pmx subshell oozie set dataset pnsa_selfipcleanup1 attribute path /data/output/SubscriberIBSelfIpCleanup/%Y/%M/%D/%H/*",
                        "pmx subshell oozie set dataset pnsa_selfipcleanup1 attribute pathType hdfs",
		

			"pmx subshell oozie add dataset pnsa_selfipcleanup_residual",
			"pmx subshell oozie set dataset pnsa_selfipcleanup_residual attribute startOffset 1",
			"pmx subshell oozie set dataset pnsa_selfipcleanup_residual attribute frequency 60",
			"pmx subshell oozie set dataset pnsa_selfipcleanup_residual attribute endOffset 1",
			"pmx subshell oozie set dataset pnsa_selfipcleanup_residual attribute doneFile _DONE",
			"pmx subshell oozie set dataset pnsa_selfipcleanup_residual attribute outputOffset 0",
			"pmx subshell oozie set dataset pnsa_selfipcleanup_residual attribute path /data/output/SubscriberIBSelfIpCleanup/%Y/%M/%D/",
			"pmx subshell oozie set dataset pnsa_selfipcleanup_residual attribute pathType hdfs",

			"pmx subshell oozie add dataset pnsa_ipportcleanup",
			"pmx subshell oozie set dataset pnsa_ipportcleanup attribute startOffset 0",
			"pmx subshell oozie set dataset pnsa_ipportcleanup attribute frequency 60",
			"pmx subshell oozie set dataset pnsa_ipportcleanup attribute endOffset 0",
			"pmx subshell oozie set dataset pnsa_ipportcleanup attribute doneFile _DONE",
			"pmx subshell oozie set dataset pnsa_ipportcleanup attribute outputOffset 0",
			"pmx subshell oozie set dataset pnsa_ipportcleanup attribute path /data/output/SubscriberIBIpPortCleanup/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset pnsa_ipportcleanup attribute pathType hdfs",

			"pmx subshell oozie add dataset pnsa_subib",
			"pmx subshell oozie set dataset pnsa_subib attribute startOffset 0",
			"pmx subshell oozie set dataset pnsa_subib attribute frequency 60",
			"pmx subshell oozie set dataset pnsa_subib attribute endOffset 0",
			"pmx subshell oozie set dataset pnsa_subib attribute doneFile _DONE",
			"pmx subshell oozie set dataset pnsa_subib attribute outputOffset 0",
			"pmx subshell oozie set dataset pnsa_subib attribute path /data/output/SubscriberIB/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset pnsa_subib attribute pathType hdfs",

			"pmx subshell oozie add dataset pnsa_radius",
			"pmx subshell oozie set dataset pnsa_radius attribute startOffset 12",
			"pmx subshell oozie set dataset pnsa_radius attribute frequency 5",
			"pmx subshell oozie set dataset pnsa_radius attribute endOffset 1",
			"pmx subshell oozie set dataset pnsa_radius attribute doneFile _DONE",
			"pmx subshell oozie set dataset pnsa_radius attribute outputOffset 0",
			"pmx subshell oozie set dataset pnsa_radius attribute path /data/output/pnsa/pilotPacket/%Y/%M/%D/%H/%mi",
			"pmx subshell oozie set dataset pnsa_radius attribute pathType hdfs",

			"pmx subshell oozie add dataset srcIpfixRecords",
			"pmx subshell oozie set dataset srcIpfixRecords attribute startOffset 0",
			"pmx subshell oozie set dataset srcIpfixRecords attribute frequency 5",
			"pmx subshell oozie set dataset srcIpfixRecords attribute endOffset 0",
			"pmx subshell oozie set dataset srcIpfixRecords attribute doneFile _DONE",
			"pmx subshell oozie set dataset srcIpfixRecords attribute outputOffset 0",
			"pmx subshell oozie set dataset srcIpfixRecords attribute path /data/output/pnsa/ipfix/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset srcIpfixRecords attribute pathType hdfs",

			"pmx subshell oozie add dataset destIpfixRecords",
			"pmx subshell oozie set dataset destIpfixRecords attribute startOffset 0",
			"pmx subshell oozie set dataset destIpfixRecords attribute frequency 5",
			"pmx subshell oozie set dataset destIpfixRecords attribute endOffset 0",
			"pmx subshell oozie set dataset destIpfixRecords attribute doneFile _DONE",
			"pmx subshell oozie set dataset destIpfixRecords attribute outputOffset 0",
			"pmx subshell oozie set dataset destIpfixRecords attribute path /data/$$commonAttributes{DCName}/ipfix/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset destIpfixRecords attribute pathType hdfs",

			"pmx subshell oozie add dataset srcSubscriberIB",
			"pmx subshell oozie set dataset srcSubscriberIB attribute startOffset 0",
			"pmx subshell oozie set dataset srcSubscriberIB attribute frequency 60",
			"pmx subshell oozie set dataset srcSubscriberIB attribute endOffset 0",
			"pmx subshell oozie set dataset srcSubscriberIB attribute doneFile _DONE",
			"pmx subshell oozie set dataset srcSubscriberIB attribute outputOffset 0",
			"pmx subshell oozie set dataset srcSubscriberIB attribute path /data/output/SubscriberIBSelfIpCleanup/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset srcSubscriberIB attribute pathType hdfs",

			"pmx subshell oozie add dataset destSubscriberIB",
			"pmx subshell oozie set dataset destSubscriberIB attribute startOffset 0",
			"pmx subshell oozie set dataset destSubscriberIB attribute frequency 60",
			"pmx subshell oozie set dataset destSubscriberIB attribute endOffset 0",
			"pmx subshell oozie set dataset destSubscriberIB attribute doneFile distcp_DONE",
			"pmx subshell oozie set dataset destSubscriberIB attribute outputOffset 0",
			"pmx subshell oozie set dataset destSubscriberIB attribute path /data/$$commonAttributes{DCName}/SubscriberIB/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset destSubscriberIB attribute pathType hdfs",
			
			"pmx subshell oozie add dataset srcRadiusRecords",
			"pmx subshell oozie set dataset srcRadiusRecords attribute startOffset 0",
			"pmx subshell oozie set dataset srcRadiusRecords attribute frequency 5",
			"pmx subshell oozie set dataset srcRadiusRecords attribute endOffset 0",
			"pmx subshell oozie set dataset srcRadiusRecords attribute doneFile _DONE",
			"pmx subshell oozie set dataset srcRadiusRecords attribute outputOffset 0",
			"pmx subshell oozie set dataset srcRadiusRecords attribute path /data/output/pnsa/pilotPacket/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset srcRadiusRecords attribute pathType hdfs",

			"pmx subshell oozie add dataset destRadiusRecords",
			"pmx subshell oozie set dataset destRadiusRecords attribute startOffset 0",
			"pmx subshell oozie set dataset destRadiusRecords attribute frequency 5",
			"pmx subshell oozie set dataset destRadiusRecords attribute endOffset 0",
			"pmx subshell oozie set dataset destRadiusRecords attribute doneFile _DONE",
			"pmx subshell oozie set dataset destRadiusRecords attribute outputOffset 0",
			"pmx subshell oozie set dataset destRadiusRecords attribute path /data/$$commonAttributes{DCName}/pilotPacket/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset destRadiusRecords attribute pathType hdfs",
			
			# Default start times for datasets and jobs

			"pmx subshell oozie set dataset pnsa_ipportcleanup attribute startTime $Dset",
			"pmx subshell oozie set dataset pnsa_subib attribute startTime $Dset",
			"pmx subshell oozie set dataset pnsa_radius attribute startTime $Dset", 
			"pmx subshell oozie set dataset srcIpfixRecords attribute startTime $Dset",
			"pmx subshell oozie set dataset destIpfixRecords attribute startTime $Dset",
			"pmx subshell oozie set dataset srcSubscriberIB attribute startTime $Dset",
			"pmx subshell oozie set dataset destSubscriberIB attribute startTime $Dset",
			"pmx subshell oozie set dataset srcRadiusRecords attribute startTime $Dset",
			"pmx subshell oozie set dataset destRadiusRecords attribute startTime $Dset",
			"pmx subshell oozie set dataset pnsa_ipportcleanup_residual attribute startTime $Dset",
			"pmx subshell oozie set dataset pnsa_subib_residual attribute startTime $Dset",
			"pmx subshell oozie set dataset srcIpfixResidual attribute startTime $Dset",
			"pmx subshell oozie set dataset srcRadiusResidual attribute startTime $Dset",
			"pmx subshell oozie set dataset pnsa_selfipcleanup attribute startTime $Dset",
			"pmx subshell oozie set dataset pnsa_selfipcleanup1 attribute startTime $Dset",
			"pmx subshell oozie set dataset pnsa_selfipcleanup_residual attribute startTime $Dset",
			
				
			
			
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

