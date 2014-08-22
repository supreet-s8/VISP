package Oozie;

use strict;
use lib "../lib";
use Carp;
use Time::Local;

###########################################################################################################################

# Returns reference to an array of respective oozie commands.

sub Atlas15_DistributionCentre {
	print "\nOops...! Outdated Solution Version...\n";
	return undef;
}

sub Atlas15_AggregationCentre {
	print "\nOops...! Outdated Solution Version...\n";
        return undef;
}

sub Atlas20_DistributionCentre {
	my $self=shift;
	my $dataStartTime=shift;
	#my $jobEnd=shift;
	my $cred=shift;						# Receiving reference to the properties file #
	my $count=$$cred{oozie}{collector}{component}{count};	# Collector component count #
	my ($dataYY,$dataMM,$dataDD,$datahh,$datamm);
	if ($dataStartTime=~(/(\d{4,4})+\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/)) {
		$dataYY=sprintf("%04d",$1);
		$dataMM=sprintf("%02d",$2);
		$dataDD=sprintf("%02d",$3);
		$datahh=sprintf("%02d",$4);
		$datamm=sprintf("%02d",$5);
	}
	my @cmds=();
	my %jobLagScheduleMinutes=(
				Atlas			=>	60,
				Distcp			=>	60,
				TopUrl			=>	60,
				TopSubcr		=>	60*24*7,
				ConsistentTopSubcr	=>	60*24*21,
				CleanupAtlas		=>	60*24,
				CleanupCollector	=>	60*24,
				CleanupLogs		=>	60*24*5,
			);
	my %jobLagScheduleMonths=(
					SubscriberBytes	=>	{Months		=>	1,
								 dataSets	=>	["BytesAgg_month"]}
				 );
	my @dataSets = (
                	"atlas_subib",
			#"atlas_wng",
			"atlas_wngib",
			"atlas_basecube","atlas_topn","atlas_subbytes",
			"atlas_subdev","atlas_rollup","DistcpCubes",
			"atlas_hhurl","atlas_topurl",
			"MonthlyBytes","MonthlyBytes1","BytesAgg",
			"WeeklyBytes","TopSubcrWeekly","TopSubcrMerge",
			"ConsistentSubcr"
                );	

	my $c=1;
        # Using collector component count #
        while($c<=$count) {
        	push(@dataSets,
				"atlas_radius_$c",
				"atlas_ipfix_$c",
				"atlas_tcpfix_$c"	
				#"atlas_wng_$c"
                );
    	        $c++;
	}
	
			
	chomp @dataSets;

	foreach my $dataSet (@dataSets){
        	push(@cmds, "pmx subshell oozie set dataset $dataSet attribute startTime $dataStartTime");
        }
	chomp @cmds;

	foreach my $job (keys %jobLagScheduleMinutes) {
		my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
		if ($job=~/cleanup/i) {
			my $time="00".":"."00"."Z";	
			$jobSchedule=~s/(\d{4,4}\-\d{2,2}\-\d{2,2}T)\d{2,2}\:\d{2,2}Z/$1$time/;
		}	
		push(@cmds, "pmx subshell oozie set job $job attribute jobStart $jobSchedule",
		#	    "pmx subshell oozie set job $job attribute jobEnd $jobEnd"
			);
	
	}

	foreach my $job (keys %jobLagScheduleMonths) {
		my $jobDataMM=$dataMM+$jobLagScheduleMonths{$job}{Months};
		my $jobDataYY=$dataYY;
		if ($jobDataMM>12) {
			$jobDataMM=sprintf("%02d",$jobDataMM-12);
			print "jobDataMM=$jobDataMM\n";
			$jobDataYY=$jobDataYY+1;
		}
		my $jobDataDD="01";
		my $jobDatahh="00";
		my $jobDatamm="00";
		my $jobSchedule="$jobDataYY\-$jobDataMM\-$jobDataDD"."T"."$jobDatahh".":"."$jobDatamm"."Z";
		push(@cmds, "pmx subshell oozie set job $job attribute jobStart $jobSchedule",
		#	    "pmx subshell oozie set job $job attribute jobEnd $jobEnd"
		);
		# StartTime for Datasets as input to Monthly jobs need to be set at 00:00Hrs on same day as of other datasets.
		my $jobLagMonths=$jobLagScheduleMonths{$job}{dataSets};	
		foreach my $dataSet (@$jobLagMonths){
			my $dataSethh="00";
			my $dataSetmm="00";
			my $dataSetStartTime="$dataYY\-$dataMM\-$dataDD"."T"."$dataSethh".":"."$dataSetmm"."Z";	
			push(@cmds,"pmx subshell oozie set dataset $dataSet attribute startTime $dataSetStartTime");
		}
			
	}
		
	chomp @cmds;
	return \@cmds;	

}


