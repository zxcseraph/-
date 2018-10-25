#!/bin/sh
set -x
dodir=/home/icaa/loudan/workdir         #脚本工作目录，所有操作均会在这个目录执行
shengfencode=23                         #省份id，天津是02
log=$dodir/root.log                     #操作记录日志
jilu=$dodir/result.log                  #记录每天的话单总量
alarmlog=$dodir/alarm.log               #记录所有告警的日志
crbtorijobid=031018                     #网管分配音频原始文件的任务号
vrbtorijobid=031019                     #网管分配视频原始文件的任务号
alljobid=031020                         #网管分配最终文件的任务号
crbtalarmcode=00003101840               #音频告警码
vrbtalarmcode=00003101841               #视频告警码
servername=hdr1                         #数据库servername
databasename=fx                         #数据库的实例名   比如newip@dbm1，newip就是实例名，dbm1就是servername
wucha=10                                #误差百分比，超过这个脚本会产生一个告警
orifinalwucha=1                         #原始文件和最终文件的误差百分比
d1dayago=`date -d "-1 days" +"%Y%m%d"`
d2dayago=`date -d "-2 days" +"%Y%m%d"`
#音频相关
#音频彩铃呼叫话单文件命名规则
crbtfile="VGOP_TONEPLAYINFO_${d1dayago}_${shengfencode}.rar"
#音频原始文件命名规则
crbtorifile="*.SRF.LOG.${d1dayago}*"
#音频原始文件主机名 truecrbthostname是文件名中的主机名和网管中的主机名的对应，因为文件中的主机名都是大写，网管识别不正常，所以需要增加一个转换。crbtorifilenames是文件中的主机名。
declare -A truecrbthostname=(["AS201"]="as201" ["AS202"]="as202" ["AS221"]="as221" ["CAS041"]="cas041" ["CAS042"]="cas042" ["CAS051"]="cas051" ["CAS052"]="cas052" ["CAS061"]="cas061" ["CAS062"]="cas062" ["CN131"]="cn131" ["CN132"]="cn132" ["CN133"]="cn133" ["CN134"]="cn134" ["CN141"]="cn141" ["CN142"]="cn142" ["CN143"]="cn143" ["CN144"]="cn144" ["CN161"]="cn161" ["CN162"]="cn162" ["CN163"]="cn163" ["CN164"]="cn164" ["CN171"]="cn171" ["CN172"]="cn172" ["CN173"]="cn173" ["CN174"]="cn174" ["CN181"]="cn181" ["CN182"]="cn182" ["CN183"]="cn183" ["CN184"]="cn184" ["CN191"]="cn191" ["CN192"]="cn192" ["CN211"]="cn211" ["CN212"]="cn212" ["CN231"]="cn231" ["CN232"]="cn232")
crbtorifilenames=("AS201" "AS202" "AS221" "CAS041" "CAS042" "CAS051" "CAS052" "CAS061" "CAS062" "CN131" "CN132" "CN133" "CN134" "CN141" "CN142" "CN143" "CN144" "CN161" "CN162" "CN163" "CN164" "CN171" "CN172" "CN173" "CN174" "CN181" "CN182" "CN183" "CN184" "CN191" "CN192" "CN211" "CN212" "CN231" "CN232")
#音频文件存放目录
crbtfiledir=/home/icaa/loudan/ziyuan/crbt
#音频原始文件存放目录
crbtfileoridir=/home/icaa/loudan/ziyuan/crbtyuanshi
#音频文件临时工作目录
crbtworkdir=$dodir/crbt
#音频原始文件临时工作目录
crbtworkdirori=$dodir/crbtori
#音频原始文件异常处理，可以提高音频原始文件数量统计精度，但是性能影响很大，请确认是否打开，1为打开，0为关闭
crbtoriyichang=1
#视频相关
#视频彩铃呼叫话单文件命名规则
vrbtfile="CLJZ_V_TONEPLAYINFO_${d1dayago}????_${shengfencode}.zip"
#视频原始文件命名规则
vrbtorifile="*.SRF.LOG.*.${d1dayago}*"
#视频原始文件主机名，同音频
declare -A truevrbthostname=(["CAS033"]="cas033" ["CAVTAS01"]="cavtas01" ["CAS073"]="cas073")
vrbtorifilenames=("CAS033" "CAVTAS01" "CAS073")
#视频文件存放目录
vrbtfiledir=/home/icaa/loudan/ziyuan/vrbt
#视频原始文件存放目录
vrbtfileoridir=/home/icaa/loudan/ziyuan/vrbtyuanshi
#视频文件临时工作目录
vrbtworkdir=$dodir/vrbt
#视频原始文件临时工作目录
vrbtworkdirori=$dodir/vrbtori

