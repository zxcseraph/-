#!/bin/sh
dodir=/home/informix/jiankong          	#脚本工作目录，所有操作均会在这个目录执行
log=$dodir/root.log                     #操作记录日志
alarmlog=$dodir/alarm.log               #记录所有告警的日志
alarmcode=123                           #告警码
remaindernum=1                          #rmd分区中的数据行数的阀值
fragdaynum=3                            #分片必须包含从今天起向后数该值的天数
ckptnum=2                               #数据库处于ckpt状态检查多少次后告警
ckptnumjiange=10                        #ckpt检查间隔秒
testflag=1                              #测试标志位，现网使用时该值必须为0
tflag=0

#通用时间配置
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
	#调试时先用这个，后期整合进来log4s
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
	log4s info "创建工作目录"
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
			sendalarm "判断ckpt状态时，从数据库导出数据失败"
		fi
		ckptstatus=`tail  $ckptunl|awk -F'|' '{print $1}'`
		if [ $testflag = 0 ]
		then
			rm -rf $ckptunl
		fi
		if [ $ckptstatus = 1 ]
		then
			let tempckptnum=tempckptnum+1
			log4s "第 $i 次检查，当前为ckpt状态，等待 $ckptnumjiange 秒后继续检查"
			if [ $tempckptnum = $ckptnum ]
			then
				sendalarm "ckpt状态已经连续 $ckptnum 次，每次间隔 $ckptnumjiange 秒处于ckpt状态，请检查数据库"
				break;
			fi
			sleep $ckptnumjiange;
		else
			log4s info "ckpt状态正常"
			break;
		fi
		if [ $i -eq $ckptnum ]
		then
			break;
		fi
	done
}
ckptcheck