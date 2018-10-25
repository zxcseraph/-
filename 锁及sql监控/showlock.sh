#!/bin/sh
mingcheng="����ؽű�"
version="1.0"
doDIR=`pwd`
servername=hdr1
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
dH=`date +"%Y%m%d%H"`
dHonly=`date +"%H"`
dMonly=`date +"%M"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dSn=`date +"%Y-%m-%d %H:%M:%S"`
dMonly=`date +"%M"`
log=$doDIR/root.log
log4ss()
{
	echo "$1"
	echo "$1" >> $log
}
getlock()
{
	dSn=`date +"%Y-%m-%d %H:%M:%S"`
	cd $doDIR
	mkdir $dS
	cd $dS
	sql="unload to $doDIR/$dS/syslocks.${dS}.unl select dbsname,tabname,type,owner,waiter,rowidlk,keynum from syslocks where dbsname not in (\"sysmaster\",\"sysadmin\",\"sysuser\",\"sysutils\")"
	echo "$sql" |dbaccess sysmaster@$servername
	while read hang
	do
		dbsname=`echo "$hang"|awk -F'|' '{print $1}'`
		tabname=`echo "$hang"|awk -F'|' '{print $2}'`
		type=`echo "$hang"|awk -F'|' '{print $3}'`
		owner=`echo "$hang"|awk -F'|' '{print $4}'`
		waiter=`echo "$hang"|awk -F'|' '{print $5}'`
		if [ X$waiter = X ]
		then
			echo "��ʼͳ�� $dSn ">> ok.${owner}.ses
			onstat -g ses $owner >> ok.${owner}.ses
			echo "����ͳ�� $dSn ">> ok.${owner}.ses
		else
			echo "��ʼͳ�� $dSn ">> bad.${owner}.ses
			echo "��ʼͳ�� $dSn ">> bad.wait.${owner}.${waiter}.ses
			onstat -g ses $owner >> bad.${owner}.ses
			onstat -g ses $waiter >> bad.wait.${owner}.${waiter}.ses
			echo "����ͳ�� $dSn ">> bad.${owner}.ses
			echo "����ͳ�� $dSn ">> bad.wait.${owner}.${waiter}.ses
		fi
	done < $doDIR/$dS/syslocks.${dS}.unl
}
timei=0
for i in {1...60}
	dS=`date +"%Y%m%d%H%M%S"`
	getlock
	sleep 1
done
