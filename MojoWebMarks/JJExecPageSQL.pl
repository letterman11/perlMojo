############################################
## Mojo Modified ExecPageSQL function 	#### 
## JJExecPageSQL			####
## standalone CGI function to be required ##
############################################
sub exec_page
{
	my $c = shift;
	my $user_id = $c->session('wmUserID');
    my $userID = $user_id;
	#my $user_id = shift;
	my $user_name = $c->session('wmUserName');
    my $sessionID = $c->session('wmSessionID');
	my $errObj = shift;
	my $tabtype = $c->param('tab') || $tabMap{tab_DATE};
	my $searchboxTitle = $c->param('searchbox');
	my $searchTypeBool = $c->param('searchtype');
	my $sort_crit = isset($c->param('sortCrit')) ? $c->param('sortCrit') : 1 ;
	my $searchboxURL = $c->param('searchbox2');
	my $ORDER_BY_CRIT;	
	my $sort_asc = 0;
	my $sort_desc = 1;
	my $sort_date_asc = 2;
	my $sort_date_desc = 3;
	my $storedSQLStr;
	my $sort_ord;	
	my $exec_sql_str;
	
	## Correct later
	if(ref $errObj ne 'Error') 
	{
		$NO_HEADER = $errObj;	
		$errObj = undef;
	}
#############################################################################
#Sort Criteria setting of ORDER_BY_CRITERIA
#############################################################################
	if($sort_crit == 0)
	{
		$ORDER_BY_CRIT = $ORDER_BY_TITLE;
		$sort_ord = ' asc ';	
	}
	elsif($sort_crit == 1)
	{
		$ORDER_BY_CRIT = $ORDER_BY_TITLE;
		$sort_ord = ' desc ';
	}
	elsif($sort_crit == 2)
	{
		$ORDER_BY_CRIT = $ORDER_BY_DATE;
		$sort_ord = ' asc ';
	}
	else
	{
		$ORDER_BY_CRIT = $ORDER_BY_DATE;
		$sort_ord = ' desc ';
	}
#############################################################################
#############################################################################
#=cut
##########################################################
# SearchBoxTitle + SearchBoxURL + AND/OR Radio Button
##########################################################
	if(($searchTypeBool eq "COMBO") && (isset($searchboxTitle)) && (isset($searchboxURL)))
	{
	    #exit
		my @queri = split /\s+/, $searchboxTitle, -1;
		my $qstr;
		if (@queri < 2)
		{
			$qstr = " a.title like '%$searchboxTitle%'  and b.url like '%$searchboxURL%' ";# $sort_ord;
			$exec_sql_str = $main_sql_str . $qstr . $ORDER_BY_DATE  .' desc '  ;# $sort_ord;
		}
		else
		{
			$qstr = " a.title like '%$queri[0]%' ";
			for (my $i = 1; $i <= $#queri; $i++)
			{
				if($searchTypeBool eq "OR")
				{
					$qstr .= " or a.title like '%$queri[$i]%' " ;
				}
				else
				{
					$qstr .= " and a.title like '%$queri[$i]%' " ;
				}
			}
		} 
		$exec_sql_str = $main_sql_str . $qstr  . " and b.url like '%$searchboxURL%' " . $ORDER_BY_DATE .  ' desc ' ;#$sort_ord;
        $storedSQLStr = $main_sql_str . $qstr ;

# File based         
#		storeSQL($storedSQLStr,$sessionID);
#########
		storeSQL2($storedSQLStr,$sessionID, $userID);
		$tabtype = $tabMap{tab_SRCH_TITLE};
	}
#=cut
	elsif(isset($searchboxTitle))
	{
          #$ORDER_BY_CRIT ;
		my @queri = split /\s+/, $searchboxTitle, -1;
		my $qstr;
		if (@queri < 2) 
		{
			$qstr = " a.title like '%$searchboxTitle%' ";# $sort_ord;
			$exec_sql_str = $main_sql_str . $qstr . $ORDER_BY_DATE  .' desc '  ;# $sort_ord;
		} 
		else 
		{
			$qstr = " a.title like '%$queri[0]%' ";
			for (my $i = 1; $i <= $#queri; $i++) 
			{
				if($searchTypeBool eq "AND") 
				{  
					$qstr .= " and a.title like '%$queri[$i]%' " ;
				}
				else   
				{ 
					$qstr .= " or a.title like '%$queri[$i]%' " ;
                }
            }
			$exec_sql_str = $main_sql_str . $qstr  . $ORDER_BY_DATE .  ' desc ' ;#$sort_ord;
		}

        $storedSQLStr = $main_sql_str . $qstr ;
        #storeSQL($storedSQLStr,$sessionID);
        storeSQL2($storedSQLStr,$sessionID, $userID);
        $tabtype = $tabMap{tab_SRCH_TITLE};

	}
      #elsif(defined($searchboxURL) && ($searchboxURL !~ /^\s*$/g))
	elsif(isset($searchboxURL))
	{

		my $qstr;
		$qstr = " b.url like '%$searchboxURL%' ";# $sort_ord;
		$exec_sql_str = $main_sql_str . $qstr . $ORDER_BY_DATE  .' desc '  ;# $sort_ord;

        $storedSQLStr = $main_sql_str . $qstr ;
       #storeSQL($storedSQLStr, $sessionID);

        storeSQL2($storedSQLStr, $sessionID, $userID);
        $tabtype = $tabMap{tab_SRCH_TITLE};
	}
##############################################################################################
# End of logic branches for SrcBoxTitle + SrchBoxURL + Radio Button
##############################################################################################
	else
	{
##############################
##for entry of tabs
#############################
	if($tabtype eq $tabMap{tab_AE}) 
	   {
	      $exec_sql_str = $main_sql_str . $AE_str . $ORDER_BY_CRIT . $sort_ord;
	   }
	   elsif($tabtype eq $tabMap{tab_FJ})
	   {
	      $exec_sql_str = $main_sql_str . $FJ_str . $ORDER_BY_CRIT . $sort_ord;
	   }
	   elsif($tabtype eq $tabMap{tab_KP})
	   {
	      $exec_sql_str = $main_sql_str . $KP_str . $ORDER_BY_CRIT . $sort_ord;
	   }
	   elsif($tabtype eq $tabMap{tab_QU})
        {
	      $exec_sql_str = $main_sql_str . $QU_str . $ORDER_BY_CRIT . $sort_ord;
        }
        elsif($tabtype eq $tabMap{tab_VZ})
	    {
	      $exec_sql_str = $main_sql_str . $VZ_str . $ORDER_BY_CRIT . $sort_ord;
	    }
	    elsif($tabtype eq $tabMap{tab_DATE})
	    {
#	      $date_sql_str .= $sort_ord . " limit 200 ";
	      $exec_sql_str = $date_sql_str . $sort_ord . "limit 200 ";
	    }
	    elsif($tabtype eq $tabMap{tab_SRCH_TITLE})
        {
           #$storedSQLStr = getStoredSQL($sessionID);
           $storedSQLStr = getStoredSQL2($sessionID);
        
            if (not isset($storedSQLStr))
            {
              $mojoMarks::moLog->error("NO Criteria set ");    
            } else {

	        $exec_sql_str = $storedSQLStr . $ORDER_BY_CRIT . $sort_ord;
           }
        }
###################################
##################################
    }

    my $executed_sql_str = ($tabtype ne $tabMap{tab_DATE}) ? $exec_sql_str : $date_sql_str . $sort_ord . " limit 200 ";

	print STDERR $executed_sql_str, "\n" if($DEBUG);

    my ($sth,$row_count,$data_refs,$genMarksMojo);

##########
# Start of Execution of SQL
#########

    $mojoMarks::moLog->error("Start Exec of SQL @" . __PACKAGE__ . "@  " . __LINE__ . " " .  $executed_sql_str , "\n");

    eval {
    	$sth = $::dbh->prepare($executed_sql_str);
    	$sth->bind_param(1,$user_id);
    	$sth->execute();
    };

	%tabMap = reverse %tabMap;

    if ($@) 
    {
        $mojoMarks::moLog->error("FAILED  Exec of SQL tabtype @" . tabtype . "@  " . __LINE__ . " " .  $executed_sql_str , "\n");
		#constructor args ->	#1,controller; #2,tabMap; #3,dataRows; #4,rowCount, #5,ErrObject
	   $genMarksMojo = GenMarksMojo->new($c,$tabMap{tabtype},undef,undef,Error->new(2000));	
	   #$genMarksMojo->genPage($user_name,$sort_crit,\%tabMap);
	   $genMarksMojo->genPage($user_id,$sort_crit,\%tabMap);
    }
	else
	{
      print STDERR "SUCCESS webMark SQL " . $executed_sql_str, "\n";
	   $data_refs = $sth->fetchall_arrayref;
	   $row_count = $sth->rows;
		print STDERR $row_count, " DB rowcount\n";
	
	   $genMarksMojo = GenMarksMojo->new($c,$tabMap{$tabtype},$data_refs,$row_count,$errObj);
	   #$genMarksMojo->genPage($user_name,$sort_crit,\%tabMap);
	   $genMarksMojo->genPage($user_id,$sort_crit,\%tabMap);
    }
############
# End of SQL Execution
###########
}

1;
