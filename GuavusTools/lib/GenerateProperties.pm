package GenerateProperties;
use strict;
use lib "../lib";
use Carp;

###########################################################################################################################


#sub new {

#	my $self=shift;
#	my $ref={};

#	bless GenerateProperties, $ref;

#	return $ref;

#}


my %typePropertiesMapping=(
			COLLECTOR1	=>["user","snmp","ntp","mapReduce","generateKeys","hostmap","sm","drbd"],
			COLLECTOR2      =>["user","snmp","ntp","generateKeys","hostmap","sm"],
			COMPUTE		=>["user","snmp","ntp","hostmap","generateKeys"],
			CACHINGCOMPUTE	=>["user","snmp","ntp","hostmap","generateKeys","iptablesCCompute"],
			UI		=>["user","snmp","ntp","hostmap","generateKeys","iptablesUI"]
		);

my %propertiesBehaviour=(
			'FIXED'		=>["user","snmp","ntp","mapReduce","generateKeys","hostmap","sm","drbd"],
			'VARIABLE'	=>["collector","cluster","iptables"],
			'COMMON'	=>["user","snmp","ntp","hostmap","generateKeys"]

		);

# Returns the ref to an array, listing property files required for a specified type.

sub filesRequired {

	#my $self=shift;
	my $type=shift;
	chomp $type;
	return $typePropertiesMapping{$type} if (defined $typePropertiesMapping{$type});
	return $propertiesBehaviour{$type}; #if (defined $propertiesBehaviour{$type});
	return undef;

}


#===========================================#
# Files to be generated
#===========================================#

sub netFiles {

	my $self=shift;
	my $ref=shift;
	my $FixedFiles=filesRequired("FIXED");
	my $VariableFiles=filesRequired("VARIABLE");
	my @list=();
	my %prop=();
	
	push (@list, @$FixedFiles);

	foreach my $prop (keys %$ref) {
		if ($prop=~/(collector)(1)/i) {
			my $count = $$ref{$prop};
			my $incList=();
			foreach my $filename (@$VariableFiles) {
				if ($filename=~/collector/) {
					push (@list,"$filename"."1");
					push (@$incList,"$filename"."1");
					next; 	
				}
				push (@list,"collector1$filename");
				push (@$incList,"collector1$filename");
			}
			my $tmp=$typePropertiesMapping{COLLECTOR1};
			push (@$incList,@$tmp);
			foreach my $no (keys %$count) {
				next if ($no!~/\d/);
				push (@list,"$$ref{$prop}{$no}{IP}");
				$prop{$$ref{$prop}{$no}{IP}}{type}="COLLECTOR1";
				$prop{$$ref{$prop}{$no}{IP}}{hostname}=$$ref{$prop}{$no}{HOSTNAME};
				$prop{$$ref{$prop}{$no}{IP}}{incList}=$incList;
				#---------------------------------------------#
			 	my $intf=$$ref{$prop}{$no}{INTERFACE};
				foreach my $intNo (keys %$intf) {

				$prop{$$ref{$prop}{$no}{IP}}{interface}{$$intf{$intNo}{NAME}}{ip}=	$$ref{$prop}{$no}{INTERFACE}{$intNo}{IP};
				$prop{$$ref{$prop}{$no}{IP}}{interface}{$$intf{$intNo}{NAME}}{subnet}=	$$ref{$prop}{$no}{INTERFACE}{$intNo}{SUBNET};
				$prop{$$ref{$prop}{$no}{IP}}{interface}{$$intf{$intNo}{NAME}}{bond}=	$$ref{$prop}{$no}{INTERFACE}{$intNo}{BOND} if (defined $$ref{$prop}{$no}{INTERFACE}{$intNo}{BOND});
				$prop{$$ref{$prop}{$no}{IP}}{interface}{$$intf{$intNo}{NAME}}{comment}=	$$ref{$prop}{$no}{INTERFACE}{$intNo}{COMMENT} if (defined $$ref{$prop}{$no}{INTERFACE}{$intNo}{COMMENT});
				next;
				
				}
				#---------------------------------------------#
			}
		} elsif ($prop=~/(collector)(\d)/i) {				# Every collector2 type node except namenode, 'll not have hadoop, oozie, drbd config.
			my $c=$2;
		#if ($prop=~/(collector)(2)/i) {
                        my $count = $$ref{$prop};
                        my $incList=();
                        foreach my $filename (@$VariableFiles) {
                                if ($filename=~/collector/) {
					push (@list,"$filename"."$c");		# Every collector2 type node 'll have separate collector.prop, iptables.prop and cluster.
					push (@$incList,"$filename"."$c");
                                        #push (@list,"$filename"."2");
                                        #push (@$incList,"$filename"."2");
                                        next;
                                }
				push (@list,"collector"."$c"."$filename");
                                push (@$incList,"collector"."$c"."$filename");
                                #push (@list,"collector2$filename");
                                #push (@$incList,"collector2$filename");
                        }
                        my $tmp=$typePropertiesMapping{COLLECTOR2};
                        push (@$incList,@$tmp);
                        foreach my $no (keys %$count) {
                                next if ($no!~/\d/);
                                push (@list,"$$ref{$prop}{$no}{IP}");
                                $prop{$$ref{$prop}{$no}{IP}}{type}="COLLECTOR$c";
                                $prop{$$ref{$prop}{$no}{IP}}{hostname}=$$ref{$prop}{$no}{HOSTNAME};
                                $prop{$$ref{$prop}{$no}{IP}}{incList}=$incList;
                        }
		#}
		}

		if ($prop=~/^compute/i) {
			my $count = $$ref{$prop};
			my $tmp=$typePropertiesMapping{COMPUTE};
			my $incList=();
			push (@$incList,@$tmp);								# Include list 'll be common for all computes.
			foreach my $no (keys %$count) {
				#next if ($no!~/\d/);
                                push (@list,"$$ref{$prop}{$no}{IP}");					# List should include all the compute IPs, with other specific details.
				$prop{$$ref{$prop}{$no}{IP}}{type}="COMPUTE";
				$prop{$$ref{$prop}{$no}{IP}}{hostname}=$$ref{$prop}{$no}{HOSTNAME};
				$prop{$$ref{$prop}{$no}{IP}}{incList}=$incList;				# Push in the include list, which stands common for all computes.
                        }
		}

		#if ($prop=~/cachingcompute(\d)/i) {
		#	my $count = $$ref{$prop};
                #        foreach my $no (keys %$count) {
                #                push (@list,"$$ref{$prop}{$no}{IP}");
                #        }
		#}

		#if ($prop=~/UI(\d)/i) {
		#	my $count = $$ref{$prop};
                #        foreach my $no (keys %$count) {
                #                push (@list,"$$ref{$prop}{$no}{IP}");
                #        }
                #}
			
	}
	
	my @ret=();	
	push(@ret,"\%prop","\@list");
	return \%prop, \@list;	
	
}


