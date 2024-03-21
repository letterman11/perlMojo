dt=$(date '+%F_%H-%M-%S')
echo ===========================
echo bookman.$dt.log archived
echo ===========================
mv bookman.log logs/bookman.$dt.log
#nohup perl wmOtherService.pl | tee -a bookman.log &
nohup /usr/bin/perl wmOtherService.pl >> bookman.log &
