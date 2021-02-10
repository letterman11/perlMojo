package GenError;


use strict;
#use StockUtil;
use Error;

sub new
{
        my $class = shift();
        my $self = {};
	$self->{ERROBJ} = shift if @_;
        bless ($self,$class);
	return $self;
}

sub display
{
   my $self = shift(); 
   my $errstr = shift if @_;
   my $out_buffer = ();
 
   $errstr = exists($self->{ERROBJ}) && $self->{ERROBJ}->errText ? $self->{ERROBJ}->errText : $errstr;


#   print StockUtil::headerHttp();
   $out_buffer = <<"OUT_HTML";
<html>
<head>
<title> Error Page </title>
<link rel="stylesheet" href="$::URL_PATHS->{MAINSTYLE_CSS}" type="text/css">
</head>
<body>
<div id="app_error">
	<span class="errtext_large"> <p> $errstr </p> </span>
</div>
</body>
</html>
OUT_HTML
   print $out_buffer;
}









1;
