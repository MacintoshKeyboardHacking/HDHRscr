#!/bin/bash
FILE=$*
CMD=$0

cd /tmp/
cd /mnt/a/inactive/
if [ ! "$FILE" ]; then
	echo Main run, identify candidates.

	# old naming convention, taken directly from hdhomerun filesystem
	find . -type f -name "*.mpg"|grep -v "S00E00" | cut -d\[ -f1|rev|cut -b2-|rev|sort|uniq -d|awk {'print "'$CMD' \""$0"\""'}|bash -v

	# new naming convention, _deletespaces
	find /mnt/a/inactive -type f -name "*S[0-9][0-9]E[0-9][0-9]*mpg" | grep -v "S00E00" | sed -e "s/\(.*S[0-9][0-9]E[0-9][0-9]\).*/\1/" | sort|uniq -d|awk {'print "'$CMD' \""$0"\""'}|bash -v

	find /mnt/a/tsout -type f -name "*S[0-9][0-9]E[0-9][0-9]*ts" | grep -v "S00E00" | sed -e "s/\(.*S[0-9][0-9]E[0-9][0-9]\).*/\1/" | sort|uniq -d|awk {'print "'$CMD' \""$0"\""'}|bash -v

else
	if [ ! -f "$FILE.active" ]; then
		ls -S "$FILE"*.mpg "$FILE"*.ts |tail -n+2|xargs -d\\n echo remove

# WATCH OUT THE $FILE.active match was failing because trailing space....

		ls -S "$FILE"*.mpg "$FILE"*.ts |tail -n+2|xargs -d\\n rm
	else
		echo nope, $FILE still active
	fi
fi
#for tablo: find . -type f -name "*ts"|cut -d\@ -f2-|cut -d\- -f1|sort|uniq -d|awk {'print "ls -S */*@"$0"-*.ts |tail -n+2|xargs -d\\\\n rm"'}|bash -v
#more tablo: find . -type f -name "*@*-*.ts"|cut -d\@ -f1|grep -v S00E00 | sort|uniq -d|awk {'print "ls -S "$0"@*.ts |tail -n+2|xargs -d\\\\n rm"'}|bash -v
#find . -type f -name "*@*-*.ts"|cut -d\@ -f1|grep -v S0x0E00 | sort|uniq -d|awk {'print "ls -S \""$0"@\"*.ts |tail -n+2|xargs -d\\\\n rm"'}|bash
