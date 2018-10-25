#!/bin/sh
dodir=/home/informix/jiankong          	#�ű�����Ŀ¼�����в������������Ŀ¼ִ��
log=$dodir/root.log                     #������¼��־
alarmlog=$dodir/alarm.log               #��¼���и澯����־
alarmcode=123                           #�澯��
remaindernum=1                          #rmd�����е����������ķ�ֵ
fragdaynum=3                            #��Ƭ��������ӽ������������ֵ������
ckptnum=2                               #���ݿ⴦��ckpt״̬�����ٴκ�澯
ckptnumjiange=10                        #ckpt�������
testflag=1                              #���Ա�־λ������ʹ��ʱ��ֵ����Ϊ0
tflag=0

#ͨ��ʱ������
time=`date +"%Y%m%d%H%M%S"`
#timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
dH=`date +"%Y%m%d%H"`
dHonly=`date +"%H"`
dMonly=`date +"%M"`
dYonly=`date +"%Y"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dSn=`date +"%Y-%m-%d %H:%M:%S"`
dMonly=`date +"%M"`
hostname=`hostname`
wai=`whoami`
#okday=`date -d "+$fragdaynum days" +"%Y%m%d"`

log4s()
{
	#����ʱ����������������Ͻ���log4s
	dStmp=`date +"%Y%m%d%H%M%S"`
	echo "$dStmp $1 $2"
	echo "$dStmp $1 $2" >> $log
}
sendalarm()
{
	dStmp=`date +"%Y%m%d%H%M%S"`
	log4s error "$1"
	echo "$dStmp $alarmcode $1" >> $alarmlog
	let errornum=errornum+1
}

if [ ! -d $dodir ]
then
	mkdir $dodir
	log4s info "��������Ŀ¼"
fi
errornum=0
ckptcheck()
{
	tempckptnum=0

	i=0
	dStmp=`date +"%Y%m%d%H%M%S"`
	ckptunl="$dodir/ckpt.unl.temp.$dStmp"
	while true
	do
		let i=i+1
		echo "unload to $ckptunl select sh_cpflag from sysshmvals"|dbaccess sysmaster 1>/dev/null 2>&1;
		if [ $tflag = 1 ]
		then
			if [ $i = 1 ]
			then
				echo 1 > $ckptunl
			elif [ $i = 2 ]
			then
				echo 0 >  $ckptunl
			fi
		elif [ $tflag = 2 ]
		then
			if [ $i = 1 ]
			then
				echo 0 > $ckptunl
			elif [ $i = 2 ]
			then
				echo 1 >  $ckptunl
			fi
		elif [ $tflag = 3 ]
		then
			if [ $i = 1 ]
			then
				echo 1 > $ckptunl
			elif [ $i = 2 ]
			then
				echo 1 >  $ckptunl
			fi
		fi
		if [ $? != 0 ]
		then
			sendalarm "�ж�ckpt״̬ʱ�������ݿ⵼������ʧ��"
		fi
		ckptstatus=`tail  $ckptunl|awk -F'|' '{print $1}'`
		if [ $testflag = 0 ]
		then
			rm -rf $ckptunl
		fi
		if [ $ckptstatus = 1 ]
		then
			let tempckptnum=tempckptnum+1
			log4s "�� $i �μ�飬��ǰΪckpt״̬���ȴ� $ckptnumjiange ���������"
			if [ $tempckptnum = $ckptnum ]
			then
				sendalarm "ckpt״̬�Ѿ����� $ckptnum �Σ�ÿ�μ�� $ckptnumjiange �봦��ckpt״̬���������ݿ�"
				break;
			fi
			sleep $ckptnumjiange;
		else
			log4s info "ckpt״̬����"
			break;
		fi
		if [ $i -eq $ckptnum ]
		then
			break;
		fi
	done
}
ckptcheck