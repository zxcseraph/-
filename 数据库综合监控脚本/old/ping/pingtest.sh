#!/bin/sh
#dbid=$1
DIR=`pwd`
pingip=$1
checkdir=$DIR/checktemp
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
export LC_TIME="POSIX"
dtoday=`date +"%Y%m%d"`
hour2second=3600
if [ ! -d $checkdir ]
then
	mkdir $checkdir
fi
while true
do
	dt=`date +"%Y%m%d"`
	dH=`date +"%Y%m%d%H"`
	nohup ping $pingip -c $hour2second | awk '{ print $0"\t" strftime("%m-%d:%H:%M:%S",systime()) } ' > $checkdir/check_ping.$dH.temp &
	sleep $hour2second
	grep -v "bytes of data" $checkdir/check_ping.$dH.temp >> $checkdir/check_ping.log.$dH
	rm $checkdir/check_ping.$dH.temp
done