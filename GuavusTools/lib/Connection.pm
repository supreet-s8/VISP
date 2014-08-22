package Connection;
use lib './';
use strict;
use Expect;
my $SSHPATH=`which ssh`;
chomp $SSHPATH;
use vars qw($ssn $args);

use Log::Log4perl;
Log::Log4perl->init("../etc/log.conf");
my $log = Log::Log4perl->get_logger("Connection");

sub new
{
	my $class=shift;
	$args=shift;
	my $self={};
	bless $self, $class;
	return $self;

}


#												#
# 	Returns the Expect object when connected successfully or Undef when unsuccessful.	#
#												#

sub conn 
{
	my $self = shift;
	my $prompt=shift;
	my $STDOUT=shift;
	my $cmd = "$SSHPATH $args->{User}\@$args->{IP}";
	my $timeout = 45;
	$ssn = new Expect();	
	$ssn->raw_pty(1);
	$ssn->log_stdout($STDOUT);
	$ssn->max_accum(50000);
	eval 
	{
		$ssn->spawn("$cmd");	
	};
	if($@)
	{
		$log->error("Error spawning ssh command, $@");
	}
	#$ssn->log_file("/tmp/expectLog");
	my $no_attempts=1;
	while (ref($ssn) ne "Expect")
        {	if ( $no_attempts >= 3 )
		{ Log("Not able to connect to host $args->{IP}"); $ssn->close(); exit 2; }
          	sleep 1;
          	$ssn=Expect->spawn("$cmd");
          	$no_attempts++;
        }
	my $res=undef;
	$ssn->restart_timeout_upon_receive(1); 
        $ssn->expect($timeout,
                [ qr/Are you sure you want to continue connecting (yes\/no)?/, sub { $ssn->send("yes\n"); exp_continue; } ],
                [ qr/password:/i, sub {$ssn->send("$args->{Password}\n"); exp_continue; } ],
                [ qr/.*\>\s*/ , sub { $ssn->send("en\n"); $ssn->send("configure terminal\n"); exp_continue; }],
		#[ qr/.+\s+\(config\)\s+#/, sub {$ssn->send("\n"); $res=1; }],
		[ qr/.+\s+\(config\)\s+#/, sub {$ssn->send("license install LK2-RESTRICTED_CMDS-88A4-FNLG-XCAU-U\n"); if($prompt eq 'shell'){$ssn->send("_shell\n")};$res=1; }],
                [ qr/Enter \'YES\' to enter configuration mode anyway:/, sub { $ssn->send("YES\n"); $res=1;exp_continue; }] 
		);
		
	my $grep=$ssn->expect(1,"-re",qr/.+\s+\(config\)\s+#/);
	$grep=$ssn->expect(1,"-re",qr/\[.+\@.+\~\]#/);
	if (defined $res)
	{	
		return $ssn;	
	} 
	else 
	{
		return undef;
	}
	
}


#											#
# 	Returns 1, for restored configuration or undef in the event unsuccessful.	#
#											#

sub restore 
{
	my $self = shift;
	$ssn->send("\n\n");
	my $prompt=$ssn->expect (1, "-re",".+config.+#");
	if ($self->{backupexists} && $prompt) {
		
		$ssn->send("configuration switch-to STATEBEFORECMC\n\n");
		$prompt=$ssn->expect (5, "-re",".+config.+#");
		sleep (5);
		if ($prompt) {
			$ssn->send("show configuration files\n");
			my $validate=$ssn->expect(5,"-re", "STATEBEFORECMC.+active.+");
			print "CONFIGURATION RESTORED\n" if ($validate);
			return 1;
		} else {
			return undef;
		}
			
	} else {
		print "NO Backup Configuration Exists or NO Prompt\n";
		return undef;
	}
	

}
1;
