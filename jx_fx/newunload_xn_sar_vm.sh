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
	nohup vmstat 1 $hour2second|awk -v dbid="$dbid" -v OFS="|" '{$1=$1;print dbid,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $xndir/xn_vm.$dh.temp &
	nohup sar -n DEV 1 $hour2second|awk -v dbid="$dbid" -v OFS="|" '{$1=$1;print dbid,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $xndir/xn_network.$dh.temp &
	nohup sar -d 1 $hour2second|awk -v dbid="$dbid" -v OFS="|" '{$1=$1;print dbid,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $xndir/xn_disk.$dh.temp &
	sleep $hour2second
	grep -v "procs" $xndir/xn_vm.$dh.temp|grep -v "swpd" >> $xndir/xn_vm.log.$dt
	grep -v "IFACE|rxpck" $xndir/xn_network.$dh.temp|grep -v "Linux"|grep -v "|$" >> $xndir/xn_network.log.$dt
	grep -v "DEV $xndir/xn_disk.$dh.temp|tps"    |grep -v "Linux"|grep -v "|$" >> $xndir/xn_disk.log.$dt
	rm $xndir/xn_vm.$dh.temp
	rm $xndir/xn_network.$dh.temp
	rm $xndir/xn_disk.$dh.temp
done