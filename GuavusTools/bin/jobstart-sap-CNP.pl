#!/usr/bin/perl 

use Carp;
use Getopt::Long;
use Time::Local;

###########################################################################################
# Setup options

#my $node=undef;
#my $nextHour=undef;		# N/A for SAP
#my $previousHour=undef;	# N/A for SAP
my $resume=undef;
my $execute=undef;
my $help=undef;
my $dataStartTime=undef;
my $output=GetOptions( 
                        #"node:s"                =>      \$node,
			#"nextHour"		 =>	 \$nextHour,
			#"previousHour"		 =>	 \$previousHour,
			"resume"		 =>	 \$resume,
			"execute"		 =>	 \$execute,
                        "setTime:s"         	 =>      \$dataStartTime,
                        "help"                   =>      \$help);



#========================#
# SAP NAMENODE JOBS
#========================#
our %jobLagScheduleMinutes=(
	ArcSight			=> 60*2,
	CleanupLogs			=> 60*24,
	CleanupMidmCubes		=> 60*24,
	CleanupRaw			=> 60*24,
	MidmDataTransferTime		=> 60*24,
	MidmData_Azusa			=> 60*24,
	MidmData_Branchburg		=> 60*24,
	MidmData_Charlotte		=> 60*24,
	MidmData_HickoryHills		=> 60*24,
	MidmData_Marina			=> 60*24,
	MidmData_Nashville		=> 60*24,
	MidmData_NewBerlin		=> 60*24,
	MidmData_Ontario		=> 60*24,
	MidmData_Vista			=> 60*24,
	MidmData_Wall			=> 60*24,
	MidmEnr_Azusa			=> 60*24,
	MidmEnr_Branchburg		=> 60*24,
	MidmEnr_Charlotte		=> 60*24,
	MidmEnr_HickoryHills		=> 60*24,
	MidmEnr_Marina			=> 60*24,
	MidmEnr_Nashville		=> 60*24,
	MidmEnr_NewBerlin		=> 60*24,
	MidmEnr_Ontario			=> 60*24,
	MidmEnr_Vista			=> 60*24,
	MidmEnr_Wall			=> 60*24,
	MidmInclusionListWait		=> 60*24,
	MidmProcessTime			=> 60*24,
	SubscriberIBToQEJob_Azusa	=> 60,
	SubscriberIBToQEJob_Branchburg	=> 60,
	SubscriberIBToQEJob_Charlotte	=> 60,
	SubscriberIBToQEJob_HickoryHills=> 60,
	SubscriberIBToQEJob_Marina	=> 60,
	SubscriberIBToQEJob_Nashville	=> 60,
	SubscriberIBToQEJob_NewBerlin	=> 60,
	SubscriberIBToQEJob_Ontario	=> 60,
	SubscriberIBToQEJob_Vista	=> 60,
	SubscriberIBToQEJob_Wall	=> 60,
             );
#========================#


if ((! $output) or ($help)) {
        &usage;
        exit;
}

sub usage {
        print <<EOF

Usage:

Provide in the following options.



--resume		   	=> No input required with this option. Option consults done.txt

--execute		   	=> Lets you execute the commands on both Master and Standby Nodes.

--setTime	                => Provide the Data Start Time (Format: 2013-02-28T15:00Z). Respective oozie jobs will get
                                   scheduled taking this as a base time.


EOF

}
#--node		(Mandatory)	 => Provide IP address of the Master/Standby namenode.
#--nextHour                      => No input required with this option. 
#--previousHour                  => No input required with this option. 

####################################### MAIN ################################################

my $cmds=undef;

if(! ($nextHour || $previousHour || $resume || $dataStartTime)){
        &usage();
        exit;

}

if($dataStartTime && ($nextHour || $previousHour || $resume)) {
	&usage();
	exit;
}

if(($nextHour && $previousHour) || ($previousHour && $resume) || ($resume && $nextHour)) {
        &usage();
        exit;
}


#&usage() if (! $node);

#die "\nError: Invalid node IP address.\n\n" if (! is_valid($node));

if($nextHour) {
$dataStartTime=`date -d "1 hour" +%Y-%m-%dT%H:00Z`;

} elsif ($previousHour) {
$dataStartTime=`date -d "1 hour ago" +%Y-%m-%dT%H:00Z`;

} elsif ($resume) {
# Consult done.txt and Execute #

my $cmds=&consult_done();
	if (! ref $cmds){
		print "\nError...!\nCould not stat done.txt for base value of Job: $cmds.\n\n";
		print "Use any of the other options to configure jobStart times.\n\n";
		exit;
	}

print "\nCommands list to be issued on node:\n\n";
print "$_\n" foreach(@$cmds);


	# CALL EXECUTE #
	if ($execute) {
	my $state=execute($cmds,$node);
		if (! $state) {
			die "Can not complete execution...! Error: 911\n\n";
		}
	} else {
		print "\nINFO: Use \"--execute\" flag to run these commands on both Master and Standby name nodes.\n";
	}
	###

print "\nProcess completed.\n\n";
exit;

} 