sub ipProp {
	my $self=shift;
	my $FH=shift;
	my $prop=shift;
	my $ip=shift;
	my @cmds=();
	#foreach my $ip (keys %$prop) {
	my $len=length($ip);
	print "$ip.prop";
		
		@cmds=("# Product",
			"build=Atlas",
			"# Release",
			"version=3.0MUR",

			"# Configure Hostname",
			"ip.hostname=$$prop{$ip}{hostname}"
		);
		if ($$prop{$ip}{type}=~/collector1/i) {
			push (@cmds,"# ICN IP Required where you include drbd config",
			    "drbd.self.ip=$ip"
			);
		}
		if (defined $$prop{$ip}{interface}) {

			my $intHash=$$prop{$ip}{interface};
			push (@cmds, "###########################",
	               	             "# Interface Configuration #",
                        	     "###########################"
			);

			foreach my $int (keys %$intHash) {
				push (@cmds,	"interface.$int.ip=$$intHash{$int}{ip}",
						"interface.$int.subnet=$$intHash{$int}{subnet}");
				push (@cmds,	"interface.$int.bond=$$intHash{$int}{bond}") if (defined $$intHash{$int}{bond});
				push (@cmds,    "interface.$int.comment=$$intHash{$int}{comment}") if (defined $$intHash{$int}{comment});
			}
		}

		if (defined $$prop{$ip}{incList}) {
			my $include=$$prop{$ip}{incList};
			push (@cmds,    "#####################################################",
              	                	"# Include Defaults				     #",
                                	"#####################################################"
			);
			foreach my $incProp (@$include) {
				push (@cmds,"include=$incProp");
			}


		}
		
	
	#}

	chomp @cmds;
	print $FH "$_\n" foreach(@cmds);
	my $l=50-$len;
	print "."x$l;
	print "Done!\n\n";
	return;
}

