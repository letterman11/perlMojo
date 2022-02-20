#!/usr/bin/perl -w

#----------------------------------------------------------#
# author: angus brooks	     							   
# script: wmClient.pl									   
# purpose: client script for webmarks  
#----------------------------------------------------------#

use strict;
use lib "/home/angus/perlProjects/syncMarkWeb/clientMarkWeb";
#use lib "/home/angus/dcoda_net/lib";

use mark_init;
use IO::Socket;
use DbGlob;
use Getopt::Long;
use Encode 'encode';
use Encode 'decode';


$| = 1;
my %webMarks = ();
my $bmFileDir;
my $DEBUG = 0;
my $END_DATA = "####END_DATA####";
my $true = 1;
my $false = 0;
my $trace;
my $tracefile;
my @opts = ("trace=s","tracefile=s");
my %optctl = (trace =>\$trace, tracefile =>\$tracefile);

my $remoteHost =	$mark_init::confg{BOOKMAN}->{remoteHost};
my $remotePort =	$mark_init::confg{BOOKMAN}->{remotePort};
my $timeOut =		$mark_init::confg{BOOKMAN}->{timeOut};
my $flags =		$mark_init::confg{BOOKMAN}->{flags};
my $bufferSize =	$mark_init::confg{BOOKMAN}->{bufferSize};
my $bmFileName =	$mark_init::confg{BOOKMAN}->{bmFileName};
my $sleepInterval =	$mark_init::confg{BOOKMAN}->{sleepInterval};
my $logFile =		$mark_init::confg{BOOKMAN}->{logFile};
my $changeTest =	$mark_init::confg{BOOKMAN}->{change};
my $bmDB = "nothing";
my $maxRuns =		$mark_init::confg{BOOKMAN}->{runs};
my $run =           0;

my $dbConFile = "/home/angus/perlProjects/syncMarkWeb/clientMarkWeb/wmDBConfig.dat";

my %ATTR = (
                LINK   => 'href',
                DATE   => 'add_date',
                TEXT  => 'text',
                ID     => 'id',
);

open (LOG_H, ">$logFile") or die "cannot open $logFile: $!\n";

LOG_H->autoflush(1);

GetOptions(\%optctl,@opts);

sub LOG
{
        my $message = shift;
        print LOG_H date_time(), $message , "\n";
}


sub close_log
{
    close(LOG_H) or warn "Problems closing LOG file handle";
}

sub queryDB_bookmarks
{
	LOG "-----------------QUERYDB CLient Begin -----------------";
	my $dbFile = shift;
	warn "$dbFile";
	my $matchFlag = 0;
	my ($link,$text,$date) = (0,1,2);

	my $dbg = DbGlob->new($dbConFile);

	my $dbh = $dbg->connect() or die "Error $!\n";
	
	if ($trace && $tracefile)
	{
		$dbh->trace($trace, $tracefile);
	} 
	elsif($trace)
	{
		$dbh->trace($trace);
	}
                          # 0 link, 1 title, 2 date
    my $sel_str = " select b.url, a.title, a.dateAdded from WM_BOOKMARK a, WM_PLACE b where a.PLACE_ID = b.PLACE_ID";

	#load data (a.title, a.dataAdded, b.url) from join of WM_BOOKMARK and WM_PLACE tables

	my $sth = $dbh->prepare($sel_str);

	$sth->execute();

	my $arrayrefs = $sth->fetchall_arrayref;

	my $rowcount = $sth->rows;	

	LOG "****ROWCOUNT: $rowcount\n";

	foreach my $row (@$arrayrefs) 
	{
			my $url = $row->[$link];
			$webMarks{$url} = {} unless  $webMarks{$url};
			$webMarks{$url}->{LINK} = $url;
			$webMarks{$url}->{DATE} = $row->[$date];
			$webMarks{$url}->{TEXT} = $row->[$text];
			$webMarks{$url}->{ID} = "-";
	}


	$dbh->disconnect() or LOG "Disconnection failed: $DBI::errstr\n" and warn "Disconnection failed: $DBI::errstr\n";

	LOG "-----------------QUERYDB CLient  End -----------------";
}