# Compute Fresh and Execute #

if($dataStartTime) {
die "Not a valid time format! Please try again.\n" if (! &isValidTime($dataStartTime));

print "\nGenerating Oozie job times...\n";
$cmds=&jobstart_pnsa($dataStartTime);

print "\nCommands list to be issued on node:\n\n";
print "$_\n" foreach(@$cmds);

        # CALL EXECUTE #
        if ($execute) {
        my $state=execute($cmds,$node);
                if (! $state) {
                        die "Can not complete execution...! Error: 911\n\n";
                }
        } else {
                print "\nINFO: Use \"--execute\" flag to run these commands on both Master and Standby name nodes.\n";
        }
        ###

print "\nProcess completed.\n\n";
} else {
	print "Could not stat Data Start Time. Exception!\n Committing Exit...! Error:007!\n";
}





####################################### Subroutines #######################################

sub jobstart_pnsa {

        my $dataStartTime=shift;
        my ($dataYY,$dataMM,$dataDD,$datahh,$datamm);
        if ($dataStartTime=~(/^(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/)) {
                $dataYY=sprintf("%04d",$1);
                $dataMM=sprintf("%02d",$2);
                $dataDD=sprintf("%02d",$3);
                $datahh=sprintf("%02d",$4);
                $datamm=sprintf("%02d",$5);
		
        }
        my @cmds=();

        foreach my $job (sort keys %jobLagScheduleMinutes) {
		chomp $job;
		if (($job=~/^Midm.+$/i)) { #|| ($job=~/^MidmData\_.+$/i)) {
		my $dataStartTime1="$dataYY\-$dataMM\-$dataDD"."T03\:00Z";
		my $jobSchedule=_dataStartToJobStart($dataStartTime1, $jobLagScheduleMinutes{$job});
                push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set job $job attribute jobStart $jobSchedule");
		} else {
                my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set job $job attribute jobStart $jobSchedule");
		}

        }


        chomp @cmds;
        return \@cmds;

}


sub consult_done {
	my $hadoop=undef;
	my @cmds =();
	$hadoop=`which hadoop`;
	chomp $hadoop;
	print "Can not consult done.txt files for Jobs.\nHadoop not available on this system! Cheating!" if (! defined $hadoop);
	print "Consulting done.txt for all jobs.\n";
	foreach my $job (sort keys %jobLagScheduleMinutes) {
		my $dataStartTime=`$hadoop dfs -cat /data/$job/done.txt 2>/dev/null`;
		chomp $dataStartTime;
		
		#print "Time for Job: $job is $dataStartTime\n";
		return $job if(!defined $dataStartTime);    # Return JOBNAME if any job does not has done.txt 

 		# Return JOBNAME if any job has bad/incomplete or missing time format in done.txt
		return $job if($dataStartTime!~(/^(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/));

                my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set job $job attribute jobStart $jobSchedule");

        }
	chomp @cmds;
	return \@cmds;

}

sub execute {
	my $cmds=shift;
	my $IP=get_ips();
	if (! $IP) {
		print "Committing Exit...!\n";
		exit;
	}
	my $cmd=undef;
	$cmd.="$_\n" foreach(@$cmds);
	chomp $cmd;
	foreach my $ip (@$IP) {
		chomp $ip;
		print "\nExecuting...\t At $ip.\n";
		my $out=`ssh -q root\@$ip "$cmd"`;
		if ($out=~/invalid command/i) {
			print "\nInvalid command error.\nAborting Process...!\n";
			print "\nOUTPUT:\n"."x"x50;
			print "\n";
			print "$out\n";
			print "x"x50;
			print "\n\n";
			return undef;
			
		}
		return undef if ($? != 0);
		print "\n";
	}
	return 1;
}

sub get_ips {
	my $master=undef;
	my $standby=undef;
	$master=`/opt/tms/bin/cli -t "en" "conf t" "show cluster global brief" | grep master`; 
	chomp $master;
	#3*    master   online    GUA21NSA-A-GV-HP 0.0.0.0         192.168.10.20  
	$master=~/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$/;
	$master=$1;
	$standby=`/opt/tms/bin/cli -t "en" "conf t" "show cluster global brief" | grep standby`;
	chomp $standby;
	$standby=~/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$/;
	$standby=$1;
	if (!($master && $standby)) {

		print "Error: Can not determine cluster Master and Standby IPs.\n";
		return undef;

	}
	my @ip=();
	push (@ip, $master, $standby);
	return \@ip;

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
	my $newEpoch = undef;
        $newEpoch = ($dataStartEpoch + ($lagMinutes*60));
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

sub isValidTime {
        my $startTime=shift;
        return $startTime if ($startTime=~/^(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/);
        return undef;
}

sub is_valid {
        my $IP=shift;
        chomp $IP;
        $IP=~s/\s+//g;
        return 1 if(($IP=~/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) && ($1<=255) && ($2<=255) && ($3<=255) && ($4<=255));
        return undef;
}

