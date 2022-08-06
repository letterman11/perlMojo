package Util;

use strict;
use Error;
use SessionObject;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use Storable;
use Data::Dumper;
use POSIX qw(strftime);
use Cwd qw(cwd);
use File::Spec;
use DateTime;
use Digest;
my $local_time_zone_nys = "America/New_York"; #for DateTime module does not do right if time zone is left off

use Mojo::Log;
our $moLog = Mojo::Log->new(path => '/home/angus/perlProjects/MojoWebMarks/log/production.log');


#my $tmp_dir = "/services/webpages/d/c/dcoda.net/tmp";
#my $tmp_dir = "/tmp";

my $tmp_dir = cwd;
my $sep = File::Spec->catfile('', '');
$tmp_dir .= $sep . "sessions";

our $sessionDbConf = "/home/angus/dcoda_net/lib/sessionFile.dat"; 

BEGIN
{
     require         Exporter;

     use vars        qw(@ISA @EXPORT @EXPORT_OK);
     @ISA            = qw(Exporter);
     #@EXPORT         = qw(&headerHttp &headerHtml &footerHtml &validateSession &validateSessionDB &formValidation &storeSession &storeSessionDB &storeSQL  &getStoredSQL &genSessionID &genID &isset);
     @EXPORT         = qw(&headerHttp &headerHtml &footerHtml &validateSession 
                                                &validateSessionDB &formValidation &storeSession &storeSessionDB &storeSQL2  
                                                        &getStoredSQL2 &genSessionID &genID &isset &convertDateEpoch);
}

########## Utility functions START ###############
##################################################
sub headerHttp
{
	return "Content-type:text/html\n\n";
}


sub headerHtml
{
	my $buffer_out;
	$buffer_out = headerHttp();
	$buffer_out .= "<html>\n"
   	       .  " <head>\n"
    	       .  "<title> StockApp</title>\n"
 	       .  "<LINK href='$::URL_PATHS->{MAINSTYLE_CSS}' rel='stylesheet' type='text/css'>\n"
	       .  "<script type='text/javascript' src='$::URL_PATHS->{COMMON_JS}'> </script>\n"
	       .  "</head>\n"
	       .  "<body>\n";
	return $buffer_out;

}

sub footerHtml
{
	my $buffer_out;
	$buffer_out = "</body>\n"
		. "</html>\n";
	return $buffer_out;
}

sub dumpEnvHtml
{
	my %anyHash		= %ENV;
	my ($key,$value)	= ""; 
	print "\n<table>";
	while (($key,$value) = each %anyHash) {
		print "\n<tr><td bgcolor=\"lightblue\"> $key </td> <td bgcolor=\"cyan\">$value</td></tr>";
	} 
	print "\n</table>"; 
}

sub parseParms
{
	my $rawInputParms	= $ENV{QUERY_STRING};
	my %inputHash	= ();

	my @rawInputParms = split /&/, $rawInputParms;
	foreach my $rawStr (@rawInputParms) {
		my ($key,$value) = split /=/, $rawStr;
		$inputHash{$key} = $value;
	}
	return \%inputHash;

}

sub printInputEnv 
{
	my ($key,$value)	= ""; 
	while (($key,$value) = each my %inputHash) {
		print "$key=$value\n";
	} 
  
}

sub genSessionID
{
	my @id_list = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9);
	my $id;
	for(my $i = 0; $i < 16; $i++) {
		 #$id .= $id_list[int(rand 35)] ;
  		 $id .= $id_list[ int rand scalar @id_list ];
	}
	return $id;
}


sub genQueryID
{
    my @id_list = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9);
    my $id;
    for(my $i = 0; $i < 5; $i++) {
               $id .= $id_list[int(rand 35)] ;
     }
       return $id;
}

sub isset
{
  return ((defined $_[0]) && ($_[0] !~ /^\s*$/));
}


sub  convertDateEpoch
{
    my $humanDate = shift;
    my ($year,$month,$day);

    $moLog->info("Start of Epoc func " . $humanDate);

    my @res1 = $humanDate =~ /([0-9]{1,2})[\-\/]([0-9]{1,2})[\-\/]([0-9]{4})/;
    my @res = $humanDate =~ /([0-9]{4})[\-\/]([0-9]{1,2})[\-\/]([0-9]{1,2})/;


    if (@res1)
    {
        print(@res1);
        $month = $res1[0];
        $day = $res1[1];
        $year = $res1[2];
    }
    elsif (@res)
    {
        print(@res);
        $year = $res[0];
        $month = $res[1];
        $day = $res[2];
    }

    $moLog->info(" 2/3 thru   Epoc func " . $humanDate);
    my $dateAdded = DateTime->new(year=>$year, month=>$month, day=>$day, time_zone=> $local_time_zone_nys)->epoch;

    $dateAdded = $dateAdded * (1000 * 1000);

    return $dateAdded;

}

sub digest_pass
{
    my $passwd = shift;
    my $sha512 = Digest->new("SHA-512"); 
    
    $sha512->add($passwd);
    return $sha512->hexdigest;

}