sub Atlas21_DistributionCentre {
        my $self=shift;
        my $dataStartTime=shift;
        #my $jobEnd=shift;
        my $cred=shift;                                         # Receiving reference to the properties file #
        my $count=$$cred{oozie}{collector}{component}{count};   # Collector component count #
        my ($dataYY,$dataMM,$dataDD,$datahh,$datamm);
        if ($dataStartTime=~(/(\d{4,4})+\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/)) {
                $dataYY=sprintf("%04d",$1);
                $dataMM=sprintf("%02d",$2);
                $dataDD=sprintf("%02d",$3);
                $datahh=sprintf("%02d",$4);
                $datamm=sprintf("%02d",$5);
        }
        my @cmds=();
        my %jobLagScheduleMinutes=(
                                Atlas                   =>      60,
                                Distcp                  =>      60,
                                TopUrl                  =>      60,
                                TopSubcr                =>      60*24*7,
                                ConsistentTopSubcr      =>      60*24*21,
                                CleanupAtlas            =>      60*24,
                                CleanupCollector        =>      60*24,
                                CleanupLogs             =>      60*24*5,
                        );
        my %jobLagScheduleMonths=(
                                        SubscriberBytes =>      {Months         =>      1,
                                                                 dataSets       =>      ["BytesAgg_month"]}
                                 );
        my @dataSets = (
                        "atlas_subib",
                        #"atlas_wng",
                        "atlas_wngib",
                        "atlas_basecube","atlas_topn","atlas_subbytes",
                        "atlas_subdev","atlas_rollup","DistcpCubes",
                        "atlas_hhurl","atlas_topurl",
                        "MonthlyBytes","MonthlyBytes1","BytesAgg",
                        "WeeklyBytes","TopSubcrWeekly","TopSubcrMerge",
                        "ConsistentSubcr"
                );

        my $c=1;
        # Using collector component count #
        while($c<=$count) {
                push(@dataSets,
                                "atlas_radius_$c",
                                "atlas_ipfix_$c",
                                "atlas_tcpfix_$c"
                                #"atlas_wng_$c"
                );
                $c++;
        }


        chomp @dataSets;

        foreach my $dataSet (@dataSets){
                push(@cmds, "pmx subshell oozie set dataset $dataSet attribute startTime $dataStartTime");
        }
        chomp @cmds;

        foreach my $job (keys %jobLagScheduleMinutes) {
                my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                if ($job=~/cleanup/i) {
                        my $time="00".":"."00"."Z";
                        $jobSchedule=~s/(\d{4,4}\-\d{2,2}\-\d{2,2}T)\d{2,2}\:\d{2,2}Z/$1$time/;
                }
                push(@cmds, "pmx subshell oozie set job $job attribute jobStart $jobSchedule",
                #           "pmx subshell oozie set job $job attribute jobEnd $jobEnd"
                        );

        }

        foreach my $job (keys %jobLagScheduleMonths) {
                my $jobDataMM=$dataMM+$jobLagScheduleMonths{$job}{Months};
                my $jobDataYY=$dataYY;
                if ($jobDataMM>12) {
                        $jobDataMM=sprintf("%02d",$jobDataMM-12);
                        print "jobDataMM=$jobDataMM\n";
                        $jobDataYY=$jobDataYY+1;
                }
                my $jobDataDD="01";
                my $jobDatahh="00";
                my $jobDatamm="00";
                my $jobSchedule="$jobDataYY\-$jobDataMM\-$jobDataDD"."T"."$jobDatahh".":"."$jobDatamm"."Z";
                push(@cmds, "pmx subshell oozie set job $job attribute jobStart $jobSchedule",
                #           "pmx subshell oozie set job $job attribute jobEnd $jobEnd"
                );
                # StartTime for Datasets as input to Monthly jobs need to be set at 00:00Hrs on same day as of other datasets.
                my $jobLagMonths=$jobLagScheduleMonths{$job}{dataSets};
                foreach my $dataSet (@$jobLagMonths){
                        my $dataSethh="00";
                        my $dataSetmm="00";
                        my $dataSetStartTime="$dataYY\-$dataMM\-$dataDD"."T"."$dataSethh".":"."$dataSetmm"."Z";
                        push(@cmds,"pmx subshell oozie set dataset $dataSet attribute startTime $dataSetStartTime");
                }

        }

        chomp @cmds;
        return \@cmds;

}

