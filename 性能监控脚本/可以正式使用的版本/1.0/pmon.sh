#!/bin/sh

version=0.1
if [ $# -lt 1 ]; then
	echo "Usage: $0 [basic] [top] [all]"
	exit 1
fi
workdir=`pwd`
host=`hostname`
log=$workdir/root.log
reservation=7									#��¼�ļ��ı�������
#hour2second=3600							#ÿ���ļ��ļ�¼��õ���־���ݣ�3600ΪһСʱһ���ļ�
iuser=`whoami`

export LC_TIME="POSIX"

os=`uname -a|awk '{print $1}'|tr '[a-z]' '[A-Z]'`
log4s()
{
	log4s_dst=`date +"%Y-%m-%d %H:%M:%S"`
	echo "$1"
	echo "$log4s_dst $1" >> $log

}


#��ȡx��֮ǰ�����庯��
DOY () {
#ȡϵͳʱ��
CURRENTDAY=`date "+%Y-%m-%d"`
BACKYEAR=`echo $CURRENTDAY|awk -F'-' '{print $1}'`
BACKMONTH=`echo $CURRENTDAY|awk -F'-' '{print $2}'`
BACKDAY=`echo $CURRENTDAY|awk -F'-' '{print $3}'`
YEAR=$BACKYEAR

#�ж�����
FYEAR="$YEAR"
 
if [ `expr ${FYEAR} % 400` -eq 0 ];then
    FRUN="366"
else
    if [ `expr ${FYEAR} % 4` -eq 0 ];then
        if [ `expr ${FYEAR} % 100` -eq 0 ];then
            FRUN="365"
        else
            FRUN="366"
        fi
    else
        FRUN="365"
    fi
fi

MONTH=`echo $BACKMONTH | sed 's/^0//g'`
DAY=`echo $BACKDAY | sed 's/^0//g'`
#MD��ʾ
MD=0
#�����ۼ�
MDTOTAL=0
NUM1=$1
	if [ $DAY -gt $NUM1 ]
	then
#��������������
		DAY=`expr $DAY - $NUM1`
	else
		while [ 1 ]
		do
			MONTH=`expr $MONTH - 1`
			[ $MONTH -le 0 ] && { MONTH=12 ; YEAR=`expr $YEAR - 1` ; }
			case $MONTH in
				1|3|5|7|8|10|12 ) DAYADD=31
					;;
				4|6|9|11 ) DAYADD=30
					;;
				2 )if [ $FRUN = 366 ]
           	then DAYADD=29
						else DAYADD=28
						fi
 
					;;
			esac
 
			DAY=`expr $DAY + $DAYADD`
			[ $DAY -gt $NUM1 ] && { DAY=`expr $DAY - $NUM1` ; break ; }
		done
	fi
	[ $DAY -lt 10 ] && { DAY="0"`expr $DAY` ; }
	[ $MONTH -lt 10 ] && { MONTH="0"`expr $MONTH` ; }
 
	RMDATE="$YEAR-$MONTH-$DAY"
	echo "$RMDATE"
}

getResidueSec()
{
	dMt=`date +"%M"|sed s'/^0//'`
	dSt=`date +"%S"|sed s'/^0//'`
	if [ $dMt -gt 22 ]
	then
		let lMt=60-dMt+22
	else
		let lMt=22-dMt
	fi
	if [ $dSt -gt 22 ]
	then
		let lSt=60-dSt+22
	else
		let lSt=22-dSt
	fi

	
	let residueSec=lMt*60+lSt

	echo $residueSec

}

