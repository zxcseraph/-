#!/bin/sh
onlinelogidr=/home/informix
bakdir=/home/informix/onlog-bak
T=`date +"%Y-%m-%d"`
Tm=`date +"-%m-%d"`
TY=`date +"%Y"`
let TYdel=TY-1

if [ ! -d $onlinelogidr ]
then
	echo "online.log�����ڣ���ȷ��Ŀ¼">>$HOME/moveonline.log
fi

if [ ! -d $bakdir ]
then
	mkdir $bakdir
	echo "��������Ŀ¼">>$HOME/moveonline.log
fi
mv $onlinelogidr/online.log $bakdir/online.log.${T}
>$onlinelogidr/online.log
chown informix:informix $onlinelogidr/online.log
chmod o+r $onlinelogidr/online.log
echo "������־�ɹ�������Ϊ$bakdir/online.log.${T}">>$HOME/moveonline.log
if [ -f $bakdir/online.log.${TYdel}${Tm} ]
then
	rm $bakdir/online.log.${TYdel}${Tm}
	echo "ɾ��һ��ǰ�ı�����־$bakdir/online.log.${TYdel}${Tm}">>$HOME/moveonline.log
fi