sub Atlas30MUR_MURDistributionCentre {
        my $self=shift;
        my $dataStartTime=shift;
        #my $jobEnd=shift;
        my $cred=shift;                                         # Receiving reference to the properties file #
        my $count=$$cred{oozie}{collector}{component}{count};   # Collector component count #
        my ($dataYY,$dataMM,$dataDD,$datahh,$datamm);
        if ($dataStartTime=~(/(\d{4,4})+\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/)) {
                $dataYY=sprintf("%04d",$1);
                $dataMM=sprintf("%02d",$2);
                $dataDD=sprintf("%02d",$3);
                $datahh=sprintf("%02d",$4);
                $datamm=sprintf("%02d",$5);
        }
        my @cmds=();
        my %jobLagScheduleMinutes=(
                                EDR                     =>      60,
                                CubeExporter            =>      60,
                                TopUrl                  =>      60,
				CleanupCollector	=>	60,
				CleanupLogs		=>	60*24,
				CleanupAtlas		=>	60*24,
                                TopSubcr                =>      60*24*7,
                                ConsistentTopSubcr      =>      60*24*21
                        );
        my %jobLagScheduleMonths=(
                                        SubscriberBytes =>      {Months         =>      1,},
                                                                 #dataSets       =>      ["BytesAgg_month"]},
					SubscriberSegment=>	{Months		=>	1}
                                 );
        my @dataSets = (
                        #"atlas_subib",
                        #"atlas_wng",
                        #"atlas_wngib",
                        "atlas_basecube","atlas_topn","atlas_subbytes",
                        "atlas_subdev","atlas_rollup",
			#"DistcpCubes",
                        "atlas_hhurl","atlas_topurl",
                        "MonthlyBytes","MonthlyBytes1",
			"BytesAgg",
			"BytesAgg_month","SubscriberSegment","SubscriberSegmentMPH",
                        "WeeklyBytes","TopSubcrWeekly","TopSubcrMerge",
                        "ConsistentSubcr"
                );

        my $c=1;
        # Using collector component count #
        while($c<=$count) {
                push(@dataSets,
                                "atlas_edrflow_$c",
                                "atlas_edrhttp_$c",
                                #"atlas_tcpfix_$c"
                                #"atlas_wng_$c"
                );
                $c++;
        }


        chomp @dataSets;

        foreach my $dataSet (@dataSets){
                push(@cmds, "pmx subshell oozie set dataset $dataSet attribute startTime $dataStartTime");
        }
        chomp @cmds;

        foreach my $job (keys %jobLagScheduleMinutes) {
                my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                if ($job=~/cleanup/i) {
                        my $time="00".":"."00"."Z";
                        $jobSchedule=~s/(\d{4,4}\-\d{2,2}\-\d{2,2}T)\d{2,2}\:\d{2,2}Z/$1$time/;
                }
                push(@cmds, "pmx subshell oozie set job $job attribute jobStart $jobSchedule",
                #           "pmx subshell oozie set job $job attribute jobEnd $jobEnd"
                        );

        }

        foreach my $job (keys %jobLagScheduleMonths) {
                my $jobDataMM=$dataMM+$jobLagScheduleMonths{$job}{Months};
                my $jobDataYY=$dataYY;
                if ($jobDataMM>12) {
                        $jobDataMM=sprintf("%02d",$jobDataMM-12);
                        print "jobDataMM=$jobDataMM\n";
                        $jobDataYY=$jobDataYY+1;
                }
                my $jobDataDD="01";
                my $jobDatahh="00";
                my $jobDatamm="00";
                my $jobSchedule="$jobDataYY\-$jobDataMM\-$jobDataDD"."T"."$jobDatahh".":"."$jobDatamm"."Z";
                push(@cmds, "pmx subshell oozie set job $job attribute jobStart $jobSchedule",
                #           "pmx subshell oozie set job $job attribute jobEnd $jobEnd"
                );
                # StartTime for Datasets as input to Monthly jobs need to be set at 00:00Hrs on same day as of other datasets.
                my $jobLagMonths=$jobLagScheduleMonths{$job}{dataSets};
                foreach my $dataSet (@$jobLagMonths){
                        my $dataSethh="00";
                        my $dataSetmm="00";
                        my $dataSetStartTime="$dataYY\-$dataMM\-$dataDD"."T"."$dataSethh".":"."$dataSetmm"."Z";
                        push(@cmds,"pmx subshell oozie set dataset $dataSet attribute startTime $dataSetStartTime");
                }

        }

        chomp @cmds;
        return \@cmds;

}



