#!/usr/bin/perl -w
use Term::ANSIColor qw(:constants);
use List::Util qw(sum);
$Term::ANSIColor::AUTORESET = 1;

$TILELEN=8;
my $ii = $ARGV[2] || 0.10;
my $Pr = $ARGV[3] || 1000;
my $sz=25;

sub binCoEff {

   my $x = shift;
   my @a = ();
   my $N= shift || 5;
   #push @a, [($x)],[($x,$x)];
   @a = ([($x)],[($x,$x)]);
   my @cF = ();
   my @sumCF;

   my @cF0 =  cfc($a[0],$ii);
   my $sumCF0 =  sum(@cF0);
   push @sumCF, $sumCF0;

   my @cF1 =  cfc($a[1],$ii);
   my $sumCF1 =  sum(@cF1); 
   push @sumCF, $sumCF1;

   for(my $i=2;$i<$N;$i++)
   {
      my $T = [];
      push @$T, $a[0]->[0];

      for(my $j=1;$j<$i;$j++)
      {
          push @$T, ($a[$i-1]->[$j-1] + $a[$i-1]->[$j]);
      }
      push @$T, $a[0]->[0];
      push @a, $T;
     
      @cF = cfc($T,$ii);
      my $sumCF = sum(@cF);
      push @sumCF, $sumCF;

   }

   pydprint2(\@a,\@sumCF);     
}

sub cfc  {
       my $T = shift;
       my $ii = shift;
       my @cF = ();
       my ($cF,$xp,$sumCF) = ();
       for my $ce (@$T)
       {
         $cF = $ce * $ii**$xp++;
         push @cF, $cF;
       }
       $sumCF = sum(@cF) ;
       return $sumCF;
}

sub pydprint2
{
   my $a = shift;
   my $sumCF = shift||1;
   my $tilelen = $TILELEN; 
   my $sp = " ";
   my $N;
   my @V = ();
   my $pydout;

   for my $p (@$a) {
       my @vv = ();
       for my $pp (@$p) {
           my $ltile = placeElonTile($pp);
           push @vv, $ltile;
       }
       push @V, [@vv];
   }
   $N = scalar(@V);
   my $nN=0;
   for my $oV (@V) {
       $N--;
       my $msp =   $sp x (($tilelen/2) * $N); 
       #print  ON_BRIGHT_YELLOW . $msp . length($msp) . RESET, "\n";
       if($N % 2 > 0? 1 : 0) {
       #$pydout .=  sprintf ("%-${sz}s%-${sz}s",  @$sumCF[$nN],  $Pr*@$sumCF[$nN++])  .  $msp . RESET ON_BRIGHT_YELLOW . join "",  @$oV;
       $pydout .=  sprintf ("%-${sz}s%-${sz}s",  @$sumCF[$nN],  $Pr*@$sumCF[$nN++])  .  $msp . RESET ON_YELLOW . join "",  @$oV;
       } else {
       $pydout .=  sprintf ("%-${sz}s%-${sz}s",  @$sumCF[$nN],  $Pr*@$sumCF[$nN++])  .  $msp . RESET ON_BRIGHT_GREEN . join "",  @$oV;
       }
       $pydout .=  $msp . "\n" ;
   }
   print $pydout;
}

sub placeElonTile 
{
   my $el = shift; 
   my $sp = " ";
   my ($fsp,$bsp);
   my ($realTile);
   my $tilelen = shift ||$TILELEN;
   my $exSp = $tilelen - length("$el");
   my $even = $exSp % 2 > 0 ? 0 : 1;

   if($even)
   {
      $fsp = $exSp/2;
      $bsp = $fsp;
   } else {
     $fsp = int($exSp/2);
     $bsp = $fsp +1;
   }

   $realTile =  $sp x $fsp;
   $realTile .= $el;
   $realTile .= $sp x $bsp;
   return $realTile;

}

    
binCoEff($ARGV[0] || 1,$ARGV[1] || 5);
