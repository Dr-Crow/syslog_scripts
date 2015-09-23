README for Syslog_Scripts
==============

syslog_scripts are tools to sort information in a syslog file
into something a little more reasonable to read.

WARNING
--------------
No warrany of an kind :-)

Licensing
--------------
syslog_scripts are tools to sort information in a syslog file
into something a little more reasonable to read.

Copyright (C) 2015 Eric Wedaa

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

What Syslog_Scripts does
--------------

Installation
--------------

Installation is manual at the moment.

Please run 
```
  cpan File::Tail
```

Add this line to rc.local (or whatever is appropriate for your site)

```
  /data/rsyslog/live_scan_for_invalid_user.pl  &
```

Edit /etc/logrotate.d/syslog so it is similar to below

```
  /data/rsyslog/*/syslog.log
  /data/rsyslog/messages
  {
      rotate 9000
      daily
      sharedscripts
      compress
      delaycompress
      prerotate
    /usr/sbin/logwatch
    kill `ps -ef |grep -v grep |grep live_scan_for_invalid_user |awk '{print $2}'`
    /usr/sbin/logwatch --print > /data/rsyslog/logwatch.out
    cp /data/rsyslog/logwatch.out /data/rsyslog/logwatch.out-`date +%Y%m%d`
          /data/rsyslog/analyze-syslog.sh > /data/rsyslog/analyze.out
    cp /data/rsyslog/analyze.out /data/rsyslog/analyze.out-`date +%Y%m%d`
    cat /data/rsyslog/analyze.out | mailx -s "Syslog output" adminteam@example.com
    cat /data/rsyslog/logwatch.out | mailx -s "Logwatch output" adminteam@example.com
    chown root.apache /data/rsyslog/logwatch.out /data/rsyslog/logwatch.out-`date +%Y%m%d`
    chmod g+r /data/rsyslog/logwatch.out /data/rsyslog/logwatch.out-`date +%Y%m%d`
    chown root.apache /data/rsyslog/analyze.out /data/rsyslog/analyze.out-`date +%Y%m%d`
    chmod g+r  /data/rsyslog/analyze.out /data/rsyslog/analyze.out-`date +%Y%m%d`
      endscript
      postrotate
    /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
    /data/rsyslog/live_scan_for_invalid_user.pl  &
  
      endscript
  }
``` 
