#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

#----------------------------------------------------------#
# author: angus brooks -- ai refactor
# script: wmOtherClient.pl
# purpose: client script for webmarks synchronization
#----------------------------------------------------------#

use lib '.';

BEGIN {
    use mark_init;
    mark_init::read_config();
}

use lib $mark_init::confg{BOOKMAN}->{libdir};

use IO::Socket::INET;
use DbGlob;
use Getopt::Long;
use Encode qw(encode decode);
use Try::Tiny;

# Configuration constants
use constant {
    END_DATA_TOKEN => "####END_DATA####",
    DEFAULT_USER_ID => "XXXXX",
    DEFAULT_USER_NAME => "XXXX",
};

# Package variables
my %webmarks = ();
my %net_webmarks = ();
my %user_table = ();
my $log_fh;

# Command line options
my %options = (
    trace => undef,
    tracefile => undef,
    debug => 0,
);

GetOptions(
    'trace=i' => \$options{trace},
    'tracefile=s' => \$options{tracefile},
    'debug' => \$options{debug},
) or die "Error in command line arguments\n";

# Configuration
my $config = $mark_init::confg{BOOKMAN};

# Initialize logging
open($log_fh, ">>", $config->{logFile}) 
    or die "Cannot open log file $config->{logFile}: $!\n";
$log_fh->autoflush(1);

#----------------------------------------------------------#
# Utility Functions
#----------------------------------------------------------#

sub log_message {
    my ($message) = @_;
    my $timestamp = get_timestamp();
    print {$log_fh} "$timestamp $message\n";
}

sub get_timestamp {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
    $year += 1900;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    return sprintf("%s %d %d %02d:%02d:%02d", 
                   $months[$mon], $mday, $year, $hour, $min, $sec);
}

sub log_separator {
    my ($char, $message) = @_;
    $char //= '=';
    log_message($char x 120);
    log_message($message) if $message;
    log_message($char x 120);
}

#----------------------------------------------------------#
# Database Functions
#----------------------------------------------------------#

sub get_db_connection {
    my $dbg = DbGlob->new($config->{dbConf});
    my $dbh = $dbg->connect() 
        or die "Database connection failed: $!\n";
    
    if ($options{trace}) {
        if ($options{tracefile}) {
            $dbh->trace($options{trace}, $options{tracefile});
        } else {
            $dbh->trace($options{trace});
        }
    }
    
    return $dbh;
}

sub query_local_bookmarks {
    log_message("Querying local bookmarks database");
    
    my $dbh = get_db_connection();
    
    my $query = <<'SQL';
        SELECT b.url, a.title, a.dateAdded, c.user_name 
        FROM WM_BOOKMARK a
        INNER JOIN WM_PLACE b ON a.PLACE_ID = b.PLACE_ID
        INNER JOIN WM_USER c ON a.user_id = c.user_id
SQL
    
    my $sth = $dbh->prepare($query);
    $sth->execute();
    
    my $rows = $sth->fetchall_arrayref();
    log_message("Retrieved " . scalar(@$rows) . " bookmarks from local database");
    
    %webmarks = ();  # Clear existing data
    
    foreach my $row (@$rows) {
        my ($url, $title, $date_added, $user_name) = @$row;
        my $key = "${url}_${user_name}";
        
        $webmarks{$key} = {
            LINK => $url,
            TEXT => $title,
            DATE => $date_added,
            ID => $user_name,
        };
    }
    
    $dbh->disconnect() 
        or log_message("Warning: Database disconnect failed: $DBI::errstr");
}

sub resolve_user_id {
    my ($user_name, $dbh) = @_;
    
    chomp($user_name);

    return DEFAULT_USER_ID unless $user_name;
    
    return $user_table{$user_name} if exists $user_table{$user_name};
    
    my ($user_id) = $dbh->selectrow_array(
        "SELECT user_id FROM WM_USER WHERE user_name = ?",
        {},
        $user_name
    );
    
    if (defined $user_id && $user_id !~ /^\s*$/) {
        $user_table{$user_name} = $user_id;
        return $user_id;
    }
    
    return DEFAULT_USER_ID;
}

sub insert_remote_bookmarks {
    log_message("Inserting new bookmarks from remote host");
    
    my $dbh = get_db_connection();
    my $insert_count = 0;
    
    foreach my $net_key (keys %net_webmarks) {
        # Skip if bookmark already exists locally
        next if exists $webmarks{$net_key};
        
        my $bookmark = $net_webmarks{$net_key};
        my $user_id = resolve_user_id($bookmark->{ID}, $dbh);
        
        if ($user_id eq DEFAULT_USER_ID) {

            log_message("Creating local user  for: $bookmark->{ID}");
            if (create_local_user($bookmark->{ID}, $dbh))
            {
                $user_id = $bookmark->{ID};
            }
            else
            {
                log_message("DB Failed to create local id  for: $bookmark->{ID}");
                next;
            }
            #log_message("Skipping bookmark - no matching user for: $bookmark->{ID}");
            #next;
        }
        
        eval {

            # Insert into WM_PLACE
            $dbh->do(
                "INSERT INTO WM_PLACE (URL, TITLE) VALUES (?,?)",
                {},
                $bookmark->{LINK}, $bookmark->{TEXT}
            );

            my $place_id = $dbh->last_insert_id;

            # Insert into WM_BOOKMARK
            $dbh->do(
                "INSERT INTO WM_BOOKMARK (PLACE_ID, TITLE, DATEADDED, USER_ID) VALUES (?,?,?,?)",
                {},
                $place_id, $bookmark->{TEXT}, $bookmark->{DATE}, $user_id
            );
            
            $insert_count++;
        };
        
        if ($@) {
            log_message("Error inserting bookmark: $@");
        }
    }
    
    log_message("Inserted $insert_count new bookmarks");
    $dbh->disconnect() 
        or log_message("Warning: Database disconnect failed: $DBI::errstr");
}