sub Atlas20_AggregationCentre {
		
	print "\nOops..! Development In Progress...\n";
        return undef;
}

sub Atlas20_ProvisionDistributionCentreOnAC {
	my $self=shift;
        my $src=shift;
	chomp $src;
        my $cred=shift;                                         # Receiving reference to the properties file #
	#my Cubes_"."$src="Cubes_"."$src";
        my @cmds=();
	push (@cmds,
			"pmx subshell oozie set job CubeExporter action ExporterAction attribute srcDatasets Cubes_"."$src",
			"pmx subshell oozie add dataset Cubes_"."$src",
			"pmx subshell oozie set dataset Cubes_"."$src attribute startOffset 0",
			"pmx subshell oozie set dataset Cubes_"."$src attribute frequency 60",
			"pmx subshell oozie set dataset Cubes_"."$src attribute endOffset 0",
			"pmx subshell oozie set dataset Cubes_"."$src attribute doneFile _DONE",
			"pmx subshell oozie set dataset Cubes_"."$src attribute outputOffset 0",
			"pmx subshell oozie set dataset Cubes_"."$src attribute path /data/output/Cubes/$src/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset Cubes_"."$src attribute pathType hdfs",
			"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute inputDatasets SubcrBytes_"."$src",
		);

	push (@cmds,
			"pmx subshell oozie add dataset SubcrBytes_"."$src",
			"pmx subshell oozie set dataset SubcrBytes_"."$src attribute startOffset 0",
			"pmx subshell oozie set dataset SubcrBytes_"."$src attribute frequency 1",
			"pmx subshell oozie set dataset SubcrBytes_"."$src attribute frequencyUnit month",
			"pmx subshell oozie set dataset SubcrBytes_"."$src attribute endOffset 0",
			"pmx subshell oozie set dataset SubcrBytes_"."$src attribute doneFile _DONE",
			"pmx subshell oozie set dataset SubcrBytes_"."$src attribute outputOffset 0",
			"pmx subshell oozie set dataset SubcrBytes_"."$src attribute path /data/output/MonthlyBytes/$src/%Y/%M",
			"pmx subshell oozie set dataset SubcrBytes_"."$src attribute pathType hdfs",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets Cubes_$src",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets SubcrBytes_"."$src"
			
		);

	
	chomp @cmds;
	return \@cmds;	

}