d1dayY=${d1dayago:3:1}
d1daym=${d1dayago:5:1}
d1dayd=${d1dayago:6:2}
#音频文件密码
mima=${d1dayY}${d1daym}${d1dayd}@${shengfencode}
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
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
#下面是各种标志
crbt_record_num=last_crbt_record_num					#昨天音频最终文件
vrbt_record_num=last_vrbt_record_num					#昨天视频最终文件
crbtori_record_num=last_crbtori_record_num		#昨天音频分析之前文件
vrbtori_record_num=last_vrbtori_record_num		#昨天视频分析之前文件
lastday_crbtoripre=lastday_crbtori_						#昨天音频分析之前文件的具体主机或者账户前缀标志
lastday_vrbtoripre=lastday_vrbtori_						#昨天视频分析之前文件的具体主机或者账户前缀标志
log4s()
{
	echo "$dS $1" >> $log
	echo "$dS $1"
}
SendAlarm()
{
	log4s "$1"
	if [ X$2 = Xcrbt ]
	then
		echo "$dS $hostname $crbtalarmcode $1" >>$alarmlog
	elif [ X$2 = Xvrbt ]
	then
		echo "$dS $hostname $vrbtalarmcode $1" >>$alarmlog
	else
		echo "$dS $hostname $crbtalarmcode $vrbtalarmcode $1" >>$alarmlog
	fi
	
}

