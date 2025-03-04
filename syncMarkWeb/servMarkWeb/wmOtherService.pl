#!/usr/bin/perl -w

#----------------------------------------------------------#
# author: angus brooks
# script: wmService.pl - server webmarks script
#----------------------------------------------------------#

use strict;

use FindBin '$Bin';
use lib "$Bin";

#use lib "$Bin/syncMarkWeb/servMarkWeb";

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
my %net_webMarks = (); # global HASH #
my ($server,$client,$client_address);
my $END_DATA = '####END_DATA####';
my $true=1;
my $false=0;

my $remoteHost =    $mark_init::confg{BOOKMAN}->{remoteHost};
my $remotePort =    $mark_init::confg{BOOKMAN}->{remotePort};
my $serverPort =    $mark_init::confg{BOOKMAN}->{serverPortOther}; # other Server Script
my $timeOut =        $mark_init::confg{BOOKMAN}->{timeOut};
my $flags =        $mark_init::confg{BOOKMAN}->{flags};
my $bufferSize =    $mark_init::confg{BOOKMAN}->{bufferSize};
my $bmFileName =    $mark_init::confg{BOOKMAN}->{bmFileName};
my $sleepInterval =    $mark_init::confg{BOOKMAN}->{sleepInterval};
my $logFile =        $mark_init::confg{BOOKMAN}->{logFileOther}; # other Server script

##### DEBUG #########
my $buffer_loops =0;
my $bufferExit = 3500;
my $clientTimeOut = 15;
##### DEBUG #########

my $defaultUserID = "XXXXX";
my $defaultUserName = "XXXX";
my %userTable = ();


#my $dbConFile = "/home/ubuntu/perlProjects/syncMarkWeb/servMarkWeb/wmDBConfig.dat";
#my $dbConFile = "C:\\Users\\angus\\perlMojo\\syncMarkWeb\\servMarkWeb\\wmDBConfig.dat";
my $dbConFile = "$Bin/wmDBConfig.dat";

my %ATTR = (
                LINK   => 'href',
                DATE   => 'add_date',
                TEXT  => 'text',
                ID     => 'id',
);

open (LOG_H, ">$logFile") or die "cannot open log file $logFile: $!\n";

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
    my ($link,$text,$date,$user_name) = (0,1,2,3);

    my $dbg = DbGlob->new($dbConFile);
    #my $dbc = DbConfig->new($dbConFile);
    my $dbh = $dbg->connect() or die "Error $!\n";
    
    #load data (a.title, a.dataAdded, b.url) from join of WM_BOOKMARK and WM_PLACE tables
    #do compare of b.url to global hash if miss then add above data to global hash
    #
    my $sth = $dbh->prepare("select b.url, a.title, a.dateAdded, c.user_name from WM_BOOKMARK a, WM_PLACE b, WM_USER c  where " .
              " a.user_id = c.user_id " .
              " and  a.place_id = b.place_id ");

    $sth->execute();
    my $arrayrefs = $sth->fetchall_arrayref;
    my $rowcount = $sth->rows;    

    LOG "****ROWCOUNT: $rowcount\n";

    foreach my $row (@$arrayrefs) 
    {

            $row->[$link] =~ s/\s*//g; # fix for dupes

            my $url = $row->[$link];
            my $user_id = $row->[$user_name];

            my $agg_key = $url ."_". $user_id;

            $webMarks{$agg_key} = {} unless  $webMarks{$agg_key};
            $webMarks{$agg_key}->{$ATTR{LINK}} = $row->[$link];
            $webMarks{$agg_key}->{$ATTR{DATE}} = $row->[$date];
            $webMarks{$agg_key}->{$ATTR{TEXT}} = $row->[$text];
            $webMarks{$agg_key}->{$ATTR{ID}} = $row->[$user_name]; 

    }

    LOG "-----------------QUERYDB Server End -----------------";

    $dbh->disconnect() or LOG "Disconnection failed: $DBI::errstr\n" and warn "Disconnection failed: $DBI::errstr\n";

}