sub hostmap {
	my $self=shift;
	my $FH=shift;
	my $ipProp=shift;			# Self created structure, with IP as base.
	my $feedin=shift;			# User supplied structure.
	my @cmds=();
	push (@cmds, "# Routing configuration");
	foreach my $ip (keys %$ipProp) {
		push (@cmds, "ip.host.$$ipProp{$ip}{hostname}=$ip");
	}	
		push (@cmds, "ip.map-hostname=no");
	foreach my $clustKey (keys %$feedin) {
		push (@cmds, "ip.host.$$feedin{$clustKey}{CLUSTER}{HOSTNAME}=$$feedin{$clustKey}{CLUSTER}{VIP}") if defined ($$feedin{$clustKey}{CLUSTER}{HOSTNAME});
	}
	chomp @cmds;
	print $FH "$_\n" foreach(@cmds);
	return;
}

sub user {
	my $self=shift;
	my $FH=shift;
	my $ipProp=shift;
	my $feedin=shift;
        my @cmds=();
	push (@cmds, "# User Configuration",
		     "user.root.status=enable",
		     "user.root.password=$$feedin{ROOT}{PASSWORD}",
		     "user.admin.status=enable",
		     "user.admin.password=admin\@123"
		);
	chomp @cmds;
	print $FH "$_\n" foreach(@cmds);
        return;

}

sub snmp {
	my $self=shift;
	my $FH=shift;
        my $ipProp=shift;
        my $feedin=shift;
        my @cmds=();
        push (@cmds,	"# SNMP common configuration",
			"snmp.server.ip=$$feedin{SNMP}{TRAPRECEIVER}",
			"snmp.server.community=$$feedin{SNMP}{COMMUNITY}",
			"snmp.server.location=$$feedin{DISTRIBUTIONCENTER}{NAME}"
		);
        chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;
}


sub ntp {
	my $self=shift;
	my $FH=shift;
	my $ipProp=shift;
	my $feedin=shift;
	my @cmds=();
	push (@cmds,	"# NTP Configuration ",
			"ntp.server1.ip=$$feedin{NTP}{IP}",
			"ntp.server1.enable=yes"
		);
        chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;
}

sub generateKeys {
	my $self=shift;
	my $FH=shift;
	my $ipProp=shift;
        my $feedin=shift;
        my @cmds=();
        push (@cmds,	"# Whether want to generate ssh keys or not.",
			"# Required for Collectors.",
			"ssh.key.admin=dsa2"
		);
	chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;
}  