pdir()
{
	if [ ! -d $1 ]
	then
		mkdir $1
		log4s "$1 不存在，创建$1"
		if [ $? = 0 ]
		then
			log4s "创建$1成功"
		else
			log4s "创建$1失败"
			exit 1;
		fi
	fi
}
pdir $dodir
pdir $crbtworkdir
pdir $vrbtworkdir
pdir $crbtworkdirori
pdir $vrbtworkdirori
crbtnum=0
vrbtnum=0
crbtinitfile()
{
	#开始crbt的初始化操作
	log4s "开始crbt初始化操作"
	rm -rf $crbtworkdir/*
	cp $crbtfiledir/$crbtfile $crbtworkdir;
	if [ $? != 0 ]
	then
		SendAlarm "文件不存在：音频彩铃话单原始文件不存在" crbt
	fi
	#判断文件对应网管主机名是否填写完全
	for key in ${crbtorifilenames[@]}
	do
	    if [ X${truecrbthostname[$key]} = X ]
	    then
	    	SendAlarm "$key 没有对应网关主机名，暂时文件名为其网管主机名" crbt
	    	truecrbthostname[$key]=$key
	    fi
	done
	cd $crbtworkdir;
	unzip -P $mima $crbtfile
	rm -rf $crbtfile
	crbtfilenum=`ls $crbtworkdir 2>/dev/null|wc -l|awk '{print $1}'`
	if [ $crbtfilenum = 0 ]
	then
		SendAlarm "文件个数：音频彩铃话个数单为空" crbt
	fi
}

vrbtinitfile()
{
	#开始vrbt的初始化操作
	log4s "开始vrbt初始化操作"
	rm -rf $vrbtworkdir/*
	cp $vrbtfiledir/$vrbtfile $vrbtworkdir;
	if [ $? != 0 ]
	then
		SendAlarm "文件不存在：视频彩铃话单备份文件不存在" vrbt
	fi
	#判断文件对应网管主机名是否填写完全
	for key in ${vrbtorifilenames[@]}
	do
	    if [ X${truevrbthostname[$key]} = X ]
	    then
	    	SendAlarm "$key 没有对应网关主机名，暂时文件名为其网管主机名" vrbt
	    	truevrbthostname[$key]=$key
	    fi
	done
	cd $vrbtworkdir;
	unzip "*.zip";
	rm -rf $vrbtworkdir/$vrbtfile
	vrbtfilenum=`ls $vrbtworkdir 2>/dev/null|wc -l|awk '{print $1}'`
	if [ $vrbtfilenum = 0 ]
	then
		SendAlarm "文件个数：视频彩铃话个数单为空" vrbt
	fi
}
getfilenum()
{
	#$1是操作目录
	cd $1;
	getnum=`wc -l *|tail -1|awk '{print $1}'`
	echo "$getnum"
}
crbtorigo()
{
	#开始crbt原始文件的初始化操作
	log4s "开始crbt原始文件初始化操作"
	rm -rf $crbtworkdirori/*
	cp $crbtfileoridir/$crbtorifile $crbtworkdirori;
	if [ $? != 0 ]
	then
		SendAlarm "文件不存在：音频彩铃话单原始备份文件不存在" crbt
	fi
	cd $crbtworkdirori;
	if [ $crbtoriyichang = 1 ]
	then
		crbtorifilesumnnum=`grep $dYonly $crbtworkdirori/*|awk 'BEGIN{FS="|"} $7!="" && $8!="" {print $0}'|wc -l|awk '{print $1}'`
	else
		crbtorifilesumnnum=`wc -l $crbtworkdirori/*|tail -1|awk '{print $1}'`
	fi

	if [ $? = 0 ]
	then
		echo "$dS|$d1dayago|${crbtori_record_num}|$crbtorifilesumnnum" >>$jilu
#		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01) values ('$crbtorijobid','$hostname','$wai','$dSn',1,'$dSn',3,'${crbtorifilesumnnum}')"|dbaccess ${databasename}@${servername}
#		if [ $? = 0 ]
#		then
#			log4s "$dS SUCCESS 原始文件总量昨天话单量 导入inms_pm_data成功"
#		else
#			log4s "$dS ERROR 原始文件总量昨天话单量 导入inms_pm_data失败"
#			echo "$crbtorijobid|$hostname|$wai|||$dSn|1|$dSn|2|${crbtorifilesumnnum}|||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
#		fi
#		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$crbtorijobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
#		if [ $? = 0 ]
#		then
#			log4s "$dS SUCCESS 原始文件总量昨天话单量 导入inms_pm_datamgr成功"
#		else
#			log4s "$dS ERROR 原始文件总量昨天话单量 导入inms_pm_datamgr失败"
#			echo "$crbtorijobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
#		fi
	else
		SendAlarm "获取crbt原始文件总量话单异常，请检查文件或者脚本" crbt
	fi
	log4s "$dS|$d1dayago|${crbtori_record_num}|$crbtorifilesumnnum"
	
	crbtorifilescount=0
	for i in ${crbtorifilenames[*]}
	do
		#首先处理异常话单
		if [ $crbtoriyichang = 1 ]
		then
			hostnum=`grep $dYonly ${i}_*|awk 'BEGIN{FS="|"} $7!="" && $8!="" {print $0}'|wc -l|awk '{print $1}'`
		else
			hostnum=`wc -l ${i}*|tail -1|awk '{print $1}'`
		fi
		if [ X$hostnum = X ]
		then
			hostnum=0
		fi
		if [ $? = 0 ]
		then
			echo "$dS|$d1dayago|${lastday_crbtoripre}${truecrbthostname[$i]}|$hostnum" >>$jilu
			echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01) values ('$crbtorijobid','${truecrbthostname[$i]}','$wai','$dSn',1,'$dSn',1,'$hostnum')"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${truecrbthostname[$i]}昨天话单量 导入inms_pm_data成功"
			else
				log4s "$dS ERROR ${truecrbthostname[$i]}昨天话单量 导入inms_pm_data失败"
				echo "$crbtorijobid|${truecrbthostname[$i]}|$wai|||$dSn|1|$dSn|1|$hostnum|||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
			fi
			echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$crbtorijobid','${truecrbthostname[$i]}','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${truecrbthostname[$i]}昨天话单量 导入inms_pm_datamgr成功"
			else
				log4s "$dS ERROR ${truecrbthostname[$i]}昨天话单量 导入inms_pm_datamgr失败"
				echo "$crbtorijobid|${truecrbthostname[$i]}|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
			fi
		else
			SendAlarm "获取${truecrbthostname[$i]}话单异常，请检查文件或者脚本" crbt
		fi
		log4s "$dS|$d1dayago|${lastday_crbtoripre}${truecrbthostname[$i]}|$hostnum"
		let crbtorifilescount=crbtorifilescount+hostnum
	done
	if [ X$crbtorifilesumnnum != X$crbtorifilescount ]
	then
		SendAlarm "取的crbtori全量数据$crbtorifilesumnnum和分主机统计的结果$crbtorifilescount不同，请检查主机是否配置全" crbt
	fi
}
vrbtorigo()
{
	#开始vrbt原始文件的初始化操作
	log4s "开始vrbt原始文件初始化操作"
	rm -rf $vrbtworkdirori/*
	cp $vrbtfileoridir/$vrbtorifile $vrbtworkdirori;
	if [ $? != 0 ]
	then
		SendAlarm "文件不存在：视频彩铃话单原始备份文件不存在" vrbt
	fi
	cd $vrbtworkdirori;
	vrbtorifilesumnnum=`wc -l $vrbtworkdirori/*|tail -1|awk '{print $1}'`
	if [ $? = 0 ]
	then
		echo "$dS|$d1dayago|${vrbtori_record_num}|$vrbtorifilesumnnum" >>$jilu
#		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01) values ('$vrbtorijobid','$hostname','$wai','$dSn',1,'$dSn',3,'${vrbtorifilesumnnum}')"|dbaccess ${databasename}@${servername}
#		if [ $? = 0 ]
#		then
#			log4s "$dS SUCCESS 原始文件总量昨天话单量 导入inms_pm_data成功"
#		else
#			log4s "$dS ERROR 原始文件总量昨天话单量 导入inms_pm_data失败"
#			echo "$vrbtorijobid|$hostname|$wai|||$dSn|1|$dSn|2|${vrbtorifilesumnnum}|||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
#		fi
#		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$vrbtorijobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
#		if [ $? = 0 ]
#		then
#			log4s "$dS SUCCESS 原始文件总量昨天话单量 导入inms_pm_datamgr成功"
#		else
#			log4s "$dS ERROR 原始文件总量昨天话单量 导入inms_pm_datamgr失败"
#			echo "$vrbtorijobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
#		fi
	else
		SendAlarm "获取vrbt原始文件总量话单异常，请检查文件或者脚本" vrbt
	fi
	log4s "$dS|$d1dayago|${vrbtori_record_num}|$vrbtorifilesumnnum"
	
	vrbtorifilescount=0
	for i in ${vrbtorifilenames[*]}
	do
		hostnum=`wc -l ${i}*|tail -1|awk '{print $1}'`
		if [ X$hostnum = X ]
		then
			hostnum=0
		fi
		if [ $? = 0 ]
		then
			echo "$dS|$d1dayago|${lastday_vrbtoripre}${truevrbthostname[$i]}|$hostnum" >>$jilu
			echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01) values ('$vrbtorijobid','${truevrbthostname[$i]}','$wai','$dSn',1,'$dSn',1,'$hostnum')"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${truevrbthostname[$i]}昨天话单量 导入inms_pm_data成功"
			else
				log4s "$dS ERROR ${truevrbthostname[$i]}昨天话单量 导入inms_pm_data失败"
				echo "$vrbtorijobid|${truevrbthostname[$i]}|$wai|||$dSn|1|$dSn|1|${hostnum}|||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
			fi
			echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$vrbtorijobid','${truevrbthostname[$i]}','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${truevrbthostname[$i]}昨天话单量 导入inms_pm_datamgr成功"
			else
				log4s "$dS ERROR ${truevrbthostname[$i]}昨天话单量 导入inms_pm_datamgr失败"
				echo "$vrbtorijobid|${truevrbthostname[$i]}|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
			fi
		else
			SendAlarm "获取${truevrbthostname[$i]}话单异常，请检查文件或者脚本" vrbt
		fi
		log4s "$dS|$d1dayago|${lastday_vrbtoripre}${truevrbthostname[$i]}|$hostnum"
		let vrbtorifilescount=vrbtorifilescount+hostnum
	done
	if [ X$vrbtorifilesumnnum != X$vrbtorifilescount ]
	then
		SendAlarm "取的vrbtori全量数据$vrbtorifilesumnnum和分主机统计的结果$vrbtorifilescount不同，请检查主机是否配置全" vrbt
	fi
}
crbtgo()
{
	crbtinitfile;
	crbtrecordnum=`getfilenum $crbtworkdir`
	filesnumcount=`ls $crbtworkdir|wc -l|tail -1|awk '{print $1}'`
	let crbtrecordnum=crbtrecordnum+filesnumcount
	echo "$dS|$d1dayago|${crbt_record_num}|$crbtrecordnum" >>$jilu
	if [ $? = 0 ]
	then
		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01,stat02) values ('$alljobid','$hostname','$wai','$dSn',1,'$dSn',2,'${crbt_record_num}','$crbtrecordnum')"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS crbt昨天话单量 导入inms_pm_data成功"
		else
			log4s "$dS ERROR crbt昨天话单量 导入inms_pm_data失败"
			echo "$alljobid|$hostname|$wai|||$dSn|1|$dSn|2|${crbt_record_num}|$crbtrecordnum||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
		fi
		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$alljobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS crbt昨天话单量 导入inms_pm_datamgr成功"
		else
			log4s "$dS ERROR crbt昨天话单量 导入inms_pm_datamgr失败"
			echo "$alljobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
		fi
	else
		SendAlarm "获取crbt话单异常，请检查文件或者脚本" crbt
	fi
	log4s "$dS|$d1dayago|${crbt_record_num}|$crbtrecordnum"
}

vrbtgo()
{
	vrbtinitfile;
	vrbtrecordnum=`getfilenum $vrbtworkdir`
	echo "$dS|$d1dayago|${vrbt_record_num}|$vrbtrecordnum" >>$jilu
	if [ $? = 0 ]
	then
		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01,stat02) values ('$alljobid','$hostname','$wai','$dSn',1,'$dSn',2,'${vrbt_record_num}','$vrbtrecordnum')"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS vrbt昨天话单量 导入inms_pm_data成功"
		else
			log4s "$dS ERROR vrbt昨天话单量 导入inms_pm_data失败"
			echo "$alljobid|$hostname|$wai|||$dSn|1|$dSn|2|${crbt_record_num}|$vrbtrecordnum||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
		fi
		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$alljobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS vrbt昨天话单量 导入inms_pm_datamgr成功"
		else
			log4s "$dS ERROR vrbt昨天话单量 导入inms_pm_datamgr失败"
			echo "$alljobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
		fi
	else
		SendAlarm "获取vrbt话单异常，请检查文件或者脚本" vrbt
	fi
	log4s "$dS|$d1dayago|${vrbt_record_num}|$vrbtrecordnum"
}
shibaichakan()
{
	#查看入库失败文件
	baddatafilenum=`ls $dodir/bad.inms_pm_data.*.unl 2>/dev/null |wc -l|awk '{print $1}'`
	if [ $baddatafilenum != 0 ]
	then
		badnum=`wc -l $dodir/bad.inms_pm_data.*.unl|tail -1|awk '{print $1}'`
		if [ X$badnum != X0 ]
		then
			SendAlarm "有失败文件，请注意"
		fi
	fi
	baddatamgrfilenum=`ls $dodir/bad.inms_pm_datamgr.*.unl 2>/dev/null |wc -l|awk '{print $1}'`
	if [ $baddatamgrfilenum != 0 ]
	then
		badnum=`wc -l $dodir/bad.inms_pm_datamgr.*.unl|tail -1|awk '{print $1}'`
		if [ X$badnum != X0 ]
		then
			SendAlarm "有失败文件，请注意"
		fi
	fi
}
bijiaocrbt()
{

	#crbt比较
	d1dnum=`grep "${crbt_record_num}" $jilu|grep $d1dayago|tail -1|awk -F'|' '{print $4}'`
	d2dnum=`grep "${crbt_record_num}" $jilu|grep $d2dayago|tail -1|awk -F'|' '{print $4}'`
	if [ X$d1dnum = X0 ] || [ X$d1dnum = X ]
	then
		SendAlarm "昨天crbt话单异常请查看" crbt
	fi
	if [ X$d2dnum = X ]
	then
		log4s "bijiaocrbt 音频总量环比 没有前天记录，不做比较"
		return 0;
	else
		if [ $d1dnum -gt $d2dnum ]
		then
			a=$d1dnum
			b=$d2dnum
		else
			a=$d2dnum
			b=$d1dnum
		fi
		PERCENTAGE=$(printf "%d" $(((a-b)*100/d2dnum)))
		if [ $PERCENTAGE -ge $wucha ]
		then
			SendAlarm "$dS crbt话单 ${d1dayago}值为：${d1dnum}，${d2dayago}值为：${d2dnum} ，差值超过百分之$wucha，请注意核查" crbt
		else
			log4s "$dS crbt话单正常"
		fi
	fi

}
bijiaovrbt()
{
	#vrbt比较
	vd1dnum=`grep "${vrbt_record_num}" $jilu|grep $d1dayago|tail -1|awk -F'|' '{print $4}'`
	vd2dnum=`grep "${vrbt_record_num}" $jilu|grep $d2dayago|tail -1|awk -F'|' '{print $4}'`
	if [ X$vd1dnum = X0 ] || [ X$vd1dnum = X ]
	then
		SendAlarm "昨天vrbt话单异常请查看" vrbt
	fi
	if [ X$vd2dnum = X ]
	then
		log4s "bijiaovrbt 视频总量环比 没有前天记录，不做比较"
		return 0;
	else
		if [ $vd1dnum -gt $vd2dnum ]
		then
			a=$vd1dnum
			b=$vd2dnum
		else
			a=$vd2dnum
			b=$vd1dnum
		fi
		PERCENTAGE=$(printf "%d" $(((a-b)*100/vd2dnum)))
		if [ $PERCENTAGE -ge $wucha ]
		then
			SendAlarm "$dS crbt话单 ${d1dayago}值为：${vd1dnum}，${d2dayago}值为：${vd2dnum} ，差值超过百分之10，请注意核查" crbt
		else
			log4s "$dS vrbt话单正常"
		fi
	fi
}
gosqlite3()
{
	echo "$1"|sqlite3 ${dodir}/hb.temp.db.$dS
}
orihbbijiao()
{
	#$1是vrbt还是crbt还是all
	xd2dnum=`grep $d2dayago $jilu|wc -l|awk '{print $1}'`
	if [ $xd2dnum -gt 0 ]
	then
		if [ X$1 = Xcrbt ]
		then
			mustnum1=`echo ${#crbtorifilenames[@]}`
			mustnum2=0
			let mustnum=mustnum1+mustnum2+2
		elif [ X$1 = Xvrbt ]
		then
			mustnum1=0
			mustnum2=`echo ${#vrbtorifilenames[@]}`
			let mustnum=mustnum1+mustnum2+2
		elif [ X$1 = Xall ]
		then
			mustnum1=`echo ${#crbtorifilenames[@]}`
			mustnum2=`echo ${#vrbtorifilenames[@]}`
			let mustnum=mustnum1+mustnum2+4
		else
			SendAlarm "orihbbijiao 参数不正确" $1
		fi

		if [ X$mustnum = X$xd2dnum ]
		then
			gosqlite3 "create table hbori(worktime text,datatime integer,content text,datanum integer);"
			gosqlite3 ".import ${jilu} hbori"
			gosqlite3 "select b.content,ABS((b.datanum-a.datanum)*100/a.datanum),a.datanum,b.datanum from hbori a , hbori b where a.content=b.content and a.datatime=$d1dayago and b.datatime=$d2dayago;" > $dodir/orihbbijiao.log.$dS
			while read hang
			do
				a1=`echo $hang|awk -F'|' '{print $1}'`
				a2=`echo $hang|awk -F'|' '{print $2}'`
				a3=`echo $hang|awk -F'|' '{print $3}'`
				a4=`echo $hang|awk -F'|' '{print $4}'`

				if [ X$a2 = X ]
				then
					SendAlarm "$a1 $d1dayago 值为 0 ，$d2dayago 值为 $a4，误差无限大，请注意核查" $1
				else
					if [ $a2 -ge $wucha ]
					then
						SendAlarm "$a1 $d1dayago 值为 $a3 ，$d2dayago 值为 $a4 ，差值超过百分之$wucha，请注意核查" $1
					fi
				fi 
			done <$dodir/orihbbijiao.log.$dS
			
			
		else
			SendAlarm "昨天的记录个数不对，无法进行对比" $1
		fi
		rm ${dodir}/orihbbijiao.log.$dS
		rm ${dodir}/hb.temp.db.$dS
	else
		log4s "orihbbijiao 分单位环比 没有前天记录，无法比较"
	fi
	

}
orifinalbijiao()
{
	#$1是vrbt还是crbt还是all
	if [ X$1 = Xcrbt ]
	then
		crbtorinum=`grep $d1dayago $jilu|grep ${crbtori_record_num}|tail -1|awk -F'|' '{print $4}'`
		crbtfinalnum=`grep $d1dayago $jilu|grep ${crbt_record_num}|tail -1|awk -F'|' '{print $4}'`
		tfcrbtPERCENTAGE=$(printf "%d" $(((crbtorinum-crbtfinalnum)*100/crbtorinum)))
		fcrbtPERCENTAGE=`echo ${tfcrbtPERCENTAGE#-}`
		if [ $fcrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "音频彩铃呼叫话单：原始文件数量为：${crbtorinum}，最终文件数量为：${crbtfinalnum}，差值为：${fcrbtPERCENTAGE}，超过了百分之${orifinalwucha}" crbt
		else
			log4s "音频彩铃呼叫话单：原始文件数量为：${crbtorinum}，最终文件数量为：${crbtfinalnum}，差值为：${fcrbtPERCENTAGE}，小于提前设定的百分之${orifinalwucha}，误差正常"
		fi
	elif [ X$1 = Xvrbt ]
	then
		vrbtorinum=`grep $d1dayago $jilu|grep ${vrbtori_record_num}|tail -1|awk -F'|' '{print $4}'`
		vrbtfinalnum=`grep $d1dayago $jilu|grep ${vrbt_record_num}|tail -1|awk -F'|' '{print $4}'`
		tfvrbtPERCENTAGE=$(printf "%d" $(((vrbtorinum-vrbtfinalnum)*100/vrbtorinum)))
		fvrbtPERCENTAGE=`echo ${tfvrbtPERCENTAGE#-}`
		if [ $fvrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "视频彩铃呼叫话单：原始文件数量为：${vrbtorinum}，最终文件数量为：${vrbtfinalnum}，差值为：${fvrbtPERCENTAGE}，超过了百分之${orifinalwucha}" vrbt
		else
			log4s "视频彩铃呼叫话单：原始文件数量为：${vrbtorinum}，最终文件数量为：${vrbtfinalnum}，差值为：${fvrbtPERCENTAGE}，小于提前设定的百分之${orifinalwucha}，误差正常"
		fi
	elif [ X$1 = Xall ]
	then
		crbtorinum=`grep $d1dayago $jilu|grep ${crbtori_record_num}|tail -1|awk -F'|' '{print $4}'`
		vrbtorinum=`grep $d1dayago $jilu|grep ${vrbtori_record_num}|tail -1|awk -F'|' '{print $4}'`
		crbtfinalnum=`grep $d1dayago $jilu|grep ${crbt_record_num}|tail -1|awk -F'|' '{print $4}'`
		vrbtfinalnum=`grep $d1dayago $jilu|grep ${vrbt_record_num}|tail -1|awk -F'|' '{print $4}'`
		tfcrbtPERCENTAGE=$(printf "%d" $(((crbtorinum-crbtfinalnum)*100/crbtorinum)))
		fcrbtPERCENTAGE=`echo ${tfcrbtPERCENTAGE#-}`
		tfvrbtPERCENTAGE=$(printf "%d" $(((vrbtorinum-vrbtfinalnum)*100/vrbtorinum)))
		fvrbtPERCENTAGE=`echo ${tfvrbtPERCENTAGE#-}`
		if [ $fcrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "音频彩铃呼叫话单：原始文件数量为：${crbtorinum}，最终文件数量为：${crbtfinalnum}，差值为：${fcrbtPERCENTAGE}，超过了百分之${orifinalwucha}" crbt
		else
			log4s "音频彩铃呼叫话单：原始文件数量为：${crbtorinum}，最终文件数量为：${crbtfinalnum}，差值为：${fcrbtPERCENTAGE}，小于提前设定的百分之${orifinalwucha}，误差正常"
		fi
		if [ $fvrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "视频彩铃呼叫话单：原始文件数量为：${vrbtorinum}，最终文件数量为：${vrbtfinalnum}，差值为：${fvrbtPERCENTAGE}，超过了百分之${orifinalwucha}" vrbt
		else
			log4s "视频彩铃呼叫话单：原始文件数量为：${vrbtorinum}，最终文件数量为：${vrbtfinalnum}，差值为：${fvrbtPERCENTAGE}，小于提前设定的百分之${orifinalwucha}，误差正常"
		fi
	else
		SendAlarm "orifinalbijiao 参数不正确" $1
	fi
}

shibai()
{
	baddata=`ls $dodir/bad.inms_pm_data.*.unl 2>/dev/null|wc -l|awk '{print $1}'`
	if [ X$baddata != X ] && [ X$baddata != X0 ]
	then
		log4s "存在inms_pm_data失败文件"
		cat $dodir/bad.inms_pm_data.*.unl > $dodir/failresent_data.unl.temp
		cat $dodir/failresent_data.unl.temp|awk 'BEGIN{FS=OFS="|"}{$8="'"$dSn"'"}{print $0}' >$dodir/failresent_data.unl
		echo "load from $dodir/failresent_data.unl insert into inms_pm_data"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS 失败重传inms_pm_data成功"
			rm $dodir/bad.inms_pm_data.*.unl
			rm $dodir/failresent_data.unl.temp
			rm $dodir/failresent_data.unl
		else
			log4s "$dS ERROR 失败重传inms_pm_data失败"
			rm $dodir/failresent_data.unl.temp
			rm $dodir/failresent_data.unl
		fi
	fi
	
	badmgr=`ls $dodir/bad.inms_pm_datamgr.*.unl 2>/dev/null|wc -l|awk '{print $1}'`
	if [ X$badmgr != X ] && [ X$badmgr != X0 ]
	then
		log4s "存在inms_pm_datamgr失败文件"
		cat $dodir/bad.inms_pm_datamgr.*.unl > $dodir/failresent_datamgr.unl
		echo "load from $dodir/failresent_datamgr.unl insert into inms_pm_datamgr"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS 失败重传inms_pm_datamgr成功"
			rm $dodir/bad.inms_pm_datamgr.*.unl
			rm $dodir/failresent_datamgr.unl
		else
			log4s "$dS ERROR 失败重传inms_pm_datamgr失败"
			rm $dodir/failresent_datamgr.unl
		fi
	fi
}
if [ X$1 = Xcrbt ]
then
	shibai
	crbtgo
	crbtorigo
	bijiaocrbt
	orihbbijiao crbt
	orifinalbijiao crbt
elif	[ X$1 = Xvrbt ]
then
	shibai
	vrbtgo
	vrbtorigo
	bijiaovrbt
	orihbbijiao vrbt
	orifinalbijiao vrbt
elif [ X$1 = Xall ]
then
	shibai
	crbtgo
	vrbtgo
	crbtorigo
	vrbtorigo
	bijiaocrbt
	bijiaovrbt
	
	orihbbijiao all
	orifinalbijiao all
	

else
	echo "参数错误，使用方式为：commadn [crbt|vrbt|all]"

fi
