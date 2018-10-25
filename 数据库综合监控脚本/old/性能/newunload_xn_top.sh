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
	top -b -n 1|awk -v dbid="$dbid" -v time="$time" -v timenowUTC="$timenowUTC" -v OFS="|" '{$1=$1;print 0,dbid,time,timenowUTC,$0}'|head -30>$topdir/top.$ds 
	sleep 1
	head -22 $topdir/top.$ds | sed "1,7d" >> $topdir/xn_top.log.$ds.temp
	awk 'BEGIN{FS="|";OFS="|"} {if(length($16)!=0 && length($17)==0){print $0}}' $topdir/xn_top.log.$ds.temp >> $topdir/xn_top.log.$dH.temp
	rm $topdir/xn_top.log.$ds.temp
	rm $topdir/top.$ds
done