sub Atlas21_ProvisionDistributionCentre4SAP {
	my $self=shift;
        my $SAP=shift;
        chomp $SAP;
        my $cred=shift;                                         # Receiving reference to the properties file #
        my @cmds=();
	print "SAP name :$SAP, CRED REF: $cred\n";
        push (@cmds,
			"pmx subshell oozie add dataset srcIpfixRecords",
			"pmx subshell oozie set dataset srcIpfixRecords attribute startOffset 0",
			"pmx subshell oozie set dataset srcIpfixRecords attribute frequency 5",
			"pmx subshell oozie set dataset srcIpfixRecords attribute endOffset 0",
			"pmx subshell oozie set dataset srcIpfixRecords attribute doneFile _DONE",
			"pmx subshell oozie set dataset srcIpfixRecords attribute outputOffset 0",
			"pmx subshell oozie set dataset srcIpfixRecords attribute path /data/collector/1/output/ipfix/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset srcIpfixRecords attribute startTime 2012-06-01T00:00Z",
			"pmx subshell oozie set dataset srcIpfixRecords attribute pathType hdfs",
			"pmx subshell oozie add dataset destIpfixRecords",
			"pmx subshell oozie set dataset destIpfixRecords attribute startOffset 0",
			"pmx subshell oozie set dataset destIpfixRecords attribute frequency 5",
			"pmx subshell oozie set dataset destIpfixRecords attribute endOffset 0",
			"pmx subshell oozie set dataset destIpfixRecords attribute doneFile _DONE",
			"pmx subshell oozie set dataset destIpfixRecords attribute outputOffset 0",
			"pmx subshell oozie set dataset destIpfixRecords attribute path /data/$$cred{collector}{DCName}/ipfix/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset destIpfixRecords attribute startTime 2012-05-19T18:00Z",
			"pmx subshell oozie set dataset destIpfixRecords attribute pathType hdfs",
			"pmx subshell oozie add job Ipfixcp DistcpJob /opt/etc/oozie/Distcp",
			"pmx subshell oozie set job Ipfixcp attribute jobEnd 2099-03-21T05:00Z",
			"pmx subshell oozie set job Ipfixcp attribute jobFrequency 5",
			"pmx subshell oozie set job Ipfixcp attribute jobStart 2012-03-21T05:59Z",
			"pmx subshell oozie set job Ipfixcp action DistcpAction attribute destDataset destIpfixRecords",
			"pmx subshell oozie set job Ipfixcp action DistcpAction attribute destNamenode $SAP",
			"pmx subshell oozie set job Ipfixcp action DistcpAction attribute retryCount 5",
			"pmx subshell oozie set job Ipfixcp action DistcpAction attribute timeout -1",
			"pmx subshell oozie set job Ipfixcp action DistcpAction attribute srcNamenode $$cred{oozie}{namenode}{hostname}",
			"pmx subshell oozie set job Ipfixcp action DistcpAction attribute srcDataset srcIpfixRecords",
			"pmx subshell oozie set job Ipfixcp action DistcpAction attribute retrySleep 60",
			"pmx subshell oozie set job Ipfixcp action DistcpAction attribute flags -overwrite",
			"pmx subshell oozie add dataset srcSubscriberIB",
			"pmx subshell oozie set dataset srcSubscriberIB attribute startOffset 0",
			"pmx subshell oozie set dataset srcSubscriberIB attribute frequency 60",
			"pmx subshell oozie set dataset srcSubscriberIB attribute endOffset 0",
			"pmx subshell oozie set dataset srcSubscriberIB attribute doneFile _DONE",
			"pmx subshell oozie set dataset srcSubscriberIB attribute outputOffset 0",
			"pmx subshell oozie set dataset srcSubscriberIB attribute path /data/output/SubscriberIB/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset srcSubscriberIB attribute startTime 2012-05-19T18:00Z",
			"pmx subshell oozie set dataset srcSubscriberIB attribute pathType hdfs",
			"pmx subshell oozie add dataset destSubscriberIB",
			"pmx subshell oozie set dataset destSubscriberIB attribute startOffset 0",
                        "pmx subshell oozie set dataset destSubscriberIB attribute frequency 60",
                        "pmx subshell oozie set dataset destSubscriberIB attribute endOffset 0",
                        "pmx subshell oozie set dataset destSubscriberIB attribute doneFile _DONE",
                        "pmx subshell oozie set dataset destSubscriberIB attribute outputOffset 0",
                        "pmx subshell oozie set dataset destSubscriberIB attribute path /data/$$cred{collector}{DCName}/SubscriberIB/%Y/%M/%D/%H/",
                        "pmx subshell oozie set dataset destSubscriberIB attribute startTime 2012-05-19T18:00Z",
                        "pmx subshell oozie set dataset destSubscriberIB attribute pathType hdfs",
                        "pmx subshell oozie add job SubscriberIBcp DistcpJob /opt/etc/oozie/Distcp",
                        "pmx subshell oozie set job SubscriberIBcp attribute jobEnd 2099-03-21T05:00Z",
                        "pmx subshell oozie set job SubscriberIBcp attribute jobFrequency 60",
                        "pmx subshell oozie set job SubscriberIBcp attribute jobStart 2012-03-21T05:59Z",
                        "pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute destDataset destSubscriberIB",
                        "pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute destNamenode $SAP",
                        "pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute retryCount 5",
                        "pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute timeout -1",
                        "pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute srcNamenode $$cred{oozie}{namenode}{hostname}",
                        "pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute srcDataset srcSubscriberIB",
                        "pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute retrySleep 60",
                        "pmx subshell oozie set job SubscriberIBcp action DistcpAction attribute flags -overwrite",
                );

        chomp @cmds;
        return \@cmds;

}