sub populate_user_id($$)
{
    my $userName  = shift;
    my $local_dbh = shift;
    my $userID;
    chomp($userName);


    if (exists($userTable{$userName})) {
        $userID = $userTable{$userName}; 
        return $userID;
    }
 
    ($userID) = $local_dbh->selectrow_array("select user_id from WM_USER where user_name = ?", {}, $userName);

    if (defined($userID) && $userID !~ /^\s*$/) 
    {
        $userTable{$userName} = $userID;
        return $userID;
    } 
    else
    {
        return $defaultUserID;
    }

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

    my $userID;
    
    LOG "-----------------INSERTDB Server Comparison Routine Begin -----------------";

    foreach my $net_urlKey (keys %net_webMarks)
    {

        if (exists $webMarks{$net_urlKey})  #  DOES HASH FUNCTION LOOKUP OF URL -- NO NEED TO LOOP
        {
            next;
        }
  
        LOG "-----------------INSERTDB Server Match Routine Insert Statement Begin -----------------";

        my $url = $net_webMarks{$net_urlKey}->{$ATTR{LINK}};
        my $title = $net_webMarks{$net_urlKey}->{$ATTR{TEXT}};
        my $dateAdded = $net_webMarks{$net_urlKey}->{$ATTR{DATE}};
        my $userName = $net_webMarks{$net_urlKey}->{$ATTR{ID}};
        
            
        my $userID = populate_user_id($userName, $dbh); 

        LOG "----  returned USERID " . $userID . " ----------";

        if ($userID eq $defaultUserID) {

           LOG "---- SKIPPING INSERTION  NO CORRESPONDING USERNAME ----";
           next; 

        }


        #In order to insert new rows get max of id col of WM_BOOKMARK and WM_PLACE tables.
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

    #$dbh->disconnect() or LOG "Disconnection failed: $DBI::errstr\n" and warn "Disconnection failed: $DBI::errstr\n";
    LOG "-----------------INSERTDB Server Comparison Routine End -----------------";
    LOG "-----------------INSERTDB Server  End -----------------";

    }
 
    $dbh->disconnect() or LOG "Disconnection failed: $DBI::errstr\n" and warn "Disconnection failed: $DBI::errstr\n";
}


sub build_data_from_buffer
{
        my $nwBuffer = shift;
        my $bmBuffer = shift;
        
        $$bmBuffer .= $nwBuffer;
        $buffer_loops++;
        return $true if $nwBuffer =~ /$END_DATA/ || $$bmBuffer =~ /$END_DATA/ms;
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

        my @bmSegments = split(/\t+/, $line, -1);

        $bmSegments[$link] =~ s/\s*\t*\n*//g; # fix for dupes add g modifier
        #$bmSegments[$link] =~ s/\s*\t*\n*//g; # fix for dupes add g modifier

        my $url = $bmSegments[$link];
        my $user_id = $bmSegments[$id];

        my $agg_key = $url . "_" . $user_id;

        next if not defined $bmSegments[$link];

        $net_webMarks{$agg_key} = {};

        $net_webMarks{$agg_key}->{$ATTR{LINK}} = $bmSegments[$link] if $bmSegments[$link];

        $net_webMarks{$agg_key}->{$ATTR{DATE}} = $bmSegments[$date] if $bmSegments[$date];

        $net_webMarks{$agg_key}->{$ATTR{TEXT}} = $bmSegments[$text] if $bmSegments[$text]; 

        #$net_webMarks{$bmSegments[$link]}->{$ATTR{ID}} = $bmSegments[$id] if  $bmSegments[$id];

        $net_webMarks{$agg_key}->{$ATTR{ID}} = $bmSegments[$id] ?  $bmSegments[$id] : " [] " ;
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
    
    $client->read_timeout($clientTimeOut);
    $client->write_timeout($clientTimeOut);

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

            #======== Decoded buffer ----
            my $decoded_bmData = decode('UTF-8', $bmData);
            #======== Decoded buffer ----
    

            $EOF = build_data_from_buffer($decoded_bmData,\$bmBuffer) ; # last parm passed by ref for mod in func

            LOG "===============================  Outside of build_func  bufferSize: ".  length($bmBuffer) 
            .  " buffer loops ".  $buffer_loops . " ". date_time() . "===================================" if $buffer_loops % 10 == 0;

            if ($buffer_loops >= $bufferExit) 
            {
                LOG $bmBuffer;
                LOG "===== EXITING  CLIENT RECV LOOP ==== " . date_time();
                last;
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
    
        $client->shutdown(SHUT_RD);

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

        $client->send($encoded_send_msg);
    
        LOG "**** LOG OF SENT MESSAGE **************************************************************************************\n";
        LOG $send_msg;
        LOG "**** END OF SENT MESSAGE **************************************************************************************\n";
    
        $client->shutdown(SHUT_RDWR);
    
        #------------------------------------------------------------
        #  Do not insert into database pointed to by server script
        #insertDB_bookmarks($bmFileName);
        #------------------------------------------------------------
        LOG "Outputing to server bookmarks file";
            
    
    LOG "=" x 120;
    LOG "=============================== Complete. ".  date_time(). " =========================================================";
    LOG "=" x 120;




    
    } # end while accept 

    $server->shutdown();

    LOG "=" x 120;
    LOG "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! END SERVER PROGRAMS. ".  date_time(). " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
    LOG "!" x 120;