########## Utility functions END  ################
##################################################

########## Validation functions START ############
##################################################
sub formValidation
{
	my $query = shift;
	my %sqlInsert = ();
	my $passLen = 6;
	my $userLen = 6;

	$sqlInsert{firstName} =	isset($query->param('firstName')) ? $query->param('firstName') : '';
	$sqlInsert{lastName} =	isset($query->param('lastName')) ? $query->param('lastName') : '';
	$sqlInsert{address1} =	isset($query->param('address1')) ? $query->param('address1') : '';
	$sqlInsert{address2} =	isset($query->param('address2')) ? $query->param('address2') : '';
	$sqlInsert{city} =	isset($query->param('city')) ? $query->param('city') : '';
	$sqlInsert{state} =	isset($query->param('state')) ? $query->param('state') : '';
	$sqlInsert{zipcode} =	isset($query->param('zipcode')) ? $query->param('zipcode') : '';
	$sqlInsert{phone} =	isset($query->param('phone')) ? $query->param('phone') : '';
	$sqlInsert{email} =	isset($query->param('email_address')) ? $query->param('email_address') : '';
	$sqlInsert{userName} =	isset($query->param('user_name')) ? $query->param('user_name') : '';
	$sqlInsert{password} =	isset($query->param('new_user_pass1')) ? $query->param('new_user_pass2') : '';


	return Error->new(106) if($sqlInsert{userName} eq 'NULL' || length($sqlInsert{userName}) < $userLen); 

	return Error->new(111) if($sqlInsert{password} eq 'NULL' || length($sqlInsert{password}) < $passLen); 

	return Error->new(113) if($query->param('new_user_pass1') ne $query->param('new_user_pass2')); 

	return Error->new(119) if($sqlInsert{email} !~ /\w+[\w.]+?\w+@\w+[\w.]+?\.\w+\s*$/);

	return \%sqlInsert;
}

sub profileFormValidation
{

	my $query = shift;
	my %sqlUpdate = ();
	my $passLen = 6;
	my $userLen = 6;

	$sqlUpdate{new_password} =  isset($query->param('new_password')) ? $query->param('new_password') : '';
	$sqlUpdate{confirm_password} =  isset($query->param('confirm_password')) ? $query->param('confirm_password') : '';
	$sqlUpdate{userName} =	isset($query->param('userName')) ? $query->param('userName') : '';

	return Error->new(110) if($sqlUpdate{userName} eq '' || length($sqlUpdate{userName}) < $userLen); 

	if (length($sqlUpdate{new_password}) >= $passLen &&  length($sqlUpdate{confirm_password})  >= $passLen) {
 
		return Error->new(112) if $sqlUpdate{new_password} ne $sqlUpdate{confirm_password};
		return \%sqlUpdate;

	} else {

		return Error->new(112) if (length($sqlUpdate{new_password}) > 0 || length($sqlUpdate{confirm_password}) > 0);

		$sqlUpdate{firstName} = isset($query->param('firstName')) ? $query->param('firstName') : '';
		$sqlUpdate{lastName} =  isset($query->param('lastName')) ? $query->param('lastName') : '';
        	$sqlUpdate{address1} =  isset($query->param('address1')) ? $query->param('address1') : '';
        	$sqlUpdate{address2} =  isset($query->param('address2')) ? $query->param('address2') : '';
        	$sqlUpdate{city} =      isset($query->param('city')) ? $query->param('city') : '';
        	$sqlUpdate{state} =     isset($query->param('state')) ? $query->param('state') : '';
        	$sqlUpdate{zipcode} =   isset($query->param('zipcode')) ? $query->param('zipcode') : '';
        	$sqlUpdate{phone} =     isset($query->param('phone')) ? $query->param('phone') : '';

		return \%sqlUpdate;
		
	}

}


sub slurp_file
{
	my $file_name = shift;
	my $out_page = ();

        open(FH, "<$file_name") or
                warn "Cannot open $file_name\n";
        my $terminator = $/;
        undef $/;
        $out_page = <FH>; #slurp file all at once via above line.
        $/ = $terminator;
        close(FH);
	return $out_page;
}

########## Validation functions END #######################
###########################################################


sub storeSession
{
	my $sessionInstance = shift;
	my $sessionID = shift;
	my $userID = shift;
	my $userName = shift;
	
	my $sessionObject = SessionObject->new($sessionInstance,
                                         $sessionID,
                                         $userID,
                                         $userName);

	store $sessionObject, "$tmp_dir/$sessionID" || die $!;

}

sub getSessionInstance
{
	my $sInstancePre = 'ses';
	my @numInstances = @{$::SESSION_CONFIG->{INSTANCES}};
	return $sInstancePre . int(rand(scalar(@numInstances)));

}

sub storeSessionObject
{
    my $sessionObject = shift;
    my $sessionFile = $sessionObject->{wmSESSIONID};

	store $sessionObject, "$tmp_dir/$sessionFile" || die $!;

}

