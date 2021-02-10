package SessionObject;

use strict;


sub new 
{
	my $class = shift;
	my $self = {};

	$self->{INSTANCE} = shift;
	$self->{wmSESSIONID} = shift;
	$self->{wmUSERID} = shift;
	$self->{wmUSERNAME} = shift;
	$self->{SESSIONDATA} = shift if @_;
	$self->{ROWCOUNT} = shift if @_;
	$self->{SORT} = shift if @_;
	bless $self, $class;	
	return $self; 

}


1;