sub collector {
	my $self=shift;
	my $FH=shift;
	my $ipProp=shift;
        my $feedin=shift;
	my $instanceID=shift;		# Instance ID remains same across all the Collector components, however, we use this number internally in the collector output path only
        my @cmds=();
        push (@cmds,	"# Collector nodes configuration on Collection Centre.",
			"# Format: collector.adaptor.<name>.<attribute>=<value>",
			"# Count stands to be number of collectors being used for one compute cluster. Produces o/p dir.",
			"#########################",
			"# Collector Configuration",
			"#########################",
			"#collector.instance.id.adaptor.param=value",
			"collector.DCName=$$feedin{DISTRIBUTIONCENTER}{NAME}",
			"collector.instance.$instanceID.edrflow.timeout=$$feedin{COLLECTOR}{EDRFLOW}{TIMEOUT}",
			"collector.instance.$instanceID.edrflow.inputdir=$$feedin{COLLECTOR}{EDRFLOW}{DIRECTORY}",
			"collector.instance.$instanceID.edrhttp.timeout=$$feedin{COLLECTOR}{EDRHTTP}{TIMEOUT}",
			"collector.instance.$instanceID.edrhttp.inputdir=$$feedin{COLLECTOR}{EDRHTTP}{DIRECTORY}",

			"collector.instance.$instanceID.edrflow.flowFile.compression=$$feedin{COLLECTOR}{EDRFLOW}{FILECOMPRESSION}",
			"collector.instance.$instanceID.edrhttp.httpFile.compression=$$feedin{COLLECTOR}{EDRHTTP}{FILECOMPRESSION}",
   			"collector.instance.$instanceID.edrflow.dropAlarmClearInterval=$$feedin{COLLECTOR}{EDRFLOW}{DROPCLEARINTERVAL}",
			"collector.instance.$instanceID.edrhttp.dropAlarmClearInterval=$$feedin{COLLECTOR}{EDRHTTP}{DROPCLEARINTERVAL}",  
   			"collector.instance.$instanceID.edrflow.dropAlarmRaiseInterval=$$feedin{COLLECTOR}{EDRFLOW}{RAISEINTERVAL}",
			"collector.instance.$instanceID.edrhttp.dropAlarmRaiseInterval=$$feedin{COLLECTOR}{EDRHTTP}{RAISEINTERVAL}",
			"collector.instance.$instanceID.edrflow.dropAlarmThreshold=$$feedin{COLLECTOR}{EDRFLOW}{DROPTHRESHOLD}",
			"collector.instance.$instanceID.edrhttp.dropAlarmThreshold=$$feedin{COLLECTOR}{EDRHTTP}{DROPTHRESHOLD}",
			"collector.instance.$instanceID.edrflow.noDataAlarmRepeat=$$feedin{COLLECTOR}{EDRFLOW}{NODATAALARMREPEAT}",
			"collector.instance.$instanceID.edrhttp.noDataAlarmRepeat=$$feedin{COLLECTOR}{EDRHTTP}{NODATAALARMREPEAT}",
			"collector.instance.$instanceID.edrflow.filenameFormat=$$feedin{COLLECTOR}{EDRFLOW}{FILENAMEFORMAT}",
			"collector.instance.$instanceID.edrhttp.filenameFormat=$$feedin{COLLECTOR}{EDRHTTP}{FILENAMEFORMAT}",
			"collector.instance.$instanceID.edrflow.transferFilenameFormat=$$feedin{COLLECTOR}{EDRFLOW}{TRANSFERFILENAME}",
			"collector.instance.$instanceID.edrhttp.transferFilenameFormat=$$feedin{COLLECTOR}{EDRHTTP}{TRANSFERFILENAME}",
		);
	chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;

} 

sub sm {
	my $self=shift;
	my $FH=shift;
        my $ipProp=shift;
        my $feedin=shift;
        my @cmds=();
	push (@cmds,	"######################",
			"# SM Config",
			"######################",
			"sm.instaNode.ip=$$feedin{CACHINGCOMPUTE}{CLUSTER}{VIP}"
		);
        chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;
} 

sub cluster {
	my $self=shift;
        my $FH=shift;
	my $ipProp=shift;
        my $feedin=shift;
	my $clusterID=shift;		# Cluster ID will differentiate the multiple clusters and their applicability to the different group of collectors.
	chomp $clusterID;
        my @cmds=();
	my $collectorType="COLLECTOR"."$clusterID";
        push (@cmds,	"#######################",
			"# Cluster Configuration",
			"#######################",
			"cluster.COL-CLUSTER$clusterID.name=$$feedin{$collectorType}{CLUSTER}{HOSTNAME}",
			"cluster.COL-CLUSTER$clusterID.interface=$$feedin{$collectorType}{CLUSTER}{INTERFACE}",
			"cluster.COL-CLUSTER$clusterID.expected-nodes=$$feedin{$collectorType}{CLUSTER}{NODES}",
			"cluster.COL-CLUSTER$clusterID.master.address=$$feedin{$collectorType}{CLUSTER}{VIP}",
			"cluster.COL-CLUSTER$clusterID.master.subnet=$$feedin{$collectorType}{CLUSTER}{SUBNET}",
			"cluster.COL-CLUSTER$clusterID.master.interface=$$feedin{$collectorType}{CLUSTER}{INTERFACE}"
		);

	chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;
} 

sub drbd {
	my $self=shift;
        my $FH=shift;
	my $ipProp=shift;
        my $feedin=shift;
        my @cmds=();
	my %count=(1=>"one", 2=>"two", 3=>"three", 4=>"four", 5=>"five", 6=>"six", 7=>"seven", 8=>"eight",9=>"nine", 10=>"ten");
        push (@cmds,	"###################################",
			"# DRBD # Hostnames and IP addresses",
			"###################################"
	);
	my $c=0;				# There may be multiple drbd hosts. All must be of type "COLLECTOR1".
	foreach my $ip (keys %$ipProp) {
		if ($$ipProp{$ip}{type}=~/^collector1/i) {
			$c=$c+1;
			push (@cmds,	"drbd.host"."$count{$c}".".hostname=$$ipProp{$ip}{hostname}",
					"drbd.host"."$count{$c}".".ip=$ip"
			);
		}
		next;
	}
        chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;
} 

