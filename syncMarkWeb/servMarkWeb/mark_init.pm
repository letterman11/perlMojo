package mark_init;

use feature 'say';
use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(%confg);

my $config_file = "wmService.cfg";
%mark_init::confg = ();

read_config();

sub read_config
{
	my $curr_sec;

	open(FH, "<$config_file") or die "Cannot open: $config_file\n";
	while(<FH>)
	{
		next if /^#+/;
		next if /^\s*$/;
		if (/\[(\S+)\]/)
		{
			$curr_sec = $1;
			$curr_sec = uc($curr_sec);
			$mark_init::confg{$curr_sec} = {};
		}
		elsif (/=/)
		{
			my ($key,$value)= split /=/;
			$key =~ s/\s*//g;
			$value =~ s/\s*\t*//g;
			chomp($key,$value);
			$mark_init::confg{$curr_sec}->{$key}=$value;
			say $mark_init::confg{$curr_sec}->{$key};
		}
	}
close(FH);
}

1;
