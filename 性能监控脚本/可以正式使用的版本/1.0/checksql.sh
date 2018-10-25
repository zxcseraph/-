#!/bin/sh
#dbid=$1
DIR=`pwd`
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
	dS=`date +"%Y%m%d%H%M%S"`
  onstat -g sql 0 >$DIR/sql.$dS
  sleep 1;
done