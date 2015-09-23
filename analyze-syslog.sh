#!/bin/sh
#
# Written by:         Eric Wedaa
# Last Modified Date: 2014-07-22
#
# This script assumes old syslog files are named syslog.log-some_date
# for instance, "syslog.log-20140625"
#
# This script assumes that each host has it's own subdirectory
# in $datapath

# Set this variable to where rsyslog is storing it's files
datapath=/data/rsyslog

hostname=`hostname`
# Edit the next two strings as appropriate
echo "This file is from /data/rsyslog/analyze-syslog.sh which is probably "
echo "being run from $hostname:/etc/logrotate.d/rsyslog"

######################################################################
#
# Process Arguments and show help
#
######################################################################
SYSLOG_FILE_NAME="syslog.log"
DO_ALL="Just syslog.log"
if [ "x$1" = "x-all" ] ; then
	SYSLOG_FILE_NAME='syslog.log*'
	DO_ALL="DO_ALL"
fi


# No more edits required after this :-)

if [ -d $datapath ] ; then
	cd $datapath
else
	echo "Can't cd to $datapath, something is bad"
	echo "Exiting now"
	echo ""
	exit 1
fi

echo ""
echo "#######################################################################"
echo "Information about syslog files"
echo ""
echo -n "Number of syslog files larger than one byte: "
find . -maxdepth 2 -type f -name $SYSLOG_FILE_NAME -size +1b|wc -l
#echo "Sample files are:"
#find . -type f -name $SYSLOG_FILE_NAME -size +1b|xargs ls -l |head -2

echo ""
echo "Hosts with 0 length syslog.log files"
find . -maxdepth 2 -type f -name 'syslog.log' -size 0 |grep -v OLD-HOSTS|xargs -L 1 dirname |sed 's/^.\///'

echo ""
echo "Hosts without DNS reverse lookup"
find . -maxdepth 2 -type d |grep -v OLD-HOSTS |grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'


echo ""
echo -n "Approximate Number of gigs of email sent by HOSTNAME: "
egrep size=  HOSTNAME?.example.com/syslog.log |grep -v cache| awk '{print $9}' |   \
tr "," "+" | tr -cd '[:digit:][=+=]' | sed 's/^/(/;s/+$/)\/1048576\n/' |bc

echo -n "Approximate Number of gigs of email sent by HOSTNAME2: "
egrep size= HOSTNAME2/syslog.log |grep size |grep -v cache| awk '{print $6}' |   \
tr "," "+" | tr -cd '[:digit:][=+=]' | sed 's/^/(/;s/+$/)\/1048576\n/' |bc

echo ""


# This doesn't work because some files may only be update rarely
# during the day and may not be found in a find command.
# I have to figure out how to get the file extension for yesterday
# and for two days ago.
#echo ""
#echo -n "Number of syslog files from two days ago larger than one byte: "
#find . -type f -mtime +1 -mtime -2 -name 'syslog.log-*' -size +1b|wc -l
#echo "Sample file names are:"
#find . -type f -mtime +1 -mtime -2 -name 'syslog.log-*' -size +1b|head -2

#
# I need to do something with the bootp, shh, unix_chkpwd, and sudo log entries 
# besides tossing them into /dev/null
#

# LC_ALL=C is magic that speeds up searches of text files
# http://www.inmotionhosting.com/support/website/ssh/speed-up-grep-searches-with-lc-all
LC_ALL=C

echo ""
echo "#######################################################################"
echo "General errors, excluding bootp, ssh, unix_chkpwd, su, and sudo (No lines is good)."
echo ""
echo "  Count Line"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep -F -v -f ignore.txt |egrep -vf ignore-expression.txt |sort |uniq -c |sort -n |egrep -v bootp\|ssh\|unix_chkpwd\|sudo\|su\:\|'configured GET variable value length limit exceeded'\|': imuxsock lost '


echo ""
echo "#######################################################################"
echo "configured GET variable value length limit exceeded errors (No lines is good)."
echo ""
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep -F -v -f ignore.txt |egrep -vf ignore-expression.txt |sort |uniq -c |sort -n |egrep -v bootp\|ssh\|unix_chkpwd\|sudo|grep 'configured GET variable value length limit exceeded' |wc -l


echo ""
echo "#######################################################################"
echo "Sudo Stuff"
echo ""
echo "  Count Line"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep -F -v -f ignore.txt |egrep -vf ignore-expression.txt |sort |uniq -c |sort -n |grep -v bootp |grep -v ssh|grep -v unix_chkpwd|grep  sudo

echo ""
echo "#######################################################################"
echo "ssh Stuff(Probably less interesting"
echo ""
echo "Count of POSSIBLE BREAK-IN ATTEMPT messages"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep  ssh |grep 'POSSIBLE BREAK-IN ATTEMPT' |wc -l