sub create_local_user 
{
    my ($user_name,$local_dbh) = @_;

    my $default_pw = $config->{defaultPass};

    my $user_create_sql = qq@ 
                    insert into wm_user (user_name,user_id,user_passwd) values (?,?,?)
                    @;
                    
    eval {
         $local_dbh->do($user_create_sql, {}, $user_name, $user_name,$default_pw);
    };
                                    
    if ($@)
    {
        log_message("------------- error creating user $user_name $@ -----------------");
        return 0;
    }       
    else    
    {       
        log_message("-------- created $user_name successfully in local db ---------------");
        return 1;
    }

}

#----------------------------------------------------------#
# Network Functions
#----------------------------------------------------------#

sub create_socket_connection {
    my $socket = IO::Socket::INET->new(
        PeerAddr => $config->{remoteHost},
        PeerPort => $config->{remotePortOther},
        Proto => 'tcp',
        Type => SOCK_STREAM,
        Timeout => $config->{timeOut},
    ) or die "Cannot connect to $config->{remoteHost}:$config->{remotePortOther}: $@\n";
    
    $socket->autoflush(1);
    return $socket;
}

sub build_send_message {
    my $message = '';
    
    foreach my $key (keys %webmarks) {
        my $bm = $webmarks{$key};
        $message .= join("\t", 
            $bm->{LINK} // '',
            $bm->{DATE} // '',
            $bm->{TEXT} // '',
            $bm->{ID} // ''
        ) . "\n";
    }
    
    $message .= END_DATA_TOKEN . "\n";
    return encode('UTF-8', $message);
}

sub send_bookmarks {
    my ($socket) = @_;
    
    my $message = build_send_message();
    log_message("Sending " . length($message) . " bytes to server");
    
    $socket->send($message) 
        or die "Cannot send to server: $!\n";
}

sub receive_bookmarks {
    my ($socket) = @_;
    
    log_message("Receiving bookmarks from server");
    
    $socket->timeout(5000);
    
    my $buffer = '';
    my $prev_chunk = '';
    my $done = 0;
    
    while (!$done) {
        my $chunk = '';
        my $bytes_received = $socket->recv($chunk, $config->{bufferSize});
        
        last unless defined $bytes_received && length($chunk) > 0;
        
        my $decoded_chunk = decode('UTF-8', $chunk);
        $buffer .= $decoded_chunk;
        
        # Check for end token across buffer boundaries
        my $cross_buffer = $prev_chunk . $decoded_chunk;
        $done = 1 if $cross_buffer =~ /@{[END_DATA_TOKEN]}/;
        
        $prev_chunk = $decoded_chunk;
    }
    
    log_message("Received " . length($buffer) . " bytes from server");
    return $buffer;
}

sub parse_received_bookmarks {
    my ($buffer) = @_;
    
    %net_webmarks = ();  # Clear existing data
    
    foreach my $line (split /\n/, $buffer) {
        last if $line =~ /@{[END_DATA_TOKEN]}/;
        
        my @fields = split /\t+/, $line;
        next unless $fields[0];  # Skip if no URL
        
        $fields[0] =~ s/\s*\t*\n*//g;  # Clean up URL
        
        my ($url, $date, $text, $user_id) = @fields;
        my $key = "${url}_${user_id}";
        
        $net_webmarks{$key} = {
            LINK => $url // '',
            DATE => $date // '',
            TEXT => $text // '',
            ID => $user_id // '',
        };
    }
    
    log_message("Parsed " . scalar(keys %net_webmarks) . " remote bookmarks");
}

#----------------------------------------------------------#
# Main Synchronization Loop
#----------------------------------------------------------#

sub run_sync_cycle {
    log_separator('=', "Start sync cycle: " . get_timestamp());
    
    #1 Reload configuration
    #2 Query local database
    #3 Connect to remote server
    #4 Send local bookmarks
    #5 Receive remote bookmarks
    #6 Parse received data
    #7 Insert new bookmarks
    #8 Cleanup
    #--------------------------

    #1
    mark_init::read_config();   
    #2  
    query_local_bookmarks();    
    #3 
    my $socket = create_socket_connection(); 
    #4 
    send_bookmarks($socket);    
    #5 
    my $buffer = receive_bookmarks($socket); 
    #6 
    parse_received_bookmarks($buffer);  
    #7
    insert_remote_bookmarks();          
    #8 
    $socket->close();       
    
    log_separator('=', "End sync cycle: " . get_timestamp());
}

#----------------------------------------------------------#
# Main Program
#----------------------------------------------------------#

log_message("Webmarks synchronization client started");

my $run_count = 0;
my $max_runs = $config->{runs};

while (1) {
    eval {
        run_sync_cycle();
    };
    
    if ($@) {
        log_message("Error during sync cycle: $@");
    }
    
    $run_count++;
    log_message("Completed run $run_count of $max_runs");
    
    last if $run_count >= $max_runs;
    
    sleep($config->{sleepInterval});
}

log_message("Webmarks synchronization client exiting after $run_count runs");
close($log_fh) or warn "Problems closing log file: $!";

__END__

=head1 NAME

wmOtherClient.pl - Webmarks synchronization client

=head1 SYNOPSIS

    perl wmOtherClient.pl [options]

    Options:
        --trace=LEVEL       Enable DBI tracing at specified level
        --tracefile=FILE    Write trace output to file
        --debug             Enable debug mode

=head1 DESCRIPTION

This client synchronizes bookmarks between a local database and a remote server.
It queries the local database, sends bookmarks to the remote server, receives
remote bookmarks, and inserts new ones into the local database.

=cut
