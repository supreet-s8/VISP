package Parse;
use strict;
use lib "../lib";
use Carp;

###########################################################################################################################

my %commandsOrder=(
			1	=>	"interface",
			2	=>	"ip",
			3	=>	"user",
			4	=>	"ntp",
			5	=>	"snmp",
			6	=>	"collector",
			7	=>	"hadoop",
			8	=>	"oozie",
			9	=>	"drbd",
			10	=>	"sm",
			11	=>	"ssh",
			12	=>	"cluster"
		);


# Provide in the Output file to be generated and a hash of properties. Returns the name of generated file as supplied to it.

sub generate_cli {

	my $outfile=shift;
	my $tree=shift;
	my $verbose=shift;
	my @cmds=();
	my @dcmd=();
	$verbose=0 if (! defined $verbose);

	if ($outfile=~/(\d+\.\d+\.\d+\.\d+)\.cli$/) {

		my $IP=$1;

		if(! ($IP=~/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) && ($1<=255) && ($2<=255) && ($3<=255) && ($4<=255)){	
			print "WARN: Not a valid IP in the name of CLI file \"$outfile\"\n";
			return undef;
		}
	} else {
		
		print "WARN: Not a properties file format \"$outfile\"\n"; 
		return undef;
	}

	if (! ref($tree)) {
		print "WARN: Reference to a properties hash not found.\n";
		return undef;
	}


	my $version=$tree->{version};
        $version=~s/[\.\s*]//g;
	
	

	my $build=$tree->{build};
        my $require="$build"."$version";

	$require="$build"."$version";           # $require must stand global to this package.
        # Loading specified module #
        eval "require product::$require" or die "Did not find project \"$$tree{build}"."$$tree{version}\" in library.";

	foreach my $index (sort{$a <=> $b} keys %commandsOrder) {		# Refer ordering 
		next if (!defined $$tree{$commandsOrder{$index}}); 
		my $sub = $commandsOrder{$index};
                chomp $sub;
                next if (($sub eq 'build') or ($sub eq 'version') or ($sub eq 'selfIP'));
                my $prop_ref=$$tree{$sub};
                my @cmd=$require->$sub($prop_ref);
                push(@cmds,"# $sub");
                push(@cmds,@cmd);
        }

	open(FH,">$outfile") or die "Unable to create file:$outfile. Error: $!\n";
        print FH "$_\n" foreach(@cmds);
        close FH;
	print "\nCreated file...\t\t$outfile\n" if ($verbose==1);
	return $outfile;

}

# Provide in the properties file and returns a hash TREE from PROP file. 

sub parse_prop {
	my $input = shift;
	my $verbose=shift;
	$verbose=0 if (! defined $verbose);
	print "\nReading file...\t\t$input\n" if ($verbose==1);
	if ($input=~/(\d+\.\d+\.\d+\.\d+)\.prop$/) {
                
                my $IP=$1;
                
                if(! ($IP=~/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) && ($1<=255) && ($2<=255) && ($3<=255) && ($4<=255)){
			print "WARN: Not a valid IP in the name of properties file \"$input\"\n";
                        return undef;
                }
        } else {
                
                print "\tWARN: Not a properties file format \"$input\"\n"; 
                return undef;
        }

	return &_parse($input,$verbose);
}


sub _parse {

	my $input=shift;
	my $verbose=shift;
        my $hash={};
        my $tree={};
        open(FH,"$input") or carp "Unable to open a properties file. Error: $!\n";
	return undef if (! <FH>);
	my @file=<FH>;
	close FH;
	foreach my $line (@file) {
                $line=~s/^\s*//;
                $line=~s/\s*$//;
                chomp $line;
                next if (($line=~/^\s*#/) or ($line=~/^\s*$/));
                my ($key,$value)=split /=/,$line;
		if ($key eq "include") {
			my $INCLUDE="INCLUDE_PROP";
			my $inp="$1"."$INCLUDE/$value".".prop" if ($input=~/(.+\/)\d+.\d+.\d+.\d+.prop/);
			print "Including: $value".".prop\t" if ($verbose==1);
			if (! -e $inp) {
				print "\tERROR: Included properties file \"$value\" does not exist.\n";
				return undef;
				next;	
			}
			my $ref=&_addSub($inp);
			foreach my $subk (keys %$ref) {
				chomp $subk;
				$hash->{$subk}=$ref->{$subk};
			}
		next;

		}
                $hash->{$key}=$value;
        }

        foreach my $key (keys %$hash) {
                my $ekey = $key;
                my @parts = split /\./, $ekey;
                @parts = '' unless @parts;
                my $t = $tree;
                while (@parts) {
                        my $part = shift @parts;
                        my $old = $t->{$part};
                        if (@parts) {
                                if (defined $old) {
                                    if (ref $old) {
                                        $t = $old;
                                    } else {
                                        $t = $t->{$part} = { '' => $old };
                                        }
                                } else {
                                        $t = $t->{$part} = {};
                                }
                        } else {
                                my $value = $hash->{$key};
                                if (ref $old) {
                                        $old->{''} = $value;
                                } else {
                                        $t->{$part} = $value;
                                }
                        }
                }
        }

        return $tree;  	
	
}

sub _addSub {
	my $inp=shift;
	my $subHash={};
	open(SH,"$inp") or carp "Unable to open a properties file. Error: $!\n";
        return undef if (! <SH>);
	my @file=<SH>;
        close SH;
	foreach my $l (@file) {
                $l=~s/^\s*//;
                $l=~s/\s*$//;
                chomp $l;
                next if (($l=~/^\s*#/) or ($l=~/^\s*$/));

                my ($key,$value)=split /=/,$l;
		$subHash->{$key}=$value;
	}

	return $subHash;
}

1;
