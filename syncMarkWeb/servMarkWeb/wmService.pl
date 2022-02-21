#!/usr/bin/perl -w

#----------------------------------------------------------#
# author: angus brooks
# script: wmService.pl - server webmarks script
#----------------------------------------------------------#

use strict;
#use lib "/home/ubuntu/perlProjects/webMarksService";
use lib "/home/ubuntu/perlProjects/syncMarkWeb/servMarkWeb";

use mark_init;
use IO::Socket;
use IO::Socket::Timeout;
use DbGlob;
use Encode 'encode';
use Encode 'decode';
use Errno qw(ETIMEDOUT EWOULDBLOCK);


$| = 1;
my $DEBUG = $ARGV[0] || 0;


my %webMarks = (); # global HASH #
my ($server,$client,$client_address);
my $END_DATA = '####END_DATA####';
my $true=1;
my $false=0;

my $remoteHost =	$mark_init::confg{BOOKMAN}->{remoteHost};
my $remotePort =	$mark_init::confg{BOOKMAN}->{remotePort};
my $serverPort =	$mark_init::confg{BOOKMAN}->{serverPort};
my $timeOut =		$mark_init::confg{BOOKMAN}->{timeOut};
my $flags =		$mark_init::confg{BOOKMAN}->{flags};
my $bufferSize =	$mark_init::confg{BOOKMAN}->{bufferSize};
my $bmFileName =	$mark_init::confg{BOOKMAN}->{bmFileName};
my $sleepInterval =	$mark_init::confg{BOOKMAN}->{sleepInterval};
my $logFile =		$mark_init::confg{BOOKMAN}->{logFile};

##### DEBUG #########
my $buffer_loops =0;
my $bufferExit = 3500;
##### DEBUG #########

my $dbConFile = "/home/ubuntu/perlProjects/syncMarkWeb/servMarkWeb/wmDBConfig.dat";

my %ATTR = (
                LINK   => 'href',
                DATE   => 'add_date',
                TEXT  => 'text',
                ID     => 'id',
);

open (LOG_H, ">$logFile") or die "cannot open $logFile: $!\n";

LOG_H->autoflush(1);


sub LOG
{
        my $message = shift;
        print LOG_H date_time(), $message, "\n";
}

sub date_time
{
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                        localtime(time);
        $year += 1900;
	my @months = qw(Jan Feb Mar Apr May Jun July Aug Sept Oct Nov Dec);
        return("$months[$mon] $mday $year $hour:$min:$sec ");
}

sub queryDB_bookmarks
{
	LOG "-----------------QUERYDB Server Begin -----------------";
	my $dbFile = shift;
	warn "$dbFile";
	my $matchFlag = 0;
	my ($link,$text,$date) = (0,1,2);

	my $dbg = DbGlob->new($dbConFile);
	#my $dbc = DbConfig->new($dbConFile);
	my $dbh = $dbg->connect() or die "Error $!\n";
	
	#load data (a.title, a.dataAdded, b.url) from join of WM_BOOKMARK and WM_PLACE tables
	#do compare of b.url to global hash if miss then add above data to global hash

	my $sth = $dbh->prepare("select b.url, a.title, a.dateAdded from WM_BOOKMARK a, WM_PLACE b where " .
			  " a.place_id = b.place_id ");
	$sth->execute();
	my $arrayrefs = $sth->fetchall_arrayref;
	my $rowcount = $sth->rows;	

	LOG "****ROWCOUNT: $rowcount\n";

	foreach my $row (@$arrayrefs) 
	{

			my $url = $row->[$link];
			$webMarks{$url} = {} unless  $webMarks{$url};
			$webMarks{$url}->{$ATTR{LINK}} = $row->[$link];
			$webMarks{$url}->{$ATTR{DATE}} = $row->[$date];
			$webMarks{$url}->{$ATTR{TEXT}} = $row->[$text];
			$webMarks{$url}->{$ATTR{ID}} = "-";

	}

	LOG "-----------------QUERYDB Server End -----------------";

	$dbh->disconnect() or LOG "Disconnection failed: $DBI::errstr\n" and warn "Disconnection failed: $DBI::errstr\n";

}

