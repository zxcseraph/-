#!/bin/sh
dbid=$1
DIR=$2
xndir=$DIR/xingnengtemp
pythonedir=/home/zxc/xuanyuan/python/
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
export LC_TIME="POSIX"
dtoday=`date +"%Y%m%d"`
hour2second=3600
if [ ! -d $xndir ]
then
	mkdir $xndir
fi
while true
do
	dt=`date +"%Y%m%d"`
	dh=`date +"%Y%m%d%H"`
	dH=`date +"%Y%m%d%H"`
	ds=`date +"%Y%m%d%H%M%S"`
	nohup vmstat 1 $hour2second|awk -v dbid="$dbid" -v OFS="|" '{$1=$1;print 0,dbid,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $xndir/xn_vm.$ds &
	nohup sar -n DEV 1 $hour2second|awk -v dbid="$dbid" -v OFS="|" '{$1=$1;print 0,dbid,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $xndir/xn_network.$ds &
	nohup sar -d 1 $hour2second|awk -v dbid="$dbid" -v OFS="|" '{$1=$1;print 0,dbid,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $xndir/xn_disk.$ds &
	sleep $hour2second
	grep -v "procs" $xndir/xn_vm.$ds|grep -v "swpd"|awk 'BEGIN{FS="|";OFS="|"} {if(length($21)!=0 && length($22)==0){print $0}}' >> $xndir/xn_vm.log.$dH.temp
#	grep -v "IFACE|rxpck" $xndir/xn_network.$ds|grep -v "Linux"|grep -v "|$"|awk 'BEGIN{FS="|";OFS="|"} {if(length($12)!=0 && length($13)==0){print $0}}' >> $xndir/xn_network.log.$dH.temp
	grep -v "IFACE|rxpck" $xndir/xn_network.$ds|grep -v "Linux"|grep -v "|$" >> $xndir/xn_network.log.$dH.temp
#	grep -v "DEV"         $xndir/xn_disk.$ds   |grep -v "Linux"|grep -v "|$"|awk 'BEGIN{FS="|";OFS="|"} {if(length($14)!=0 && length($15)==0){print $0}}' >> $xndir/xn_disk.log.$dH.temp
	grep -v "DEV"         $xndir/xn_disk.$ds   |grep -v "Linux"|grep -v "|$" >> $xndir/xn_disk.log.$dH.temp
	rm $xndir/xn_vm.$ds
	rm $xndir/xn_network.$ds
	rm $xndir/xn_disk.$ds
done