sub insertDB_bookmarks
{
	LOG "-----------------INSERTDB CLient  Begin -----------------";
	my $dbFile = shift;
	my $matchFlag = 0;
	my ($link,$text,$date,$user_id) = (0,1,2,3);
	my $dbg = DbGlob->new($dbConFile);
	my $dbh = $dbg->connect() or die "Error $!\n";

	if ($trace && $tracefile)
	{
		$dbh->trace($trace, $tracefile);
	} 
	elsif($trace)
	{
		$dbh->trace($trace);
	}

	#load link column from DB if link does not equal
	#to bookmark url, then find the max(bookmark_id) and max(place_id) from DB, increment by one for each table
	#then insert bookmark_id, fk(place_id), title, dataAdded, lastMod into WM_BOOKMARK
	#insert place_id, url, title into WM_PLACE.  should be enough to recreate a bookmark.
	#forget the rest of tables/colums.
	########################
	# added insert of user_id into bookmark_id -- need scheme to insert rows from other sites that 
    # match up user_id and names - some function/heuristic to solve this properly
	##########################

	my $sel_str = <<"SQL_SEL";    
	select b.URL, a.TITLE, a.DATEADDED, a.USER_ID 
    from WM_BOOKMARK a, WM_PLACE b where  	
    a.PLACE_ID = b.PLACE_ID 
SQL_SEL

	my $sth = $dbh->prepare($sel_str);

	$sth->execute();

	my $arrayrefs = $sth->fetchall_arrayref();

	my $rowcount = $sth->rows;	

	my $userID;

	LOG "-----------------INSERTDB CLient Comparison Routine Begin -----------------";
	
	foreach my $urlKey (keys %webMarks)
	{
		foreach my $row (@$arrayrefs)
		{
           
			#new feature to insert not null user_id
        	$userID = $row->[$user_id];
			if ($row->[$link] eq $urlKey)
			{
				$matchFlag = 1;
				last;
			}
		}
	
		if(!$matchFlag)
		{

		    LOG "-----------------INSERTDB CLient Match Routine Insert Statement Begin -----------------";
			my $url = $webMarks{$urlKey}->{LINK};
			my $title = $webMarks{$urlKey}->{TEXT};
			my $dateAdded = $webMarks{$urlKey}->{DATE};
	        

			my ($tbl1MaxId) = $dbh->selectrow_array("select max(BOOKMARK_ID) from WM_BOOKMARK");
			my ($tbl2MaxId) = $dbh->selectrow_array("select max(PLACE_ID) from WM_PLACE");
			
			$tbl1MaxId++;
			$tbl2MaxId++;

			
			#------- wm_bookmark------------------------
			my $sql_insert_wm_book = "insert into WM_BOOKMARK (BOOKMARK_ID, PLACE_ID, TITLE, DATEADDED, USER_ID) values (?,?,?,?,?)";

			my @bind_vals_bookmark = ($tbl1MaxId,
							$tbl2MaxId,
							$title,
							$dateAdded,
							$userID);

			my $rc = $dbh->do($sql_insert_wm_book, {}, @bind_vals_bookmark); 

			#------- wm_bookmark------------------------
			
			#------- wm_place------------------------
			my $sql_insert_wm_place = "insert into WM_PLACE (PLACE_ID, URL, TITLE) values (?, ?, ?)";

			my @bind_vals_place = ($tbl2MaxId,
									$url,
									$title);

			my $rc2 = $dbh->do($sql_insert_wm_place, {}, @bind_vals_place);
			#------- wm_place------------------------
			# error checks later to be put in place
			#######################################
			LOG "-----------------INSERTDB CLient Match Routine Insert Statement End -----------------";
		}


		$matchFlag = 0;
	}
	
	$dbh->disconnect() or LOG "Disconnection failed: $DBI::errstr\n" and warn "Disconnection failed: $DBI::errstr\n";
	LOG "-----------------INSERTDB CLient Comparison Routine End -----------------";
	

	LOG "-----------------INSERTDB CLient  End -----------------";

}

sub build_data_from_buffer
{
        my $nwBuffer = shift;
        my $bmBuffer = shift;

        $$bmBuffer .= $nwBuffer;
        return $true if $nwBuffer =~ /$END_DATA/;
        return $false;

}

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

                $webMarks{$bmSegments[$link]}->{LINK} = $bmSegments[$link] if $bmSegments[$link];

                $webMarks{$bmSegments[$link]}->{DATE} = $bmSegments[$date] if $bmSegments[$date];

                $webMarks{$bmSegments[$link]}->{TEXT} = $bmSegments[$text] if $bmSegments[$text];

                $webMarks{$bmSegments[$link]}->{ID} = $bmSegments[$id] ?  $bmSegments[$id] : " [] " ;
        }

}

sub date_time
{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
							localtime(time);
	$year += 1900;
	my @months = qw(Jan Feb Mar Apr May Jun July Aug Sept Oct Nov Dec);
	return("$months[$mon] $mday $year $hour:$min:$sec ");
}

#------------------------ Main ----------------------------#	

LOG "****** LOGGING INITIATED *******\n";
	
