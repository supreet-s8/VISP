############################################# Package BuildHosts #################################################################
# Date				:	20 April, 2012
#
# Build_MultiHost($arr_ref)	:	Takes an array of references to the hashes containing server(TallMaple) information.
#                                       Hash has the following keys (IP, User, Password, ConfigFile), and builds (applies confi
#                                       -guration) the servers. Essentially, it calls Build_Host method for each host sequentially.
# Build_MultiHost_Threaded($arr_ref) : 	Takes an array of references to the hashes containing server(TallMaple) information.
#					Hash has the following keys (IP, User, Password, ConfigFile), and builds (applies confi
#					-guration) the servers. Essentially, it forks threads of Build_Host method for each host.
# Build_Host($hash_ref)		:	Takes a reference to a hash containing server(TallMaple) information, similar as above.
# GetCurrentState		:	(For internal use) Takes the expect handle object to determine the current shell state
#					by seeing the command prompt.
# GetThisState			:	(For internal use, partially implemented) Takes expect object, expected state, and last
#					last executed command, and tries to get the expected state by handling the current
#					inconsistent state
# HandleError			:	(For internal use) Parse the expect output taken as argument for any known errors and 
#					logs them to a logger
# Run				: 	(For internal use) Actually runs the command
###################################################################################################################################

package BuildHosts;
	
use Log::Log4perl;
Log::Log4perl->init("../etc/log.conf");
use Connection;
use Carp;
use Switch;
use threads;
%cmd_level = (
		"enable" => 1,
		"configure terminal" => 2,
		"pmx" => 3,
	);
my @ErrorList = map { qr{$_} } ('% Unrecognized command', 'Invalid command:', 'Did not understand:','% Duplicate','% Invalid','% Incomplete command','Cannot open:');
my @BadCommands = ('quit' , 'exit', 'ntpdate');
$MAX_RETRIES = 6;
$TIMEOUT = 60;
$errorCode = 0;
$DefaultParamsFile = "../etc/system.defaults";
open SD, "<$DefaultParamsFile" or carp "Unable to open Default params file :$DefaultParamsFile";
$WaitOnHang = 10;
while (<SD>)
{
 	my $tmp;
	chomp;
        next if m/^$/ or m/^#/;
       	($tmp,$WaitOnHang) = split(/=/, $_) if m/WaitOnHang/i;
}

my $log = Log::Log4perl->get_logger("BuildHosts");
my $date_time = `date`;
$log->debug("Execution Started : $date_time");

sub new
{
        my $class=shift;
        my $self={};
        bless $self, $class;
        return $self;
}