sub validateSession
{
    my $sessionID = shift;    
    my ($sessionObject,$userID)  = ();

   #$sessionObject = retrieve("$tmp_dir/$sessionID") || return Error->new(103);
    eval {
     $sessionObject = retrieve("$tmp_dir/$sessionID"); 
    };

    if ($@) 
    {
        return Error->new(103);
    }
   return $sessionObject;

}

sub storeSQL
{
    my $storedSQL = shift;
    my $sessionID = shift;

    my $sessObj = SessionObject->new();
    $sessObj->{'SESSIONDATA'} =  $storedSQL;
    $sessObj->{'wmSESSIONID'} = $sessionID;

    storeSessionObject($sessObj); 
}

sub storeSQL2
{
    my $storedSQL = shift;
    my $sessionID = shift;
    my $userID = shift;

    my $sessObj = SessionObject->new();
    $sessObj->{'SESSIONDATA'} =  $storedSQL;
    $sessObj->{'wmSESSIONID'} = $sessionID;
    $sessObj->{'wmUSERID'} = $userID;

    storeSessionObjectDB($sessObj); 

}

sub getStoredSQL
{
    my $sessionID = shift;
    my $sessionObject = validateSession($sessionID);
    my $storedSQL = $sessionObject->{'SESSIONDATA'};

    $moLog->error("#################SSQL " . $storedSQL);

    return $storedSQL;
}

sub getStoredSQL2 
{
    my $sessionID = shift;
    my $sessionObject = validateSessionDB($sessionID);
    my $storedSQL = $sessionObject->{'SESSIONDATA'};

    return $storedSQL;

}


sub storeSessionDB 
{
    my ($sessInst,$sessionID,$userID,$userName) = (@_);
    my $APPL = <DATA>;
	my $dbconf = DbConfig->new($sessionDbConf);
    my $path_to_file = $dbconf->dbName();
    my $local_dbh = $dbconf->connect()
        or die "Cannot Connect to Database $DBI::errstr\n";
 
    print STDERR $sessionID, "\n";

	my $now_str = strftime "%Y-%m-%d %H:%M:%S", localtime;

	my $rc2 = $local_dbh->do(" insert into session (APPL, SESSIONID, USERID, USERNAME, DATE_TS) values ('$APPL', '$sessionID', '$userID', '$userName', '$now_str') " );
        die "Trace Error alpha1 " . $dbconf->dbName() ." $DBI::errstr\n" unless defined ($rc2);

	print STDERR "RCODE2 => $rc2\n";

	if(not defined($rc2)) {
		print STDERR "Failed DB Operation: $DBI::errstr\n";
		$local_dbh->disconnect;
		return Error->new(150);
	}

}

sub storeSessionObjectDB 
{
    my $APPL;
    $APPL = <DATA>;
    close DATA;
    
    my $sessionObject = shift;

    my $storedSQL  = $sessionObject->{'SESSIONDATA'};
    my $sessionID  = $sessionObject->{wmSESSIONID};
    my $userID  = $sessionObject->{wmUSERID};

	my $now_str = strftime "%Y-%m-%d %H:%M:%S", localtime;

	my $dbconf = DbConfig->new($sessionDbConf);

	my $local_dbh = $dbconf->connect()
               or die "Cannot Connect to Database $DBI::errstr\n";

    my $quoted_storedSQL =  $local_dbh->quote($storedSQL); 

    eval {

	    $local_dbh->do(qq{
				insert into session (APPL, SESSIONID, USERID, USERNAME, DATE_TS, SESSIONDATA) values 
                ('$APPL', '$sessionID', '$userID', '$userID', '$now_str', $quoted_storedSQL)
				});

    };

    if ($@) 
    {

        $moLog->error("Failed insert for session table ?? " . $DBI::errstr);

        eval {

	     $local_dbh->do(qq{
				update session  
				set SESSIONDATA =  $quoted_storedSQL,
                    UPDATE_TS = '$now_str'
				 where SESSIONID = '$sessionID' 
				});

        };

    	if($@) {
            $moLog->error("Failed update for session table  ?? " . $DBI::errstr);

    		print STDERR "Failed DB Operation: $DBI::errstr\n";
    		$local_dbh->disconnect;
    		return Error->new(150);
    	}

    } else {

        return $sessionObject;        
    }

}

sub validateSessionDB 
{

    my $storedSQL;
    my $sessionID = shift;
  	my $dbconf = DbConfig->new($sessionDbConf);

    my $local_dbh = $dbconf->connect()
       or die "Cannot Connect to Database $DBI::errstr\n";
    
    $moLog->error("SessionID " . $sessionID);

    ($sessionID,$storedSQL) = $local_dbh->selectrow_array("select SESSIONID, SESSIONDATA from session where SESSIONID = '$sessionID' ");

    $moLog->error( " validate SSQL " . $storedSQL);
    $moLog->error( "SessionID AFTER " . $sessionID);

    #die "$DBI::errstr Error DB \n" unless defined ($sessionID);

    return Error->new(2000) unless defined $sessionID;
    return SessionObject->new("mojoMarks",$sessionID,undef,undef,$storedSQL);
        
}


__DATA__
WEBMARKS

1;