while (1) {

	LOG "=" x 120;
	LOG  "=" x int((120 - 1)/2) . "@" . "=" x int((120-1)/2);
	LOG  "=" x int((120 - 3)/2) . "@@@" . "=" x int((120-3)/2);
	LOG  "=" x int((120 - 5)/2) . "@@@@@" . "=" x int((120-5)/2);
	LOG "=============================== Start     ". date_time() . " =========================================================";
	LOG  "=" x int((120 - 5)/2) . "@@@@@" . "=" x int((120-5)/2);
	LOG  "=" x int((120 - 3)/2) . "@@@" . "=" x int((120-3)/2);
	LOG  "=" x int((120 - 1)/2) . "@" . "=" x int((120-1)/2);

	mark_init::read_config();


	###### query DBs
	queryDB_bookmarks($bmDB);

	my $socket = IO::Socket::INET->new( PeerAddr    => $remoteHost,
                                                PeerPort        => $remotePort,
                                                Proto           => "tcp",
						#Timeout           => 8,
                                                Type            => SOCK_STREAM)
                                                or LOG "Coudn't connect to $remoteHost:$remotePort : $@\n"
                                                and die "Coudn't connect to $remoteHost:$remotePort : $@\n";

	# code/decode socket for utf8 - Unicode
    ### commented out binmode utf  because of intro of utf8 in lower encoding layers
    # an error in perl 30.0 and up if used

	#binmode($socket, ":encoding(UTF-8)");
	#binmode($socket, ":bytes");

	$socket->autoflush(1);

    my $send_msg;

	for my $bmKey (keys %webMarks) {
	       $send_msg .= $webMarks{$bmKey}->{LINK} . "\t";
	       $send_msg .= $webMarks{$bmKey}->{DATE} . "\t";
	       $send_msg .= $webMarks{$bmKey}->{TEXT} . "\t";
	       #$send_msg .= $webMarks{$bmKey}->{$ATTR{ID}} . "\t" if $webMarks{$bmKey}->{$WINATTR{ID}};
	       $send_msg .= "\n";
	}

	$send_msg .= $END_DATA;
	$send_msg .= "\n";

    #=========== Encode send message ------- 
    my $encoded_send_msg = encode('UTF-8', $send_msg);
    #=========== Encode send message -------


	LOG "**** LOG OF SENT MESSAGE ****************************************************************************";
 	#LOG $send_msg;
	LOG "**** END LOG OF SENT MESSAGE ************************************************************************";
	
	#$socket->send($send_msg) or LOG  "Cannot send to server \n"  and 
	#			die "Cannot send to server \n";  # this will block until successful send or timeout			

	$socket->send($encoded_send_msg) or LOG  "Cannot send to server \n"  and 
				die "Cannot send to server \n";  # this will block until successful send or timeout			

	LOG "Expecting recieve from server";

	my $EOF=$false;
	my $bmData;
	my $bmBuffer;

	LOG "at begin of loop from server";
	## new value for timeout
	## to test for failure
	##
	LOG $socket->timeout() . " Socket Timeout";
	$socket->timeout(5);
	LOG $socket->timeout() . " Socket Timeout Set";
	###
	do {

		$bmData = ();

		$socket->recv($bmData, $bufferSize);

		#======== Decoded buffer ----
		my $decoded_bmData = decode('UTF-8', $bmData);
		#======== Decoded buffer ----


		#$EOF = build_data_from_buffer($bmData,\$bmBuffer) ; # last parm passed by ref for mod in func
		$EOF = build_data_from_buffer($decoded_bmData,\$bmBuffer) ; # last parm passed by ref for mod in func

		#debug_println("After recv of socket");

	}      
	while(!$EOF);

	LOG "just outside end loop from server";

	LOG "**** LOG OF RECIEVED MESSAGE ****************************************************************************";
 	#LOG $bmBuffer;
	LOG "**** END LOG OF RECIEVED MESSAGE ************************************************************************";

	extract_data_from_buffer($bmBuffer); 

	LOG "Output of bookmarks to *nix\n";
	
	#output_bookmarks($bmFileName);

	###### insert into firefox SQLiteDB
	insertDB_bookmarks($bmDB);	

	dump_bm() if $DEBUG;

	
	$socket->close();
	#$socket->shutdown();
	LOG "=" x 120;
	LOG "=============================== Complete. ".  date_time(). " =========================================================";
	LOG "=" x 120;
    
    if (++$run == $maxRuns) 
    {
        LOG "@@@@@@@@ Exiting client script @@@@@@@@@@";
        close_log(); 
        exit(0);
    }

	sleep ($mark_init::confg{BOOKMAN}->{sleepInterval});	
    
}	