sub iptables {
	my $self=shift;
	my $FH=shift;
	my $ipProp=shift;
        my $feedin=shift;
	my $collectorID=shift;
        my @cmds=();
        push (@cmds,	"##########",
			"# IPs for collectors.",
			"##########",
	);
	my $c=0;
	foreach my $ip (keys %$ipProp) {
		if ($$ipProp{$ip}{type}=~/^collector$collectorID/i) {
			push (@cmds, "ip.filter.input.accept.$c=$ip");
			$c=$c+1;
		}
		next;
	}	

	chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;
}

sub mapReduce {				# Assumed, 'll be applicable to type COLLECTOR1 only.
	my $self=shift;
        my $FH=shift;
	my $ipProp=shift;
        my $feedin=shift;
	my @cmds=();
	push (@cmds,	"####################",
			"# Hadoop Oozie",
			"####################",
	);
	my $c=0;
	my $s=0;
	my $h=0;
	foreach my $ip (keys %$ipProp) {

		if ($$ipProp{$ip}{type}=~/^collector(\d)/i) {
			my $a=$1;
			$h=$a if ($h<$a);
			push (@cmds, "hadoop.clients.$c=$ip");
			$c=$c+1;
		} elsif ($$ipProp{$ip}{type}=~/^compute/i) {
			push (@cmds, "hadoop.slaves.$s=$ip");
			$s=$s+1;
		}
	
	}
	push (@cmds, "oozie.collector.component.count=$h");
	if (defined $$feedin{COLLECTOR1}{CLUSTER}{VIP}) {
		# Always be a COLLECTOR1.CLUSTER VIP and Hostname, if it is a single node COLLECTOR1, then it is self IP(COLLECTOR1.1).
		push (@cmds, 	"hadoop.master.ip=$$feedin{COLLECTOR1}{CLUSTER}{VIP}",
				"oozie.namenode.vip=$$feedin{COLLECTOR1}{CLUSTER}{VIP}",		
				"oozie.namenode.hostname=$$feedin{COLLECTOR1}{CLUSTER}{HOSTNAME}",
				"oozie.job.SubscriberBytes.action.DistcpBytes.attribute.srcNamenode=$$feedin{COLLECTOR1}{CLUSTER}{HOSTNAME}"
		);
	
	} else {

		push (@cmds, "hadoop.master.ip=$$feedin{COLLECTOR1}{1}{IP}",
	                     "oozie.namenode.vip=$$feedin{COLLECTOR1}{1}{IP}",
			     "oozie.namenode.hostname=$$feedin{COLLECTOR1}{1}{HOSTNAME}",
			     "oozie.job.SubscriberBytes.action.DistcpBytes.attribute.srcNamenode=$$feedin{COLLECTOR1}{1}{HOSTNAME}"
                );
	}

	push (@cmds, 	"# Job details (EDR)",
			"oozie.job.EDR.name=EDRCubes",
			"oozie.job.EDR.path=/opt/etc/oozie/EDRCubes",
			"oozie.job.EDR.attribute.jobFrequency=60",
			"oozie.job.EDR.attribute.binInterval=3600",

			"# Job action attributes",
			"oozie.job.EDR.action.BaseCubes.attribute.timeout=-1",
			"oozie.job.EDR.action.SubcrBytesAgg.attribute.timeout=0",
			"oozie.job.EDR.action.TopN.attribute.timeout=0",
			"oozie.job.EDR.action.SubcrDev.attribute.timeout=0",
			"oozie.job.EDR.action.Rollup.attribute.timeout=-1",

			"# Job details (CubeExporter)",
			"oozie.job.CubeExporter.name=ExporterJob",
			"oozie.job.CubeExporter.path=/opt/etc/oozie/CubeExporter",
			"oozie.job.CubeExporter.attribute.jobFrequency=60",

			"# Job action attributes",
			"oozie.job.CubeExporter.action.ExporterAction.attribute.instaHost=$$feedin{CACHINGCOMPUTE}{CLUSTER}{VIP}",
			
			"# Job details (TopUrl)",
			"oozie.job.TopUrl.name=TopUrl",
			"oozie.job.TopUrl.path=/opt/etc/oozie/TopUrl",
			"oozie.job.TopUrl.attribute.jobFrequency=60",

			"# Job action attributes",
			"oozie.job.TopUrl.action.HHUrl.attribute.timeout=-1",

			"# Job details (TopSubcr)",
			"oozie.job.TopSubcr.name=TopSubcr",
			"oozie.job.TopSubcr.path=/opt/etc/oozie/TopSubcr",
			"oozie.job.TopSubcr.attribute.jobFrequency=10080",

			"# Job action attributes",
			"oozie.job.TopSubcr.action.BytesAgg.attribute.timeout=-1",
			"oozie.job.TopSubcr.action.TopSubscribers.attribute.timeout=0",
			"oozie.job.TopSubcr.action.TopSubcrMerge.attribute.timeout=0",

			"# Job details (SubscriberBytes)",
			"oozie.job.SubscriberBytes.name=SubscriberBytes",
			"oozie.job.SubscriberBytes.path=/opt/etc/oozie/SubscriberBytes",
			"oozie.job.SubscriberBytes.attribute.jobFrequency=1",
			"oozie.job.SubscriberBytes.attribute.frequencyUnit=month",

			"# Job action attributes",
			"oozie.job.SubscriberBytes.action.DistcpBytes.attribute.destNamenode=$$feedin{COLLECTOR1}{CLUSTER}{HOSTNAME}",
			#"oozie.job.SubscriberBytes.action.DistcpBytes.attribute.srcNamenode=$$feedin{COLLECTOR1}{CLUSTER}{HOSTNAME}",
			"oozie.job.SubscriberBytes.action.SubBytesMapRedAction.attribute.timeout=-1",
			"oozie.job.SubscriberBytes.action.DistcpBytes.attribute.timeout=0",

			"# Job details (SubscriberSegment)",
			"oozie.job.SubscriberSegment.name=SubscriberSegment",
			"oozie.job.SubscriberSegment.path=/opt/etc/oozie/SubscriberSegment",
			"oozie.job.SubscriberSegment.attribute.jobFrequency=1",
			"oozie.job.SubscriberSegment.attribute.frequencyUnit=month",
	
			"# Job action attributes",
			"oozie.job.SubscriberSegment.action.SubSegMapRedAction.attribute.timeout=-1",

			"# Job details (ConsistentTopSubcr)",
			"oozie.job.ConsistentTopSubcr.name=ConsistentTopSubcr",
			"oozie.job.ConsistentTopSubcr.path=/opt/etc/oozie/ConsistentTopSubcr",
			"oozie.job.ConsistentTopSubcr.attribute.jobFrequency=10080",

			"# Job action attributes",
			"oozie.job.ConsistentTopSubcr.action.ConsistentSubcrs.attribute.timeout=-1",

			"# Job details (CleanupCollector)",
			"oozie.job.CleanupCollector.name=CleanupDataset",
			"oozie.job.CleanupCollector.path=/opt/etc/oozie/CleanupDataset",
			"oozie.job.CleanupCollector.attribute.jobFrequency=1",
			"oozie.job.CleanupCollector.attribute.frequencyUnit=hour",

			"# Job details (CleanupLogs)",
			"oozie.job.CleanupLogs.name=CleanupLogs",
			"oozie.job.CleanupLogs.path=/opt/etc/oozie/CleanupLogs",
			"oozie.job.CleanupLogs.attribute.jobFrequency=1",
			"oozie.job.CleanupLogs.attribute.frequencyUnit=day",
		
			"# Job details (CleanupAtlas)",
			"oozie.job.CleanupAtlas.name=CleanupAtlas",
			"oozie.job.CleanupAtlas.path=/opt/etc/oozie/CleanupAtlas",
			"oozie.job.CleanupAtlas.attribute.jobFrequency=1",
			"oozie.job.CleanupAtlas.attribute.frequencyUnit=day"
	);
		
	chomp @cmds;
        print $FH "$_\n" foreach(@cmds);
        return;

}

1;
