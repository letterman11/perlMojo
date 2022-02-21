our $hist_sql_all_str = "select b.url, a.title, a.dateAdded from WM_BOOKMARK a, WM_PLACE b where a.PLACE_ID = b.PLACE_ID  and a.USER_ID = ? "; 

sub gen_histogram
{
	my $userID = shift;
	my %markHist = ();
	my %elimdups = ();
	my @histo_list = ();	
	my ($title,$url,$dateAdded) = (1,0,2);

	### error checking ????? ##############
#	my $dbg = DbGlob->new();
#	$dbh = $dbg->connect();
	my $sth = $::dbh->prepare($hist_sql_all_str);
	#my $sth = $dbh->prepare($hist_sql_all_str);
	$sth->bind_param(1,$userID);
	$sth->execute();
	my $data_refs = $sth->fetchall_arrayref;
	my $row_count = $sth->rows;
	### error checking ????? ##############
	
	foreach (@{$data_refs})			
	{
		next if not defined($_->[$title]); 
	        next if $_->[$title] =~ /^\s*$/;

		if(exists($elimdups{$_->[$title]}))
		{
			$elimdups{$_->[$title]}->{url} = $_->[$url];	
			$elimdups{$_->[$title]}->{dateAdded} = $_->[$dateAdded];	
		}
		else
		{
			$elimdups{uc $_->[$title]} = { url => $_->[$url], 
					dateAdded => $_->[$dateAdded] };
		}		
	}	

	foreach (keys %elimdups)
	{
		my @words = split /(?:\s+)/, $_, -1;

		foreach (@words)
		{
			next if /(?:(\ba\b)|(\bfrom\b)|(\byour\b)|(\bHow\b)|(\bBE\b)|(\bas\b)
			|(\bthe\b)|(\bby\b)|(\bon\b)|(\band\b)|(\bis\b)|(\bFor\b)|(\bwith\b)
			|(\bIn\b)|(\bto\b)|(\bof\b)|(\b(\s+)\b)|(-|\+)|(\|)|[&\-:><'#])/i;

			next if /\b[[:cntrl:]]+\b/;
			next if not /[\x00-\x7f]/;
			next if length($_) < 3 and $_ =~ /\d/;
	
			s/\s+$//g;
			s/^\s+//g;

			if (exists($markHist{$_}))
			{
				$markHist{$_}->{count}++;
			}
			else
			{
				$markHist{$_} = { count => 1 };
			}

		}

	}
      
       my @markHistHiLo = 
       map { $_->[0] }
       sort { $b->[1] <=> $a->[1] } 
       map { [ $_, $markHist{$_}->{count} ] }
       keys %markHist;

 return @markHistHiLo;

}

sub gen_optionListDiv
{
   my $userID = shift;
   my @H = gen_histogram($userID);

   my $str0;
   my $str1;
   my $str2;
   my $str3;

   $str0 .= qq#\n\t<option value=" "> </option>#;
   $str1 .= qq#\n\t<option value=" "> </option>#;
   $str2 .= qq#\n\t<option value=" "> </option>#;
   $str3 .= qq#\n\t<option value=" "> </option>#;

   for my $option (@H[0..14])
   {
       $option =~ s/\|/ /g; 
       $str0 .= qq#\n\t<option value="$option"> $option</option>#;
   }

   map {  
           $_ =~ s/\|/ /g; 
	   $str1 .= qq#\n\t<option value="$_"> $_</option>#; 
   									} @H[15..29];
   map {  
           $_ =~ s/\|/ /g; 
	   $str2 .= qq#\n\t<option value="$_"> $_</option>#; 
   										} @H[30..44];

   map {  
           $_ =~ s/\|/ /g; 
	   $str3 .= qq#\n\t<option value="$_"> $_</option>#; 
   										} @H[45..59];

   my $out_hist_opts = <<"OPTION_TABLE";
       <div style="display:inline-block" id="optionDiv">
       <form>
      <select  onchange="topOpToSearch(this.options[this.options.selectedIndex].text);" id="topOptionID" name="topOption">
  <!--       <select  onblur="topOpToSearch(this.options[this.options.selectedIndex].text);" id="topOptionID" name="topOption"> -->
          $str0 
       </select>
      <select  onchange="topOpToSearch(this.options[this.options.selectedIndex].text);" id="topOptionID" name="topOption">
          $str1 
       </select>
      <select  onchange="topOpToSearch(this.options[this.options.selectedIndex].text);" id="topOptionID" name="topOption">
          $str2 
       </select>
      <select  onchange="topOpToSearch(this.options[this.options.selectedIndex].text);" id="topOptionID" name="topOption">
          $str3 
       </select>

       </form>
       </div>
OPTION_TABLE
   return $out_hist_opts; 
}