sub Atlas21MIDM_MIDM {

        my $self=shift;
        my $dataStartTime=shift;
        #my $jobEnd=shift;
        my $cred=shift;                                         # Receiving reference to the properties file #
        my @cmds=();
        my %jobLagScheduleMinutes=(
                                MidmEnr		        =>      ,
                                MidmData                =>      60*24,
				CleanupMidmCubes	=>	
                        );
        my %jobLagScheduleMonths=(
                                        #SubscriberBytes =>      {Months         =>      1,
                                        #                        dataSets       =>      ["BytesAgg_month"]}
                                 );

        my @dataSets = (
                        "midm_subib",
                        "midm_wngibcp",
                        "midm_ipfix",
                        "midm_out",
			"midm_enr_local",
			"midm_enr_final",
			"midm_agg_final",
			"midm_agg_local",
			"",
                );

        chomp @dataSets;

        foreach my $dataSet (@dataSets){
		


	}




}



sub Atlas21PNSA_PNSA {

	my $self=shift;
        my $dataStartTime=shift;
        #my $jobEnd=shift;
        my $cred=shift;                                         # Receiving reference to the properties file #
        my $count=$$cred{oozie}{collector}{component}{count};   # Collector component count #
        my ($dataYY,$dataMM,$dataDD,$datahh,$datamm);
        if ($dataStartTime=~(/(\d{4,4})+\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/)) {
                $dataYY=sprintf("%04d",$1);
                $dataMM=sprintf("%02d",$2);
                $dataDD=sprintf("%02d",$3);
                $datahh=sprintf("%02d",$4);
                $datamm=sprintf("%02d",$5);
        }
        my @cmds=();
        my %jobLagScheduleMinutes=(
                                PnsaSubscriberIb        =>      60,
                                Ipfixcp                 =>      60,
                                SubscriberIBcp          =>      60
                        );
        my %jobLagScheduleMonths=(
                                        #SubscriberBytes =>      {Months         =>      1,
                                        #                        dataSets       =>      ["BytesAgg_month"]}
                                 );
        my @dataSets = (
                        "pnsa_ipportcleanup",
                        "pnsa_subib",
			"pnsa_radius",
			"srcIpfixRecords",
			"destIpfixRecords",
			"srcSubscriberIB",
			"destSubscriberIB",
			# PNSA "pnsa_selfipcleanup" has the startTime as dataStartTime+1 hour
			"pnsa_selfipcleanup"
                );

        chomp @dataSets;

        foreach my $dataSet (@dataSets){
		if ($dataSet=~/pnsa_selfipcleanup/i) {
			my $dataStartPlusOne=_dataStartToJobStart($dataStartTime, 60);
			push(@cmds, "pmx subshell oozie set dataset $dataSet attribute startTime $dataStartPlusOne");
			next;
		}
                push(@cmds, "pmx subshell oozie set dataset $dataSet attribute startTime $dataStartTime");
        }
        chomp @cmds;

        foreach my $job (keys %jobLagScheduleMinutes) {
                my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                push(@cmds, "pmx subshell oozie set job $job attribute jobStart $jobSchedule");

        }


        chomp @cmds;
        return \@cmds;

}