echo ""
echo "Count of Failed password for root from messages"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep  ssh |grep 'Failed password for root from' |wc -l

echo ""
echo "Count of failed login attempt for root messages(MIGHT be the same as above)"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep  ssh |grep 'failed login attempt for root' |wc -l

echo ""
echo "Count of sshd Invalid user and Failed password messages"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep  sshd |egrep 'Invalid user'\|'Failed password for' |wc -l

echo ""
echo "Count of refused connect from messages"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep  sshd |egrep 'refused connect from' |wc -l

echo ""
echo "Count of Accepted publickey for messages (Probably ok unless it's a huge number"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep  sshd |egrep 'Accepted publickey for' |egrep -v netezz\|omni |wc -l

echo ""
echo "Count of warning: can't verify hostname messages"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep  sshd |egrep can\'t\ verify\ hostname |wc -l

echo ""
echo "Other ssh events"
echo "  Count Line"
cat */$SYSLOG_FILE_NAME |/data/rsyslog/split-syslog-lines.pl  |grep -F -v -f ignore.txt |egrep -vf ignore-expression.txt |sort |uniq -c |sort -n |grep -v bootp |grep -v unix_chkpwd|grep  ssh |grep -v 'POSSIBLE BREAK-IN ATTEMPT' |grep -v 'Failed password for root from' |egrep -v 'Invalid user'\|'Failed password for'\|'failed login attempt for root'\|can\'t\ verify\ hostname\|'Accepted publickey for'\|'refused connect from'

if [ "X$DO_ALL" = "XDO_ALL" ] ; then
	echo "-all was set, skipping standard deviation report"
	exit
fi

echo ""
echo "#######################################################################"
echo "Check file sizes within one standard deviation"
echo ""
# Please note that this section uses the MOST time by far in this script
# Among other reasons is that it is doing a `wc -l` on ALL the existing 
# syslog.log-* files
# 
# It might be worth looking at this to see how I can cache wc -l output
# from one run to the next, and then just do a `wc -l` on the NEW files
# in the dirctory

original_pwd=`pwd`
for i in */syslog.log ; do
	path=`dirname $i`
	cd $path

	# the redirects below (2>/dev/null) just cleanup the output
	# when there are no "OLD" files
	Count_of_files_greater_than_0=`wc -l syslog.log-* 2>/dev/null |grep -v \ \ 0\ |grep -v total |wc -l 2>/dev/null`
	if [ $Count_of_files_greater_than_0 -lt 4 ] ; then
		echo "Not enough files in $path, skipping"
		cd $original_pwd
		continue
	fi
	# Can I do this faster with an awk script?
	#Total_number_of_lines=`wc -l syslog.log-* |grep -v \ \ 0\ |grep total |sed 's/ total//'`
	#Average_line_count=$[$Total_number_of_lines/$Count_of_files_greater_than_0]

	
	# Get the standard deviation
	
	# tail -n +2 | head -n -1 deletes the first and last lines on the 
	# assumption that they are outliers and I don't care about then
	# while I calculate the standard deviation
	#Line_counts=`wc -l syslog.log-* |grep -v \ \ 0\ |grep -v total|awk '{print $1}'|tail -n +2 | head -n -1`
	Line_counts=`for i in *gz; do gzip -dc $i |wc -l |grep -v \ \ 0\ |grep -v total|awk '{print $1}'; done`
	Average_line_count=$(
		echo "$Line_counts" |
		awk '{ s+=$1} END {print int(s/NR)}'
	)
	#echo "Average line count is $Average_line_count"

	standardDeviation=$(
	    echo "$Line_counts" |
	        awk '{sum+=$1; sumsq+=$1*$1}END{print int(sqrt(sumsq/NR - (sum/NR)**2))}'
	)
	
	Adjusted_average_line_count_lower_bound=$[$Average_line_count-$standardDeviation]
	Adjusted_average_line_count_upper_bound=$[$Average_line_count+$standardDeviation]
	Size_of_current_syslog=`wc -l syslog.log|sed 's/ syslog.log//'`

	if [ $Size_of_current_syslog -lt $Adjusted_average_line_count_lower_bound ] ; then
		echo "Warning: $path/syslog.log $1 ($Size_of_current_syslog lines) < than lower limit (1 Std Deviation of $standardDeviation)  of $Adjusted_average_line_count_lower_bound"
		cd $original_pwd
		continue
	fi
	
	if [ $Size_of_current_syslog -gt $Adjusted_average_line_count_upper_bound ] ; then
		echo "Warning: $path/syslog.log $1 ($Size_of_current_syslog lines) > than upper limit (1 Std Deviation of $standardDeviation)  of $Adjusted_average_line_count_upper_bound"
	fi
	
	cd $original_pwd
done