GetPerformance()
{
	log4s "Enter main loop"
	mkdir $workdir/vm 1>/dev/null 2>&1
	mkdir $workdir/net 1>/dev/null 2>&1
	mkdir $workdir/disk 1>/dev/null 2>&1
	#����ѭ���У�ִ��ͳ�ƺʹ����ļ����ں�ִ̨�У���֤ͳ�Ƶ�����
	while true
	do
		log4s "In the main loop"

		#���ݵ�ǰʱ�䣬��ȡ���ѭ��Ҫ���е�ʱ��
		runSec=`getResidueSec`
		let runSec=runSec-1
		dH=`date +"%Y%m%d%H"`
		dS=`date +"%Y%m%d%H%M%S"`

		nohup vmstat 1     $runSec|awk -v host="$host" -v OFS="|" '{$1=$1;print 0,host,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $workdir/vm/p_vm.$dS 2>&1 &
		nohup sar -n DEV 1 $runSec|awk -v host="$host" -v OFS="|" '{$1=$1;print 0,host,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $workdir/net/p_network.$dS 2>&1 &
		nohup sar -d 1     $runSec|awk -v host="$host" -v OFS="|" '{$1=$1;print 0,host,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}' > $workdir/disk/p_disk.$dS 2>&1 &
		sleep $runSec;

		grep -v "procs"       $workdir/vm/p_vm.$dS        |grep -v "swpd"                  >> $workdir/vm/p_vm.log.$dH
		grep -v "IFACE|rxpck" $workdir/net/p_network.$dS  |grep -v "Linux"|grep -v "|$"    >> $workdir/net/p_network.log.$dH
		grep -v "DEV"         $workdir/disk/p_disk.$dS    |grep -v "Linux"|grep -v "|$"    >> $workdir/disk/p_disk.log.$dH
		
		rm -rf $workdir/vm/p_vm.$dS;
		rm -rf $workdir/net/p_network.$dS;
		rm -rf $workdir/disk/p_disk.$dS;
		
		#ɾ��ָ������֮ǰ�ļ�¼�ļ�
		#��ȡָ������֮ǰ������
		log4s "��ʼɾ�������ļ�"
		rmday=`DOY $reservation|awk -F'-' '{print $1$2$3}'`
		log4s "GetPerformance ��������Ϊ $rmday"
		rm -rf $workdir/vm/p_vm.log.${rmday}*;
		rm -rf $workdir/net/p_network.log.${rmday}*;
		rm -rf $workdir/disk/p_disk.log.${rmday}*;
	done
	
}

