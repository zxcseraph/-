#!/bin/sh
#�ӵ�0��cpuռ�ÿ�ʼ��ֱ��ָ��������
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
	echo "���������ƽű������У�Ϊ�������������ϸ�˲�ps -ef|grep $shichu���鿴�Ƿ��н����Ȼ����ϵ������Ա"
	exit 1;
fi
truecpunum=`cat /proc/cpuinfo|grep processor|wc -l|awk '{print $1}'`
if [ $truecpunum -lt $zhanyongnum ]
then
	echo "���õ�cpuռ�ø�����$zhanyongnum������ʵ��cpu������$truecpunum�����������нű�"
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