#!/usr/bin/perl -s
while (<>){
	#$original_line=$_;
	#($date, $host, $line)=split(/ /,$_,3);
	($date, $line)=split(/ /,$_,2);
	#convert everything to normal ascii characters
	# This uses CPU, maybe unnecessarily
	#$line =~ s/[^[:ascii:]]//g;
	$line =~ tr/\040-\176/ /c;
	print ("$line\n");
}