sub insertDB_bookmarks
{
	LOG "-----------------INSERTDB Server  Begin -----------------";
	my $dbFile = shift;
	my $matchFlag = 0;
	my ($link,$text,$date,$user_id) = (0,1,2,3);
	my $dbg = DbGlob->new($dbConFile);
	my $dbh = $dbg->connect() or die "Error $!\n";

	#load link column from DB if link does not equal
	#to bookmark url, then find the max(id) from DB, increment by one
	#then insert id, fk, title, dataAdded, lastMod into WM_BOOKMARKS
	#insert fk as id, url, title into WM_PLACE.  should be enough to recreate a bookmark.
	#forget the rest of tables.

	my $sth = $dbh->prepare("select b.url, a.title, a.dateAdded, a.user_id from WM_BOOKMARK a, WM_PLACE b where " .	
			  " a.place_id = b.place_id ");

	$sth->execute();
	my $arrayrefs = $sth->fetchall_arrayref();
	my $rowcount = $sth->rows;	
    my $userID;
	
	LOG "-----------------INSERTDB Server Comparison Routine Begin -----------------";

	foreach my $urlKey (keys %webMarks)
	{
		foreach my $row (@$arrayrefs)
		{
			# new feature to insert not null user_id
			#
            $userID = $row->[$user_id]; 
			if ($row->[$link] eq $urlKey)
			{
				$matchFlag = 1;
				last;
			}
		}
	
		if(!$matchFlag)
		{
		    LOG "-----------------INSERTDB Server Match Routine Insert Statement Begin -----------------";
			my $url = $webMarks{$urlKey}->{$ATTR{LINK}};
			my $title = $webMarks{$urlKey}->{$ATTR{TEXT}};
			my $dateAdded = $webMarks{$urlKey}->{$ATTR{DATE}};
		
            

			#In order to insert new rows get max of id col of WM_BOOKMARK and WM_PLACE tables.
			my ($tbl1MaxId) = $dbh->selectrow_array("select max(BOOKMARK_ID) from WM_BOOKMARK");
			my ($tbl2MaxId) = $dbh->selectrow_array("select max(PLACE_ID) from WM_PLACE");
			
			$tbl1MaxId++;
			$tbl2MaxId++;

			my $typeID = 1; # needed for WM_BOOKMARK
			my $parentID = 5; # needed for WM_BOOKMARK_roots

			my $rc = $dbh->do("insert into WM_BOOKMARK (bookmark_id, place_id, title, dateAdded, user_id) values ($tbl1MaxId, $tbl2MaxId," . $dbh->quote($title) 
			. ",'$dateAdded', '$userID')");

			my $rc2 = $dbh->do("insert into WM_PLACE (place_id, url, title) values ($tbl2MaxId," . $dbh->quote($url) . ", " . $dbh->quote($title) . ")");

			LOG "-----------------INSERTDB Server Match Routine Insert Statement End -----------------";
		}

		$matchFlag = 0;
	}
	
	$dbh->disconnect() or LOG "Disconnection failed: $DBI::errstr\n" and warn "Disconnection failed: $DBI::errstr\n";

	LOG "-----------------INSERTDB Server Comparison Routine End -----------------";
	LOG "-----------------INSERTDB Server  End -----------------";
}


sub build_data_from_buffer
{
        my $nwBuffer = shift;
		my $bmBuffer = shift;
		
        $$bmBuffer .= $nwBuffer;
	$buffer_loops++;
        return $true if $nwBuffer =~ /$END_DATA/;
        return $false;

}

#----------------------------------------------------------#
# function: extract_data_from_buffer		 	   
# extracts data from network populated buffer		   
# recieved from socket.					   
#----------------------------------------------------------#
sub extract_data_from_buffer
{
	my ($link,$date,$text,$id) = (0,1,2,3);
	my $buffer = shift;
	for my $line (split (/\n/, $buffer)) {

		last if $line =~ /$END_DATA/;

		my @bmSegments = split(/\t+/, $line);

		$bmSegments[$link] =~ s/\s*\t*\n*//;

		next if not defined $bmSegments[$link];

                $webMarks{$bmSegments[$link]} = {};

                $webMarks{$bmSegments[$link]}->{$ATTR{LINK}} = $bmSegments[$link] if $bmSegments[$link];

                $webMarks{$bmSegments[$link]}->{$ATTR{DATE}} = $bmSegments[$date] if $bmSegments[$date];

                $webMarks{$bmSegments[$link]}->{$ATTR{TEXT}} = $bmSegments[$text] if $bmSegments[$text]; 

                $webMarks{$bmSegments[$link]}->{$ATTR{ID}} = $bmSegments[$id] ?  $bmSegments[$id] : " [] " ;
	}

}