#top�������������Ҫ����top�Ĺ���ʱ��ʹ��������á���ʽ�ǲ���top��Ϊһ��ʱ��ִ��topģʽ����������б�����top����Ϊall��ʱ����ǰһ����ʽ����top��
GetTop()
{
	log4s "Enter top main loop"
	mkdir $workdir/top 1>/dev/null 2>&1
	while true
	do
		dH=`date +"%Y%m%d%H"`
		dS=`date +"%Y%m%d%H%M%S"`
		if [ X$os = XLINUX ]
		then
			nohup top -b -n 1   |awk -v time="$dS" -v host="$host" -v OFS="|" '{$1=$1;print 0,host,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}'|head -30>$workdir/top/p_top.$dS &
			if [ X$iuser = Xroot ]
			then
				nohup iotop -b -n 1 |awk -v time="$dS" -v host="$host" -v OFS="|" '{$1=$1;print 0,host,strftime("%Y%m%d%H%M%S"),strftime("%s"),$0}'|head -30>$workdir/top/p_iotop.$dS &
			fi
			sleep 1;
			head -22 $workdir/top/p_top.$dS   | sed "1,7d" >> $workdir/top/p_top.log.$dH
			rm -rf $workdir/top/p_top.$dS;
			if [ X$iuser = Xroot ]
			then
				head -22 $workdir/top/p_iotop.$dS | sed "1,2d" >> $workdir/top/p_iotop.log.$dH
				rm -rf $workdir/top/p_iotop.$dS;
			fi

		else
			log4s "OS is not support  $os"
		fi
		
		#ɾ��ָ������֮ǰ�ļ�¼�ļ�
		#��ȡָ������֮ǰ������
		rmday=`DOY $reservation|awk -F'-' '{print $1$2$3}'`
		rm -rf $workdir/top/p_top.log.${rmday}*;
		if [ X$iuser = Xroot ]
		then
			rm -rf $workdir/top/p_iotop.log.${rmday}*;
		fi
	done
}
analysis()
{
	lenstarttime=`echo "$1"|wc -L`
	lenendtime=`echo "$2"|wc -L`
	if [ $lenstarttime = 19 ]
	then
		#��ʽΪ2018-09-30 16:04:02��ֱ��ת��Ϊutc
		starttimet="$1"
		starttime=`date -d "$starttimet" +"%s"`
	elif [ $lenstarttime = 14 ]
	then
		#��ʽΪ20180930160402����Ҫת��Ϊ����ĸ�ʽ��ת��Ϊutc
		starttimet="${1:0:4}-${1:4:2}-${1:6:2} ${1:8:2}:${1:10:2}:${1:12:2}"
		starttime=`date -d "$starttimet" +"%s"`
	elif [ $lenstarttime = 10 ]
	then
		#��ʽΪutc������Ҫת��
		starttime="$1"
	else
		#�쳣��ʽ��������
		log4s "��ʼʱ�������ʽ����ȷ��������"
		exit 1;
	fi
	if [ $lenendtime = 19 ]
	then
		#��ʽΪ2018-09-30 16:04:02��ֱ��ת��Ϊutc
		endtimet="$2"
		endtime=`date -d "$starttimet" +"%s"`
	elif [ $lenendtime = 14 ]
	then
		#��ʽΪ20180930160402����Ҫת��Ϊ����ĸ�ʽ��ת��Ϊutc
		endtimet="${2:0:4}-${2:4:2}-${2:6:2} ${2:8:2}:${2:10:2}:${2:12:2}"
		endtime=`date -d "$starttimet" +"%s"`
	elif [ $lenendtime = 10 ]
	then
		#��ʽΪutc������Ҫת��
		endtime="$2"
	else
		#�쳣��ʽ��������
		log4s "����ʱ�������ʽ����ȷ��������"
		exit 1;
	fi
	log4s "��ʼʱ��Ϊ�� $starttime  ����ʱ��Ϊ�� $endtime   ��ʼ��ȡ��Χ����־"
	log4s "�ϲ���¼��־"
	cat $workdir/vm/p_vm.log.??????????           > $workdir/all_vm.log
	cat $workdir/net/p_network.log.??????????  > $workdir/all_net.log
	cat $workdir/disk/p_disk.log.??????????        > $workdir/all_disk.log
	log4s "��ʼ����vm������"
	awk -v starttime="$starttime" -v endtime="$endtime" -F'|' '{if($4>starttime && $4<endtime){print $0}}'  $workdir/all_vm.log   > $workdir/result_vm.log
	log4s "��ʼ����net������"
	awk -v starttime="$starttime" -v endtime="$endtime" -F'|' '{if($4>starttime && $4<endtime){print $0}}'  $workdir/all_net.log   > $workdir/result_net.log
	log4s "��ʼ����disk������"
	awk -v starttime="$starttime" -v endtime="$endtime" -F'|' '{if($4>starttime && $4<endtime){print $0}}'  $workdir/all_disk.log  > $workdir/result_disk.log
	rm -rf  $workdir/all_vm.log
	rm -rf  $workdir/all_net.log
	rm -rf  $workdir/all_disk.log
	sort  -t"|" -k 4 -n $workdir/result_vm.log    > $workdir/result_vm.log1
	sort  -t"|" -k 4 -n $workdir/result_net.log    > $workdir/result_net.log1
	sort  -t"|" -k 4 -n $workdir/result_disk.log   > $workdir/result_disk.log1
	mv $workdir/result_vm.log1 $workdir/result_vm.log
	mv $workdir/result_net.log1 $workdir/result_net.log
	mv $workdir/result_disk.log1 $workdir/result_disk.log
}

if [ $1 = all ] 
then
	nohup sh ./pmon.sh top 1>$workdir/topnohup.out 2>&1 &
	GetPerformance
fi

if [ $1 = basics ] 
then
	GetPerformance
fi
if [ $1 = top ]
then
	GetTop
fi
if [ $1 = analysis ] && [ X$2 != X ] && [ X$3 != X ]
then
	analysis "$2" "$3"
fi