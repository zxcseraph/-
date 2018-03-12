#!/bin/sh
onlinelogidr=/home/informix
bakdir=/home/informix/onlog-bak
T=`date +"%Y-%m-%d"`
Tm=`date +"-%m-%d"`
TY=`date +"%Y"`
let TYdel=TY-1

if [ ! -d $onlinelogidr ]
then
	echo "online.log不存在，请确认目录">>$HOME/moveonline.log
fi

if [ ! -d $bakdir ]
then
	mkdir $bakdir
	echo "创建备份目录">>$HOME/moveonline.log
fi
mv $onlinelogidr/online.log $bakdir/online.log.${T}
>$onlinelogidr/online.log
chown informix:informix $onlinelogidr/online.log
chmod o+r $onlinelogidr/online.log
echo "备份日志成功，备份为$bakdir/online.log.${T}">>$HOME/moveonline.log
if [ -f $bakdir/online.log.${TYdel}${Tm} ]
then
	rm $bakdir/online.log.${TYdel}${Tm}
	echo "删除一年前的备份日志$bakdir/online.log.${TYdel}${Tm}">>$HOME/moveonline.log
fi