sub GetCurrentState
{
	my $exp = shift;
	my $cur_state = ();
	$log->error("Expect object not defined , $!") unless defined $exp;
	$exp->clear_accum();

	eval {
	$exp->send("\n");
	my @out=$exp->expect($TIMEOUT,
		[ qr/\(press RETURN\)/, sub { $exp->send("q\n"); $errorCode = 1; $cur_state = undef; } ],
		[ qr/Press RETURN for more, or q when done/, sub { $exp->send("q\n"); $errorCode = 1; $cur_state = undef; } ],
		[ qr/.+\(END\)/, sub { $exp->send("q\n"); $errorCode = 1; $cur_state = undef;  } ],
		[ qr/.+\s+\(config\)\s+#/, sub { $errorCode=0; $cur_state->{level} = 2; $cur_state->{name} = "configure terminal"; } ],
                [ qr/.+\s+>/, sub { $cur_state->{level} = 0; $cur_state->{name} = "normal"; } ],
		[ qr/.+\s+#/, sub { $cur_state->{level} = 1; $cur_state->{name} = "enable"; } ],
		[ qr/pm extension>/, sub { $errorCode=0; $cur_state->{level} = 3; $cur_state->{name} = "pmx";  } ],
		[ qr/pm extension\s+\((.+)\)>/, 
			sub { 
				$tmp = $exp->match() or $log->error("match() failed on expect object exp = $exp, $!");; 
				$tmp =~ s/pm\s+extension\s+\((.+)\)>/$1/; 
				$tmp =~ s/\s+/_/; 
				$cur_state->{level} = 4; $cur_state->{name} = $tmp; 
			} ],
		[ qr/\[admin\@.+\]#/, sub { $cur_state->{level} = -1; $cur_state->{name} = "shell"; } ]
		);
	};
	if($@)
	{
		$log->error("Caught exception in GetCurrentState, $@");
	}
	#$exp->clear_accum();
	return $cur_state;
}

sub GetThisState
{
	$log->info("Inside GetThisState....");
	my ($exp, $state, $cmd) = @_;
	eval {
	$exp->expect( $TIMEOUT,
	#	[ qr/\(END\)/, sub { $exp->send("q"); $exp->send("\n"); } ],
		[ qr/Press RETURN for more, or q when done/, sub { $exp->send("q"); $exp->send("\n"); $log->error("Got (Press RETURN for more, or q when done)....");} ],
        	);
	};
	if($@)
	{
		$log->error("Caught exception in GetThisState, $@");
	}
}

sub Run
{
	my ($exp, $cmd, $state) = @_;
	
	$log->debug("COMMAND: $cmd\tSTATE: $state->{name}\tLEVEL:$state->{level}");
	eval {
	$log->warn("Potentially Bad Command.") if (grep {$_ eq $cmd} @BadCommands);
	print "\"$cmd\"" if ($verbose==1);
	$exp->send($cmd);
#	$exp->send("\n");
	};
	if($@)
	{
		$log->error("Caught exception in run. INFO: $@");
	}
	return;
}

sub HandleErrors
{
	my $exp = shift;
	my $cmd = shift;
	my $buffer = $exp->before();
	$buffer=~s/\r//g;
	chomp $buffer;
	$log->debug($buffer);
	
	if ($errorCode == 1 && $cmd !~ m/pmx\s+register\s+.+/ && $cmd !~ m/^\s*register\s+.+/)
	{

		print "......FAILED\n" if ($verbose==1);
		$log->error("ERROR: COMMAND: $cmd\tSTATE:$cur_state->{name}LEVEL:$cur_state{level}");
                $log->error("OUTPUT: $buffer\n");
		print "------------------\n$buffer\n------------------\n";
		my $cur_state=GetCurrentState($exp);
		my $answer=&rollback();
		if ($answer=~/yes/) {
			while ($errorCode == 1 && $cur_state->{level} > 2) {
 			
			Run($exp, "quit", $cur_state);
			$exp->clear_accum();
 			sleep 3;
 			$cur_state = GetCurrentState($exp);
			$errorCode = 1;
 			
 			}
			
			while ($errorCode == 1 && $cur_state->{level}==-1) {

			Run($exp, "cli -m config", $cur_state);
                        $exp->clear_accum();
                        sleep 3;
                        $cur_state = GetCurrentState($exp);
                        $errorCode = 1;

                        }
		
		$log->error("Performing Roll Back...\n");
		Run($exp, "configuration revert saved\n", $cur_state);	
		$exp->send("configuration revert saved\n");
		$errorCode = 0;
		my $cur_state = GetCurrentState($exp);
		#$log->error("State after roll back : $cur_state->{level} , $cur_state->{name}");

			unless($cur_state->{level} == 2) {
			$log->error("Roll back failed.., cur_state->{level} = $cur_state->{level}");
			}

		return 0;
		}else {
                        my $answer=&continueConfig();
                        return 0 if ($answer=~/no/);
                        return 1 if ($answer=~/yes/);

                }

	}

	foreach my $errorList(@ErrorList)
	{
		if ($buffer =~ m/$errorList/) {

		my $cur_state=GetCurrentState($exp);
		$errorCode = 1;
		print "......FAILED\n" if ($verbose==1);
		$log->error("ERROR: COMMAND: $cmd\tSTATE:$cur_state->{name}LEVEL:$cur_state{level}");
                $log->error("OUTPUT: $buffer\n");
		print "------------------\n$buffer\n------------------\n";
		my $answer=&rollback();

                if ($answer=~/yes/) {
			while ($errorCode == 1 && $cur_state->{level} > 2) {

				Run($exp, "quit", $cur_state);
				#$exp->clear_accum();
                         	sleep 3;
                         	$cur_state = GetCurrentState($exp);
				$errorCode = 1;

                 	}
			
			while ($errorCode == 1 && $cur_state->{level}==-1) {

                        Run($exp, "cli -m config", $cur_state);
                        $exp->clear_accum();
                        sleep 3;
                        $cur_state = GetCurrentState($exp);
                        $errorCode = 1;

                        }

                	$log->error("Performing roll back...\n");
			Run($exp, "configuration revert saved", $cur_state);	
                	$errorCode = 0;
               		my $cur_state = GetCurrentState($exp);
                	unless($cur_state->{level} == 2)
                	{
                	        $log->error("Roll back failed.., cur_state->{level} = $cur_state->{level}");
               		}
                	return 0;
		} else {
			my $answer=&continueConfig();			
			return 0 if ($answer=~/no/);
			return 1 if ($answer=~/yes/);
			
		}

		}
		next;
		
	}

	$errorCode = 0;
	print "......OK\n" if ($verbose==1);
	return 1;
}

sub Build_MultiHost_Threaded
{
        my $self = shift;
	my $arr_ref = shift;
        my ($ret, @thread_array);
	my @arr = @$arr_ref;
	my $len = @arr;
	for (my $i=0; $i<$len; $i++)
        {
		$thread_array[$i] = threads->new(\&Build_Host, $dummy, $arr[$i]);
        }
	foreach (@thread_array)
	{
		$ret = $_->join;
                print "Build_Host thread:$_ returned $ret\n";
	}
}
sub Build_MultiHost
{
        my $self = shift;
        my $arr_ref = shift;
	my @arr = @$arr_ref;
	foreach (@arr)
	{
		$log->debug("Build Process for $_->{IP} started... \n");
		my $retval = $self->Build_Host($_);
		$log->debug("Build Process for $_->{IP} returned with $retval \n");
	}	
}

sub Build_Host
{
	my $self = shift;
	my $hashref = shift;
	my $cmd = undef;
	my $crnt_state=undef;
	our $verbose=$hashref->{Verbose};
	my $expected_state=undef;
	my $con = new Connection($hashref);
	print "\n\nLaunching connection with $hashref->{IP}\n\n"; 
	my $exp = $con->conn("config", $hashref->{STDOUT});
	if(!defined $exp)
	{
		$log->error("Unable to Login $hashref->{IP}");
		return 1;
	}
	#$exp->log_file("/tmp/expectLog-".$hashref->{IP});
	$exp->send("write memory\n");
	$expected_state->{level} = 2;
	$expected_state->{name} = "configure terminal";
	my $CmdListRef = $hashref->{CommandList};
	if(!defined $CmdListRef)
	{
		open CFG, "<$hashref->{ConfigFile}" or croak "$hashref->{ConfigFile} not found\n";
		@CmdList = <CFG>;
	}
	else
	{
		@CmdList = @$CmdListRef;
	}
	$crnt_state = GetCurrentState($exp);
	foreach (@CmdList)
	{
		next if m/^#/ or m/^$/;
		chomp;
		$cmd = $_;
		$cmd =~ s/^\s+//;
		$cmd =~ s/\s+$//;
		#$errorCode=0;
		my $retries = 0;
		$errorCode = 0;

		switch($cmd)
		{
			case "enable" { $expected_state->{level} = $cmd_level{"enable"}; $expected_state->{name} = "enable"; }
			case "configure terminal" { $expected_state->{level} = $cmd_level{"configure terminal"}; $expected_state->{name} = "configure terminal"; }
			case "pmx" { $expected_state->{level} = $cmd_level{"pmx"}; $expected_state->{name} = "pmx"; }
			case /^\s*subshell\s+(\w+)\s*$/ { $expected_state->{level} = 4; $tmp = $cmd; $tmp =~ s/subshell\s+//; $expected_state->{name} = $tmp; }
			case /(^\s*quit\s*$|^\s*exit\s*$)/ { 
				$expected_state->{level} = $cur_state->{level} - 1; 
				foreach (keys %cmd_level) { if ($cmd_level{$_} == $expected_state->{level}) { $expected_state->{name} = $_; } }
				}
			else { $expected_state->{name} = $crnt_state->{name}; $expected_state->{level} = $crnt_state->{level}; } 
		}

		Run($exp, $cmd, $crnt_state);
		$crnt_state = GetCurrentState($exp);


	        my $ret =  HandleErrors($exp, $cmd);
                last unless $ret;
	
		eval {
                while((! defined $crnt_state) or ($expected_state->{level} != $crnt_state->{level}) or ($expected_state->{name} ne $crnt_state->{name}))
                {
                        if ($retries++ < $MAX_RETRIES)
                        {
                                $log->debug("RETRYING: retry number = $retries");
                                $log->debug("STATE: EXPECTING: $expected_state->{name}\tPRESENT:$crnt_state->{name}");
                                $crnt_state = GetCurrentState($exp);
                        }
                        else
                        {
                                $log->error("ERROR: Reached MAX_RETRIES expecting $expected_state->{name} prompt. Present STATE: $crnt_state->{name}");
                                return 1;
                        }
                }
                };
                if($@)
                {
                        $log->error("Caught exception in the until loop : Build_Host, $@");
                }

	
        	#$log->debug("errorCode = $errorCode, cmd = $cmd, last cmd o/p = $exp->before()");
		#$log->debug("cmd = $cmd, $expected_state->{name}, $crnt_state->{name}, $expected_state->{level}, $crnt_state->{level}");

		
	
	}
	if($errorCode == 0 && $expected_state->{level}==2)
	{
		sleep 1;
		Run($exp, "write memory", $crnt_state);
		$crnt_state = GetCurrentState($exp);
		my $ret =  HandleErrors($exp, $cmd);
                #if ($ret==1) {
		#print "......OK\n";
		#} else {
		#print "......FAILED\n";
		#}	
	}
	$exp->close();
	return $errorCode;
}


sub rollback {
	my $ans="no";
	sleep 3;
	print "\n\nNote: All configuration will be lost on rollback.\n";
	do {
		print "\nDo you want to perform rollback to the last saved configuration?(yes/no) [no]:";
		my $ans=<>;
		chomp $ans;
		$ans="no" if ($ans eq "");
		$answer=$ans;
	} while ($answer!~/yes/ && $answer!~/no/);
	
	return $answer;
}

sub continueConfig {
        my $ans="no";
        sleep 3;
       
        do {
                print "\nDo you want to continue with remaining configuration?(yes/no) [no]:";
                my $ans=<>;
                chomp $ans;
                $ans="no" if ($ans eq "");
                $answer=$ans;
        } while ($answer!~/yes/ && $answer!~/no/);

        return $answer;
}
1;
