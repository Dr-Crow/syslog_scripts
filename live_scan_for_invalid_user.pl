#!/usr/bin/perl
use File::Tail;

#
# set some variables
#
$COUNTER=0;
$ALERT_LEVEL=100;
$SYSLOG_LINES_GO_HERE="/data/rsyslog/breakin-attempts.txt";
$FILENAME="/data/rsyslog/messages";
$WAIT_TIME_IN_MINUTES=60;
$SEND_NEXT_EMAIL_AT_THIS_TIME=0; # This gets updated to current time 
                                 # after first email is sent
$EMAIL="adminteam\@example.com ";
$START_TIME=6;   # Start time to start sending emails (6:00 AM)
$END_TIME=18;    # Don't send email after this time (6:00 PM)

#
# Clear our temporary log file now
#
sub clear_email_message {
	$COUNTER=0;
	open (FILE, ">$SYSLOG_LINES_GO_HERE");
	print (FILE "This email came from ADD HOSTNAME HERE\n");
	print (FILE "It is scanning $FILENAME and alerts every $ALERT_LEVEL\n");
	print (FILE "times it sees an \"Invalid user\" line in the file and\n");
	print (FILE "will wait $WAIT_TIME_IN_MINUTES minutes before sending another alert.\n");
	print (FILE "\n");
	print (FILE "This program sends email between $START_TIME:00 and $END_TIME:00\n");
	print (FILE "This program is restarted by logwatch so a carefully timed\n");
	print (FILE "attack may not send a notification email.\n");
	close (FILE);
}

&clear_email_message;

#
# Open and loop forever
#
if ( -f $FILENAME ) {
	tie *FH, "File::Tail", (name => $FILENAME);
	while (<FH>) {
		if (/nessus.example.com/){next;}
		if (
			(/Invalid user/)||
			(/Failed keyboard-interactive\/pam for/)||
			(/User not known to the underlying authentication module/)||
			(/Too many authentication failures for/)||
			(/Failed password for root/)
		){
#print "DEBUG $_";
			open (FILE, ">>$SYSLOG_LINES_GO_HERE");
			print (FILE $_);
			close (FILE);
			$COUNTER++;
			if (($COUNTER >= $ALERT_LEVEL)&& 
				(time > $SEND_NEXT_EMAIL_AT_THIS_TIME)){
				#print "DEBUG Sending email now\n";
				$WHAT_HOUR_IS_THIS=`date +%H`;
				if ( ($WHAT_HOUR_IS_THIS >= $START_TIME)
					&& ($WHAT_HOUR_IS_THIS <= $END_TIME)){
						$DATE=`date +%Y.%m.%d`;
						`mailx -s "DANGER-POSSIBLE BREAK IN ATTEMPT" $EMAIL < $SYSLOG_LINES_GO_HERE `;
						`cp $SYSLOG_LINES_GO_HERE $SYSLOG_LINES_GO_HERE.$DATE`;
						&clear_email_message;
						$SEND_NEXT_EMAIL_AT_THIS_TIME=time+($WAIT_TIME_IN_MINUTES*60)
				}
			}
		}
	}
}
else {
	print "File $FILENAME not found\n";
}
