package GenMarks;

use strict;
use POSIX qw(strftime);
use Error;

sub new
{
   my $class = shift;
   my $self = {};
   $self->{TAB} = shift;
   $self->{DATAREFS} = shift; 
   $self->{ROWCOUNT} = shift;
   $self->{ERROROBJ} = shift if @_; 
  
   #print STDERR $self->{ROWCOUNT};
  
   bless ($self,$class);

}

sub genPage
{
   my $self = shift;
   my $user_name = shift;
   my $sort_crit = shift;
   my %tabMap =  %{shift()};
   my $tab = $self->{TAB};

   my ($sort_sp_ae,$sort_sp_fj,$sort_sp_kp,$sort_sp_qu,$sort_sp_vz,$sort_sp_date,$sort_sp_search) =  (" ") x 8; 
    
   my $sort_span_html_asc = "<span style=\"font-size:13pt; font-weight:bold\" id=\"sort_span\"> &uarr; </span>";
   my $sort_span_html_dsc = "<span style=\"font-size:13pt; font-weight:bold\" id=\"sort_span\"> &darr; </span>";

   #reverse hash again ?? why perl internals ??
   %tabMap = reverse %tabMap;    
   my $optionTops = &::gen_optionListDiv(); 

   if($sort_crit == 0)
   {
      SWITCH1: {
	if($tabMap{$tab} == 1) { $sort_sp_ae = $sort_span_html_asc; last SWITCH1; }
	if($tabMap{$tab} == 2) { $sort_sp_fj = $sort_span_html_asc; last SWITCH1; }
	if($tabMap{$tab} == 3) { $sort_sp_kp = $sort_span_html_asc; last SWITCH1; }
	if($tabMap{$tab} == 4) { $sort_sp_qu = $sort_span_html_asc; last SWITCH1; }
	if($tabMap{$tab} == 5) { $sort_sp_vz = $sort_span_html_asc; last SWITCH1; }
	if($tabMap{$tab} == 9) { $sort_sp_date = $sort_span_html_asc; last SWITCH1; }
	if($tabMap{$tab} == 6) { $sort_sp_search = $sort_span_html_asc; last SWITCH1; }
      }
	
   }
   elsif($sort_crit == 1)
   {
      SWITCH2: {
	if($tabMap{$tab} == 1) { $sort_sp_ae = $sort_span_html_dsc; last SWITCH2; }
	if($tabMap{$tab} == 2) { $sort_sp_fj = $sort_span_html_dsc; last SWITCH2; }
	if($tabMap{$tab} == 3) { $sort_sp_kp = $sort_span_html_dsc; last SWITCH2; }
	if($tabMap{$tab} == 4) { $sort_sp_qu = $sort_span_html_dsc; last SWITCH2; }
	if($tabMap{$tab} == 5) { $sort_sp_vz = $sort_span_html_dsc; last SWITCH2; }
	if($tabMap{$tab} == 9) { $sort_sp_date = $sort_span_html_dsc; last SWITCH2; }
	if($tabMap{$tab} == 6) { $sort_sp_search = $sort_span_html_dsc; last SWITCH2; }
      }
   }

   my $pageOut = <<"OUT_HTML"; 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>

<title> WebMarks Application </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
<link rel="shortcut icon" href="/dcoda.net/gen_rsrc/dc.ico">
<link rel="icon" href="/dcoda.net/gen_rsrc/dc.ico">
<link rel="stylesheet" href="/webMarks/web_src/style.css" type="text/css">
<script type="text/javascript" src="/webMarks/web_src/common.js"> </script>
</head>

<body onLoad="getSearchTerms()">
<div id="main">
 <div id="header">
  <h1 class="left"> <a href="/webMarks"> WEBMARKS </a></h1>
  <!-- <h3>angus</h3> -->
  <a href="/dcoda.net"> <img class="banner_image" alt="dcoda logo" src="/dcoda.net/gen_rsrc/DCBANNER_CROP2_219_31_2.jpg" /> </a>
 </div>
<div class="tab_divs" id="$tab">
  <div class="tab_header">
    <span onclick="cgi_out('tab=1');" class="tab_spans" id="sp_AE"> A-E $sort_sp_ae </span>
    <span onclick="cgi_out('tab=2');" class="tab_spans" id="sp_FJ"> F-J $sort_sp_fj </span>
    <span onclick="cgi_out('tab=3');" class="tab_spans" id="sp_KP"> K-P $sort_sp_kp </span>
    <span onclick="cgi_out('tab=4');" class="tab_spans" id="sp_QU"> Q-U $sort_sp_qu </span>
    <span onclick="cgi_out('tab=5');" class="tab_spans" id="sp_VZ"> V-Z $sort_sp_vz </span>
    <span onclick="cgi_out('tab=9');" class="tab_spans" id="sp_DATE"> DATE $sort_sp_date </span>
<!--    <span class="tab_spans" id="sp_SRCH"> SEARCH </span>  -->
 <span onclick="cgi_out('tab=6');" class="tab_spans" id="sp_SRCH"> SEARCH $sort_sp_search </span>  
    <!-- <span class="tab_spans" id="sp_SRCH"> SEARCH </span> -->

  </div>
OUT_HTML

   $pageOut .= genTabTable($self,$sort_crit);
   $pageOut .= <<"OUT_HTML2";
   </div>

   <script language="Javascript" type="text/javascript">
    if (window.screen.width <= 640) {
       document.write( ' <div>  <span width="125px" style="font-size:13pt; font-weight:bold" id="searchTerms">  </span>  </div> ');
    } else {
     document.write( ' <div> <span width="125px" style="font-size:7pt; font-weight:bold" id="searchTerms">  </span>  </div> ');
   }
   </script>
   <div class="search_div">
     <form  name="search_form" class="search_form" method="POST" action="/cgi-bin/webMarks/cgi-bin/wm_app.cgi?req=search">
       <ul>
<li> Enter Search Term(s)  </li>
	<!-- <li style="padding-left:3px;"> OR <input name="searchtype" checked="true" type="radio"  value="OR">  AND <input name="searchtype" type="radio"  value="AND"> <input id="searchBx" name="searchbox" type="text" size="25"> title  <input id="searchBx2" name="searchbox2" type="text" size="25"> url  </li> -->
<!--	<li style="padding-left:3px;"> OR <input name="searchtype" checked="true" type="radio"  value="OR">  AND <input name="searchtype" type="radio"  value="AND"> </li> -->
 	 <li style="padding-left:3px;">  OR <input name="searchtype" type="radio"  value="OR"> AND <input name="searchtype" checked="true" type="radio"  value="AND"> COMBO <input name="searchtype" type="radio" value="COMBO"> </li>
    	<li style="position:absolute; top:20px; right:5px;"> <input onclick="setSearchTerms();" name="submit" type="submit" value="Search"> </li> $optionTops
<li style="padding-left:3px; width:100%"> <input id="searchBx" name="searchbox" type="text" size="25"> title  <input id="searchBx2" name="searchbox2" type="text" size="25"> url </li> 
       </ul>
     </form>
   </div>
  <div class="new_mark">
   <form name="newMark" id="new_mark" method="POST" action="/cgi-bin/webMarks/cgi-bin/wm_app.cgi?req=newMark">
    <ul>
    <!-- <li> Enter Title </li> -->
    <li> Enter Title <input name="mark_title" type="text" size="100"> </li>
   <!-- <li> Enter URL</li> -->
    <li>Enter URL  <input name="mark_url" type="text" size="100"> </li>
    <li> <input name="submit" type="submit" value="Submit"> </li>
    </ul>
   </form>
  </div>

  <div class="delta_pass">
   <form name="deltaPass" id="delta_pass" method="POST" action="/cgi-bin/webMarks/cgi-bin/wm_app.cgi?req=deltaPass">
    <ul>
    <li onclick="logOut();"> LOGOUT $user_name </li>
    <li> Change Pass Word ? </li>
    <li> Enter User Name </li>
    <li> <input name="user_name" type="text" size="25"> </li>
    <li> Enter Old Pass Word </li>
    <li> <input name="old_pass" type="password" size="25"> </li>
    <li> Enter New Pass Word </li>
    <li> <input name="user_pass" type="password" size="25"> </li>
    <li> <input name="submit" type="submit" value="Submit"> </li>
    </ul>
   </form>
  </div>


 </div>
</body>
</html>
OUT_HTML2

   print ::header unless $::NO_HEADER == 1;
   print $pageOut;

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


sub genPage2
{
   my $self = shift;
   my $tab = $self->{TAB};

   my $pageOut = <<"OUT_HTML";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>

<title> WebMarks Application </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<link rel="shortcut icon" href="/dcoda.net/gen_rsrc/dc.ico">
<link rel="icon" href="/dcoda.net/gen_rsrc/dc.ico">
<link rel="stylesheet" href="/webMarks/web_src/style.css" type="text/css">
</head>

<body>
<div id="main">
 <div id="header">
  <h1 class="left"> <a href="/webMarks"> WEBMARKS </a></h1>
  <a href="/dcoda.net"> <img class="banner_image" alt="dcoda logo" src="/dcoda.net/gen_rsrc/DCBANNER_CROP2_219_31_2.jpg" /> </a>
 </div>
OUT_HTML


}

sub genTabTable
{
   my $self = shift;
   my $sort_crit = shift;
   my ($url,$title,$added) = (0,1,2);
   my $tbl;
   my $tbl_row;
   my $row_color;
   my $i;
   my $alt;
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


   $tbl = qq# "<table class=\"tab_table\">\n"
   	 "<col width=\"50%\">\n"
   	 "<col width=\"35%\">\n"
   	 "<col width=\"auto\">\n"
   	 "<tr class=\"header_row\"><th>Title</th><th>LINK</th><th style=\"background:red\" onClick=\"cgi_out('tab=11');\"> Date Added $sort_sp_dt </th></tr>\n";
	#;

  ## POTENTIAL ERROR SECTION ##
  if(defined($self->{ERROROBJ}))
  {
      $tbl .= $self->genError();
  } 
  
  ## POTENTIAL ERROR SECTION ##
   for my $row (@{$self->{DATAREFS}}) 
   {
       ($url,$title,$added) = @$row;

       $added = convertTime($added);

       $alt =  (++$i % 2 ? 1 : 2);   
       $row_color = "row_color" . $alt;
       $tbl_row .= "<tr class=\"$row_color\">" 
		     .	" <td class=\"title_cell\"> <a href=\"$url\" target=\"_blank\">  $title </a> </td>"
		     .	" <td class=\"url_cell\">  $url </td>"
		     .	" <td class=\"date_cell\">  $added </td>"
		     .  " </tr> \n";
   } 

   $tbl .= $tbl_row if(defined($tbl_row));
   $tbl .= "</table>\n";

   return $tbl; 
}

sub genTabDivs
{
   my $tab = shift;
   my $pageOut = <<"OUT_HTML";
<div class="tab_divs" id="$tab">
  <div class="tab_header">
    <span onclick="document.location = '/cgi-bin/webMarks/cgi-bin/wm_app.cgi?tab=0';" class="tab_spans" id="sp_AE"> A-E </span>
    <span onclick="document.location = '/cgi-bin/webMarks/cgi-bin/wm_app.cgi?tab=1';" class="tab_spans" id="sp_FJ"> F-J </span>
    <span onclick="document.location = '/cgi-bin/webMarks/cgi-bin/wm_app.cgi?tab=2';" class="tab_spans" id="sp_KP"> K-P </span>
    <span onclick="document.location = '/cgi-bin/webMarks/cgi-bin/wm_app.cgi?tab=3';" class="tab_spans" id="sp_QU"> Q-U </span>
    <span onclick="document.location = '/cgi-bin/webMarks/cgi-bin/wm_app.cgi?tab=4';" class="tab_spans" id="sp_VZ"> V-Z </span>
    <span onclick="document.location = '/cgi-bin/webMarks/cgi-bin/wm_app.cgi?tab=4';" class="tab_spans" id="sp_VZ"> V-Z </span>
  </div>
OUT_HTML

}

sub convertTime
{
   my $microsecs_epoch = shift;
   my $unixsecs_epoch = $microsecs_epoch / (1000 * 1000);
   strftime("%m-%d-%Y %H:%M:%S", localtime($unixsecs_epoch));
}

sub genDefaultPage
{

   my $self = shift;
   my $Obj = shift;
   my $tab = $self->{TAB};
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
 
   my $pageOut = <<"OUT_HTML"; 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>

<title> WebMarks Application </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
<link rel="shortcut icon" href="/dcoda.net/gen_rsrc/dc.ico">
<link rel="icon" href="/dcoda.net/gen_rsrc/dc.ico">
<link rel="stylesheet" href="/webMarks/web_src/style.css" type="text/css">
</head>

<body>
<div id="main">
 <div id="header">
  <h1 class="left"> <a href="/webMarks"> WEBMARKS </a></h1>
  <a href="/dcoda.net"> <img class="banner_image" alt="dcoda logo" src="/dcoda.net/gen_rsrc/DCBANNER_CROP2_219_31_2.jpg" /> </a>
 </div>
 <div class="landing">
     <form name="credentials" class="credentials" method="POST" action="/cgi-bin/webMarks/cgi-bin/wm_app.cgi?req=auth">
       <ul>
	<li style="font-size:30px; padding-bottom:10px;"> ENTER CREDENTIALS </li>
	<li style="font-size:24px;"> USER NAME: <input name="user_name" type="text"> </li>
	<li style="font-size:24px;"> PASSWORD: <input name="user_pass" type="password"> </li>
	<li style="padding:10px 0px 0px 5px;font-size:12px;"> Not Registered ? 
		<a style="text-decoration:underline" onclick="document.location = '/cgi-bin/webMarks/cgi-bin/wm_app.cgi?req=reg' "> Register </a> </li>
	<li style="float:right; font-size:18px; color:$colorStyle;"> $displayText </li>
	<li style="position:absolute; top:140px; right:5px; padding-top:30px; padding-left:10px;"> <input name="submit" type="submit" value="Submit" style="font-size:10pt;"> </li>
       </ul>
     </form>
 </div>
 </div>
</body>
</html>

OUT_HTML
    print ::header;
    print $pageOut;

}

sub genRegistration
{

   my $self = shift;
   my $errObj = shift if @_;
   my $errText;
   my $tab = $self->{TAB};

   #checks....
   if(ref $errObj eq 'Error')
   {
       $errText = $errObj->errText();
   } 

   $errText = $errText ||  " ";  

   my $pageOut = <<"OUT_HTML"; 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>

<title> WebMarks Application </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
<link rel="shortcut icon" href="/dcoda.net/gen_rsrc/dc.ico">
<link rel="icon" href="/dcoda.net/gen_rsrc/dc.ico">
<link rel="stylesheet" href="/webMarks/web_src/style.css" type="text/css">
</head>

<body>
<div id="main">
 <div id="header">
  <h1 class="left"> <a href="/dcoda.net/webMarks"> WEBMARKS </a></h1>
  <a href="/dcoda.net"> <img class="banner_image" alt="dcoda logo" src="/dcoda.net/gen_rsrc/DCBANNER_CROP2_219_31_2.jpg" /> </a>
 </div>
 <div class="registration">
     <form name="registration"  method="POST" action="/cgi-bin/webMarks/cgi-bin/wm_app.cgi?req=regAuth">
       <ul>
	<li style="font-size:30px; padding-bottom:10px;"> REGISTER </li>
	<li> ENTER USER NAME: <input name="user_name" type="text"> </li>
	<li> ENTER PASSWORD: <input name="new_user_pass1" type="password"> </li>
	<li> RENTER PASSWORD: <input name="new_user_pass2" type="password"> </li>
	<li> ENTER EMAIL ADDRESS: <input name="email_address" type="text"> </li>
	<li style="font-size:18px; color:red"> $errText  </li>
	<li style="position:absolute; top:175px; right:5px; font-size:24px; padding-top:10px; padding-left:10px;"> <input name="submit" type="submit" value="Submit" style="font-size:10pt"> </li>
       </ul>
     </form>
 </div>
 </div>
</body>
</html>

OUT_HTML
    print ::header;
    print $pageOut;

}

1;
