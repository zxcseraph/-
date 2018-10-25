#!/bin/sh
#从第0个cpu占用开始，直到指定个数。
zhanyongnum=$1
dodir=/tmp/zhanyong
dS=`date +"%Y%m%d%H%M%S"`
shichu=$dodir/cpuzhanyong${dS}.sh
cat <<EOF >$shichu
while true
do
a=0
let b=a+100
let c=b*100
done
EOF
nowzhanyong=`ps -ef|grep $shichu|wc -l|awk '{print $1}'`
if [ X$nowzhanyong != X0 ]
then
	echo "有类似名称脚本在运行，为避免出错误，请详细核查ps -ef|grep $shichu，查看是否有结果，然后联系开发人员"
	exit 1;
fi
truecpunum=`cat /proc/cpuinfo|grep processor|wc -l|awk '{print $1}'`
if [ $truecpunum -lt $zhanyongnum ]
then
	echo "设置的cpu占用个数：$zhanyongnum，少于实际cpu个数：$truecpunum，请重新运行脚本"
	exit 1;
fi
tempnum=0
while [ $tempnum -lt $zhanyongnum ]
do
	nohup sh $shichu &
	ps -ef|grep $shichu|awk '{print $2}' > $dodir/nowpid.txt
	let tempnum=tempnum+1
done

tempcputag=0
while read nowpid
do
	taskset -pc $tempcputag $nowpid
	let tempcputag=tempcputag+1
done < $dodir/nowpid.txt