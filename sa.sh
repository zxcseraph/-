#!/bin/sh
#长期部署版sar，放在执行目录
HOSTNAME=`hostname|tr '[a-z]' '[A-Z]'`
dodir=/tmp
xiaoshi=720
LC_TIME="POSIX"
export LC_TIME="POSIX"
tag=`date +"%Y%m%d%H"`

num=0
while [ $num -lt $xiaoshi ]
do
	tag=`date +"%Y%m%d%H"`
	nohup sar -d 1 3600 > ${HOSTNAME}.$tag &
	sleep 3600;
	gzip ${HOSTNAME}.$tag
	let num+=1
done