sub Atlas22PNSA_PNSA {

        my $self=shift;
        my $dataStartTime=shift;
        #my $jobEnd=shift;
        my $cred=shift;                                         # Receiving reference to the properties file #
        my $count=$$cred{oozie}{collector}{component}{count};   # Collector component count #
        my ($dataYY,$dataMM,$dataDD,$datahh,$datamm);
        if ($dataStartTime=~(/(\d{4,4})+\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/)) {
                $dataYY=sprintf("%04d",$1);
                $dataMM=sprintf("%02d",$2);
                $dataDD=sprintf("%02d",$3);
                $datahh=sprintf("%02d",$4);
                $datamm=sprintf("%02d",$5);
        }
        my @cmds=();
        my %jobLagScheduleMinutes=(
                                PnsaSubscriberIb        =>      60,
				#Ipfixcp			=>	60,
                                Ipfixcp1                =>      15,
				Ipfixcp2		=>      20,
				Ipfixcp3		=>	25,
                                SubscriberIBcp          =>      60,
				Radiuscp		=>	60,
				CleanupCollector	=>	60,
				CleanupSubIb		=>	60,
				CleanupLogs		=>	60
                        );
        my %jobLagScheduleMonths=(
                                        #SubscriberBytes =>      {Months         =>      1,
                                        #                        dataSets       =>      ["BytesAgg_month"]}
                                 );
        my @dataSets = (
                        #"pnsa_ipportcleanup",
                        #"pnsa_subib",
                        #"pnsa_radius",
                        #"srcIpfixRecords",
                        #"destIpfixRecords",
                        #"srcSubscriberIB",
                        #"destSubscriberIB",
			#"srcRadiusRecords",
			#"destRadiusRecords",
                        # PNSA "pnsa_selfipcleanup" has the startTime as dataStartTime+1 hour
                        "pnsa_selfipcleanup"
                );

        chomp @dataSets;

        foreach my $dataSet (@dataSets){
                if ($dataSet=~/pnsa_selfipcleanup/i) {
                        my $dataStartPlusOne=_dataStartToJobStart($dataStartTime, 60);
                        push(@cmds, "pmx subshell oozie set dataset $dataSet attribute startTime $dataStartPlusOne");
                        next;
                }
                push(@cmds, "pmx subshell oozie set dataset $dataSet attribute startTime $dataStartTime");
        }
        chomp @cmds;

        foreach my $job (sort keys %jobLagScheduleMinutes) {
                my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                push(@cmds, "pmx subshell oozie set job $job attribute jobStart $jobSchedule");

        }


        chomp @cmds;
        return \@cmds;

}





######################## Helper Subroutines ########################
sub _dataStartToJobStart {

	my ($dataStartTime, $lagMinutes) = @_;
        $dataStartTime =~ s/Z$//;
        my ($date, $time) = split "T", $dataStartTime;
        my ($yy, $MM, $dd) = split "-", $date;
        my ($hh, $mm) = split ":", $time;
	$MM=$MM-1;	
	$MM=11 && $yy=$yy-1 if $MM<0;
        my $dataStartEpoch = timelocal(0,$mm,$hh,$dd,$MM,$yy);
        my $newEpoch = $dataStartEpoch + $lagMinutes*60;
        my ($wday,$yday,$isdst, $sec);
	my $test=localtime($newEpoch);
        ($sec,$mm,$hh,$dd,$MM,$yy,$wday,$yday,$isdst) = localtime($newEpoch);
	$MM=$MM+1;
        $MM = sprintf("%02d", $MM);
        $dd = sprintf("%02d", $dd);
        $mm = sprintf("%02d", $mm);
        $hh = sprintf("%02d", $hh);
	my $startTime=(1900+$yy)."-".$MM."-".$dd."T".$hh.":".$mm."Z";
        return $startTime;
}


1;

