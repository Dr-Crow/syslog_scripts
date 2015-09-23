#!/usr/bin/perl
# 2014.11.14 filtered out "refused connect" because it's now boring Ericw
use File::Tail;

#
# set some variables
#
$COUNTER=0;
$print_flag=1;
$MESSAGES="/data/rsyslog/messages";
$IGNORE_FILE="/data/rsyslog/ignore.txt";

#
# Load ignore.txt
#
open (FILE, $IGNORE_FILE) || die "Can not read $IGNORE_FILE, exiting.\n";
print "Loading lines to ignore from $IGNORE_FILE\n";
while (<FILE>){
	print ".";
	chomp;
	$ignore_line{$_}+=1;
}
close (FILE);
print "\n";

#
# Open and loop forever
#
if ( -f $MESSAGES ) {
	print "Watching file $MESSAGES now\n";
	tie *FH, "File::Tail", (name => $MESSAGES);
#	open (FH, $MESSAGES);

	while (<FH>) {
		#print "DEBUG $_";
		$_ =~ s/©//;
		chomp;
		foreach $line (keys %ignore_line){
        		if ($_ =~ /\Q$line\E/){
				#print "MATCH STRING is $line\n";
                		#print "HIT on $_.\n\n";
				$print_flag=0;
				last;
        		}
		}
		if (/refused connect/){
				$print_flag=0;
		}
		if ($print_flag){
			print "$_\n";
		}
		$print_flag=1;
	}
}
else {
	print "File $MESSAGES not found\n";
}
