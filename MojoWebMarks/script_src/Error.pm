package Error;

use strict;

BEGIN
{
     require         Exporter;

     use vars          qw(@ISA @EXPORT @EXPORT_OK);
     @ISA            = qw(Exporter);
     @EXPORT         = qw();
     @EXPORT_OK      = qw();
}



my %err_codes = ( 
 			99  => "SuccessFully Changed Password",
			101 => "Failed Login",
			102 => "Database Failure",
			103 => "Session Exists",
			104 => "No Session Exists for ID",
			105 => "No Object exists for Session",
			106 => "User Name must be at least 6 characters",
			107 => undef,
			108 => undef,
			109 => undef,
			110 => undef,
			111 => "Password must be at least 6 characters",
			112 => "Incorrect User Name / Password",
			113 => "Passwords do not match",
			119 => "Invalid Email Address",
			120 => "User Name already taken",
			150 => "Duplicate Web Mark entry",
			151 => "Invalid Web Mark Submission",
			2000 => "Search Criteria Failure",
			ERRCOND => undef,
		);	



sub new
{
	my $class = shift;
	my $code  = shift; 
	my $self = \%err_codes;
	$self->{ERRCOND} = $code;
	bless ($self, $class);
	return $self;   

}


sub errText
{
	my $self = shift;
	return $self->{$self->{ERRCOND}};
}





1;
