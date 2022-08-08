package GenMarksMojo;
use strict;

#require '/home/angus/perlProjects/MojoWebMarks/gen_histo_gram_multi.pl';


##TODO try to work out Mojo inheritance to get all needed methods => probably the app var/object
#otherwise mojo controller is an attribute of class
#@ISA = qw('Mojolicious::Controller');
#use Mojo::Base 'Mojolicious::Controller';

use POSIX qw(strftime);
use Error;

sub new
{
   my $self = {};
   my $class = shift;
   my $mojoc = shift;
   $self->{MC} = $mojoc;
   $self->{TAB} = shift;
   $self->{DATAREFS} = shift; 
   $self->{ROWCOUNT} = shift;
   $self->{ERROROBJ} = shift if @_; 
   print STDERR $self->{ROWCOUNT}, " rowcount \n";
   bless ($self,$class);
}

sub renderMainView
{

}

sub genPage
{
   my $class = shift;
   print STDERR  "$class->{MC} second CLASS \n";
	my $c = $class->{MC};
   #my $user_name = shift;
   my $user_id = shift;
   my $sort_crit = shift;
   my %tabMap =  %{shift()};
   my $tab = $class->{TAB};

   my $tabTable = $class->genTabTable($sort_crit);
   my $optionTops = &main::gen_optionListDiv($user_id); 

	#$c->stash(tabTable => $tabTable, sort_crit => $sort_crit, user_name => $user_id, tab => $tab, optionTops => $optionTops);
	$c->stash(tabTable => $tabTable, sort_crit => $sort_crit, user_name => $user_id, tab => $tab, optionTops => $optionTops);
	$c->render(template => 'class_mainview', format => 'html');
}

sub genError
{
   my $self = shift;
   my $errObj = $self->{ERROROBJ};
   my $errText = $errObj->errText(); 

   my $errOut = <<ERR_HTML;
<div>
  <ul>
   <li style="font-size:16px; color:red"> $errText  </li>
  </ul>
</div>
ERR_HTML
   
   return $errOut;

}

sub genTabTable
{
   my $self = shift;
   my $sort_crit = shift;
   my ($url,$title,$added) = (0,1,2);
   my $bk_id = 3;
   my $tbl;
   my $tbl_row;
   my $row_color;
   my $i;
   my $alt;
   my $tbl_row_header; 
   my $sort_sp_dt;

   my $sort_span_html_asc = "<span id=\"sort_span_date\">  &uarr; </span>";
   my $sort_span_html_dsc = "<span id=\"sort_span_date\">  &darr; </span>";

   if($sort_crit == 2)
   {
       $sort_sp_dt = $sort_span_html_asc;
   }
   elsif($sort_crit == 3)
   {
       $sort_sp_dt = $sort_span_html_dsc;
   }
   else
   {
       $sort_sp_dt = " ";
   }

   $tbl = qq# <table id="tab_table" class="tab_table">\n
     <col width="50%">\n
     <col width="35%">\n
     <col width="auto">\n
     <tr class="header_row"><th>Title</th><th>LINK</th><th style="background:red" onClick="cgi_out('tab=11');"> Date Added $sort_sp_dt </th></tr>\n
	#;

  ## POTENTIAL ERROR SECTION ##
  if(defined($self->{ERROROBJ}))
  {
      $tbl .= $self->genError();
  } 
  
  ## POTENTIAL ERROR SECTION ##
   for my $row (@{$self->{DATAREFS}}) 
   {
       ($url,$title,$added,$bk_id) = @$row;

       $added = convertTime($added);

       $alt =  (++$i % 2 ? 1 : 2);   
       $row_color = "row_color" . $alt;

       $tbl_row_header = " <th hidden>  $bk_id   </th> "; 

       $tbl_row .= qq# <tr class="$row_color"> 
                  $tbl_row_header 
		     	 <td class="title_cell"> <a href="$url" target="_blank">  $title </a> </td>
		     	 <td class="url_cell">  $url </td>
		     	 <td class="date_cell">  $added </td>
		        </tr> \n
				#;
   } 

   $tbl .= $tbl_row if(defined($tbl_row));
   $tbl .= "</table>\n";

   return $tbl; 
}

sub convertTime
{
   my $microsecs_epoch = shift;
   my $unixsecs_epoch = $microsecs_epoch / (1000 * 1000);
   strftime("%m-%d-%Y %H:%M:%S", localtime($unixsecs_epoch));
}

sub renderDefaultView()
{


}

sub genDefaultPage
{
	my $c = shift;
	my $user_name = $c->param('user_name');
	my $Obj = shift;
	my $tab = $c->{TAB};
	my $errText;
	my $succRegText;
	my $displayText; 
	my $colorStyle;

	if(ref $Obj eq 'Error')
	{
		$errText = $Obj->errText();
		$colorStyle = "red";
	}
	else
	{
       $succRegText = $Obj; 
       $colorStyle = "light-grey";
   }

   $displayText = $errText || $succRegText || " ";
	$c->stash(displayText => $displayText, colorStyle => $colorStyle, user_name => $user_name, tab => $tab);
	$c->render(template => 'class_defaultpage', format => 'html');
} 

sub renderRegistrationView
{


}

sub genRegistration
{

   my $c = shift;
   my $errObj = shift if @_;
   my $errText;
   my $tab = $c->{TAB};

   #checks....
   if(ref $errObj eq 'Error')
   {
       $errText = $errObj->errText();
   } 

   $errText = $errText ||  " ";  

	$c->stash(errText => $errText);
	$c->render(template => 'class_registration', format => 'html');
}


1;
