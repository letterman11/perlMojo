package DbConfig;

use strict;
our @ISA = qw(DBI);
use DBI;

use FileHandle;

$::attr = { 
		PrintError => 0,
		RaiseError => 1,
        mysql_auto_reconnect => 1,
        mysql_enable_utf8mb4 => 1,
	}; 

$::attr2 = { 
		PrintError => 1,
		RaiseError => 0,
	}; 


####################
# Test alias
*DbConfig::errstr = *DBI::errstr; 
#
###################

sub new 
{
	my $class = shift;
	my %configHash = ();
	bless \%configHash, $class;

	my $self =  \%configHash;
	$self->_initialize($_[0]);	

	return \%configHash;
}


sub _initialize
{
	my $configHash = $_[0];
	my $defaultConfFile = defined($_[1]) && $_[1] !~ /^\s*$/ ?  $_[1] : "stockDbConfig.dat";
 	my $fh = new FileHandle;
	if ($fh->open("< $defaultConfFile") ) {
		while (<$fh>) {
			next if /^#/;
			 if (/([A-Za-z0-9_]+)=([A-Za-z0-9_\-\:\.\/]*)/) 
			{ 
				my ($key,$value) = ($1,$2);
				$configHash->{$key}=$value;
		       }	

		} 
		$fh->close;
  	} else { die "Error opening configfile $defaultConfFile \n"; }
	
}

sub _initialize2
{
	my $self = $_[0];
	my %configH;
	eval 'stockDB.pl';		
	print STDERR "here $@ ";
       %$self = (%$self,%configH);
	
}

sub dbName 
{
	my $self = shift;
	return $self->{'database'};
}     
     
sub dbHost
{
	my $self = shift;
	return $self->{'hostname'};
}

sub dbUser
{
	my $self = shift;
	return $self->{'user'};
} 

sub dbPass
{
	my $self = shift;
	return $self->{'password'};
} 

sub rowsPerPage
{
	my $self = shift;
	return $self->{'rowsperpage'};

}   

sub dbdriver
{

	my $self = shift;
	return $self->{'dbdriver'};

}

sub dbPort
{

	my $self = shift;
	return $self->{'port'};

}

sub connect 
{
	my $self = shift;
	my $dbdriver = $self->dbdriver; 
	my $dbname = $self->dbName; 
	my $dbuser = $self->dbUser; 
	my $dbpass = $self->dbPass; 
	my $dbhost = $self->dbHost; 
	my $dbport = $self->dbPort; 
      	my $dsn; 

	if ($dbdriver =~ /SQLite/i) 
	{
		$dsn = $dbdriver ."=". $dbname;

	} elsif ($dbdriver =~ /mysql/i) 
	{
		 $dsn = $dbdriver . ":database=$dbname;host=$dbhost;port=$dbport";	

	} elsif ($dbdriver =~ /Pg/i) 
	{
		 $dsn = $dbdriver . ":dbname=$dbname;host=$dbhost";	
	} else {

		$dsn = $dbdriver . $dbname;
	}

    no warnings;
	return $self->SUPER::connect($dsn,  $dbuser, $dbpass, $::attr );
  

}


1; 
