#!/bin/sh
dbid=$1
DIR=$2
topdir=$DIR/toptemp
pythonedir=/home/zxc/xuanyuan/python/
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
export LC_TIME="POSIX"
dtoday=`date +"%Y%m%d"`
dHold=`date +"%Y%m%d%H"`
if [ ! -d $topdir ]
then
	mkdir $topdir
fi
while true
do
	dH=`date +"%Y%m%d%H"`
	time=`date +"%Y%m%d%H%M%S"`
	timenowUTC=`date +%s`
	ds=`date +"%Y%m%d%H%M%S"`
	dutc=`date +%s`
	if [ X$dH != X$dHold ]
	then
		mv $topdir/top.log $topdir/top.log.$dH
	fi
	top -b -n 1|awk -v dbid="$dbid" -v time="$time" -v timenowUTC="$timenowUTC" -v OFS="|" '{$1=$1;print dbid,time,timenowUTC,$0}'|head -30>$topdir/top.$ds 
	sleep 1
	head -22 $topdir/top.$ds | sed "1,7d" >>$topdir/top.log
	rm $topdir/top.$ds 
	dHold=$dH
done
