#!/bin/bash
#set -e


#DEBUG=DEBUG

OUTDIR="/a/out2/"
HOST=hdhomerun.localdomain
HTMP=/tmp/thd-`date +%s`
PRGM=$0


fail() {
	echo FAIL
	CLEAN="NO"
	exit 1
}


getSeries() {
	if [ $DEBUG ]; then echo "seriesURL:	$seriesURL"; fi

	rm -f /tmp/thd-clean
	while [ ! -f /tmp/thd-clean ]; do
		touch /tmp/thd-clean

		curl -sS --url $seriesURL |tr \{ \\n |sed \
			-e 's/.*EpisodeTitle":"\(.*\)",.*"ImageURL":\(.*jpg"\),.*Filename":"\(.*\)\( \[.*\).mpg","PlayURL":\(.*\),"CmdURL":\(.*\)}.*/touch "\3.active"; curl --limit-rate 4000000 --speed-limit 2000000 -C- -o "\3\4-\1.mpg" --url \5 ||exit 1; if [ ! -f "\3\4-\1.jpg" ]; then curl -sS -o "\3\4-\1.jpg" --url \2; exit 1; fi/g' \
			-e 's/.*"ImageURL":\(.*jpg"\),.*Filename":"\(.*\)\( \[.*\).mpg","PlayURL":\(.*\),"CmdURL":\(.*\)}.*/touch "\2.active"; curl --limit-rate 4000000 --speed-limit 2000000 -C- -o "\2\3.mpg" --url \4 ||exit 1; if [ ! -f "\2\3.jpg" ]; then curl -sS -o "\2\3.jpg" --url \1; exit 1; fi/g' |\
			tail -n+2 |sed -e "s/[']//g" |sort |\
			(while read -r episodeURL; do getEpisode ||rm -f /tmp/thd-clean; done)
	done

#	if [ -f /tmp/thd-done ]; then
	if ([ -f /tmp/thd-clean ] && [ -f /tmp/thd-done ]) ; then
		curl -sS --url $seriesURL |tr \{ \\n |cut -d\} -f1|tr \, \\n|grep CmdURL|sed -e "s/.*\:/curl -X POST --url \"http:/" -e "s/\"$/\&cmd=delete\&rerecord=1\"/"|tail -n+6|bash -v
		curl -X POST --url 'http://hdhomerun.localdomain/recording_events.post?sync'
	fi
	return 0
}


getEpisode() {
	if [ $DEBUG ]; then
		echo -n
		echo "debug_cmd:	$episodeURL"
#		return 1
	else
		echo $episodeURL |bash -v
		sleep 1
	fi
}


cd $OUTDIR ||fail
mkdir -p $OUTDIR/../inactive/

if [ ! $DEBUG ]; then
	if [ -f /tmp/thd-lock ]; then
		rm -f /tmp/thd-clean
		rm -f /tmp/thd-done
		fail
	else
		touch /tmp/thd-lock
	fi
fi

find . -maxdepth 1 -type f -name "*.active" -size 0 -print0|xargs -0 rm

if [ ! $* ]; then	# first pass, from the top...
	rm -f /tmp/thd-done
	while [ ! -f /tmp/thd-done ]; do
		touch /tmp/thd-done

		curl -sS --url http://$HOST/recorded_files.json -o $HTMP.top ||fail
		cat $HTMP.top |tr \{ \\n |\
			grep -v -e "PBS News" -e "Amanpour" -e "Frontline" -e "BBC News" -e "Colbert" -e "Sound of Music"|\
			sed -e 's/.*EpisodesURL":"\(.*\)",".*/\1/' |tail -n+2 |\
			(while read -r seriesURL; do getSeries ||rm -f /tmp/thd-done; done)
	done
else
	echo "NONO, this mode... not yet ($*)"
fi

if [ ! $DEBUG ]; then
	echo "curl -X POST --url \"http://hdhomerun.localdomain/recording_events.post?sync\"" bash -v
	find . -type f -name "*.mpg" |rev|cut -d\/ -f1|rev|sort|sed -e 's/\(.*\) \[.*/if [ ! -f "\1.active" ]; then mv -n "\1"* \.\.\/inactive\/; fi/'|bash -v
	rm /tmp/thd-lock $HTMP*
fi

#cat $HTMP.top | tr \{ \\n |sed -e "s/\",\"/\{/g" -e "s/,\"/\{/g" -e "s/\",/\{/g"
#cat $HTMP.top |sed -e 's/\",\"/\|/g' -e 's/},{/\|\|/g' -e 's/,\"/\|/g' |tr \| \\n 

#curl --url "$*" 2>/dev/null|tr \{ \\n|cut -d\} -f1|tr \, \\n|grep CmdURL|sed -e "s/.*\:/curl -X POST --url \"http:/" -e "s/\"$/\&cmd=delete\&rerecord=1\"/"|tail -n+6| bash -v
#curl -sS --url http://hdhomerun.localdomain/recorded_files.json?SeriesID=C20016223EN73MO | tr \{ \\n |