sub CLOSESOCK
{
  print "";
}


#----------------------------------------------------------#
#------------------- Main ---------------------------------#
#----------------------------------------------------------#

	$server = IO::Socket::INET->new(LocalPort       => $serverPort,
	                                 Type           => SOCK_STREAM,
	                                 Reuse          => 1,
	                                 Blocking       => 1,
	                                 Listen         => 2 )
	                                 or LOG "Couldn't be a tcp server on port $serverPort : $@\n"
	                                 and die "Couldn't be a tcp server on port $serverPort : $@\n";


	#explicit unicode setting
	#binmode($server, ":encoding(UTF-8)");
	#binmode($server);

	LOG "After socket initialization";

	while ($client = $server->accept()) {

	IO::Socket::Timeout->enable_timeouts_on($client);
	
	$client->read_timeout(8);
	$client->write_timeout(8);

	LOG "=" x 120;
	LOG "=============================== Start     ". date_time() . " =========================================================";
	LOG "=" x 120;

	
		#get_local_bookmarks($bmFileName);
		queryDB_bookmarks($bmFileName);
	
		my $EOF=$false;
		my $bmBuffer;
		
		LOG "BEFORE CALLS OF CLIENT RECV: " . $client->peerhost() . " " .  $client->peerport();
		my $bmData;
		my $retCode;	
		do {
			#my $bmData;
	
			$client->recv($bmData, $bufferSize);

			if ( 0+$! == ETIMEDOUT || 0+$! == EWOULDBLOCK ) {
				last;
			  }

			#
       			#======== Decoded buffer ----
		        my $decoded_bmData = decode('UTF-8', $bmData);
       			#======== Decoded buffer ----
	

			#$EOF = build_data_from_buffer($bmData,\$bmBuffer) ; # last parm passed by ref for mod in func
	                $EOF = build_data_from_buffer($decoded_bmData,\$bmBuffer) ; # last parm passed by ref for mod in func
			LOG "===============================  Outside of build_func  bufferSize: ".  length($bmBuffer) 
			.  " buffer loops ".  $buffer_loops . " ". date_time() . "===================================" if $buffer_loops % 10 == 0;

			if ($buffer_loops >= $bufferExit) 
			{
				last;
				LOG "===== EXITING  CLIENT RECV LOOP ==== " . date_time();
			}

		}	
		while(!$EOF);
		#while(!$EOF || $buffer_loops < 1500);
		$bmData = undef;
		$buffer_loops=0;
	
		LOG "AFTER CALLS OF CLIENT RECV";
	
		LOG "**** LOG OF RECIEVED MESSAGE **********************************************************************************";
		#LOG $bmBuffer;
		LOG "**** END OF RECIEVED MESSAGE **********************************************************************************";
	
	        extract_data_from_buffer($bmBuffer); 
	
		my $send_msg;
		
		for my $bmKey (keys %webMarks) {
		       $send_msg .= $webMarks{$bmKey}->{$ATTR{LINK}} . "\t";
		       $send_msg .= $webMarks{$bmKey}->{$ATTR{DATE}} . "\t";
		       $send_msg .= $webMarks{$bmKey}->{$ATTR{TEXT}} . "\t";
		       $send_msg .= $webMarks{$bmKey}->{$ATTR{ID}} . "\t" if $webMarks{$bmKey}->{$ATTR{ID}};
		       $send_msg .= "\n";
	
		}
	
	
		$send_msg .= $END_DATA;
		$send_msg .= "\n";

		#======= Encode send message -- 
		my $encoded_send_msg = encode('UTF-8', $send_msg);	
		#======= Encode send message -- 

		#$client->send($send_msg);
		$client->send($encoded_send_msg);
	
#		LOG "**** LOG OF SENT MESSAGE **************************************************************************************\n";
#		LOG $send_msg;
#		LOG "**** END OF SENT MESSAGE **************************************************************************************\n";
	
		$client->close();
	
	
		#output_bookmarks($bmFileName);
		insertDB_bookmarks($bmFileName);
		LOG "Outputing to server bookmarks file";
	
	LOG "=" x 120;
	LOG "=============================== Complete. ".  date_time(). " =========================================================";
	LOG "=" x 120;




	
	} # end while accept 

	$server->shutdown();

	LOG "=" x 120;
	LOG "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! END SERVER PROGRAMS. ".  date_time(). " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
	LOG "!" x 120;
