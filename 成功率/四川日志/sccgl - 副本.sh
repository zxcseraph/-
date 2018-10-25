#!/bin/sh
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
d7dayago=`date -d "7 day ago" +"%Y%m%d"`
dodir=/home/informix/tongji    #操作目录，也就是脚本所放的目录
bakdir=$dodir/bak
rizhilog=/home/informix/tongji/prbt.log  #日志全路径
log=$dodir/root.log
resultfile=$dodir/result.log.$dS
databasename=appdb1	#数据库库名
servername=test			#数据库servername
autofailresent=1   #失败自动重传，0为需要手动执行，1为自动重传
jiange=5			#时间间隔，根据配置的cron来填写
fengetype=1   #日志分割模式，1为日期分割。待扩展
fengeflag=1   #分割后缀名，1为".2018-01-02"。待扩展
RingString="UserToneManageImpl.orderTone"
RingString1="toneType=1"
RingsetString="UserToneManageImpl.orderTone"
RingsetString1="toneType=2"
AddToneString="UserToneManageImpl.addSetting"
UserManagerString="UserManageImpl.subscribe"
Ringfilter=("returnCode=000000")
Ringsetfilter=("returnCode=000000" "returnCode=000001")
AddTonefilter=("returnCode=000000")
UserManagerfilter=("returnCode=000000" "returnCode=000001")
wai=`whoami`
hostname=`hostname`
if [ ! -f $rizhilog ]
then
	echo "指定日志文件$rizhilog不存在"
	exit 1;
fi
if [ ! -d $dodir ]
then
	echo "操作目录$dodir不存在"
	exit 1;
fi
log4s()
{
	echo "$1" >> $log
	echo "$1"
}

SendAlarm()
{
	#该参数负责将需要上报的参数进行上报
	echo "$1"
}
tongji()
{
	#第一个参数是关键字，第二个是成功标志数组,第三个关键字是日志名称，第四个是名称，第五个参数额外关键字
	GrepString="$1"
	filter=$2
	logtempname=$4.temp.$dS    #临时文件，统计出全量，为了处理速度快
	lasttagfile=$4.old     #跑过一次之后的证据
	lasttimefile=$3.`date -d "yesterday" +%Y-%m-%d`
	>$logtempname
	if [ X$5 = X ]
	then
		if [ $dHonly -eq 0 ] && [ $dMonly -le 5 ]
		then
			grep "$GrepString" $lasttimefile >> $logtempname
		fi
		grep "$GrepString" $3 >> $logtempname
	else
		if [ $dHonly -eq 0 ] && [ $dMonly -le 5 ]
		then
			grep "$GrepString" $lasttimefile|grep "$5" >> $logtempname
		fi
		grep "$GrepString" $3|grep "$5" >> $logtempname
	fi
	#当前获取的总数
	allnum=`wc -l $logtempname|awk '{print $1}'`
	
	#当前获取的成功总数
	oknum=0
	for i in ${filter[*]}; do
    oktempnum=`grep "$i" $logtempname|wc -l|awk '{print $1}'`
    let oknum=oknum+oktempnum
  done
	
	if [ ! -f $lasttagfile ]
	then
		echo "$dS|$4|$allnum|$oknum" >> $lasttagfile
		echo "$dS|$4|$allnum|$oknum" >> $resultfile
		log4s "${4}第一次运行，当前总数:$allnum,当前成功总数:$oknum"
		rm $logtempname
	else
		oldallnum=`tail -1 $lasttagfile|awk -F'|' '{print $3}'`
		if [ $? != 0 ]
		then
			log4s "$dS ERROR 获取$lasttagfile中数据失败"
			exit 1;
		fi
		oldoknum=`tail -1 $lasttagfile|awk -F'|' '{print $4}'`
		if [ $? != 0 ]
		then
			log4s "$dS ERROR 获取$lasttagfile中数据失败"
			exit 1;
		fi
		let chaallnum=allnum-oldallnum
		let chaoknum=oknum-oldoknum
		if [ X$chaallnum = X ] || [ X$chaoknum = X ]
		then
			log4s "$dS ERROR 计算差值失败"
			exit 1;
		fi
		rm $logtempname
		echo "$dS|$4|$allnum|$oknum" >> $lasttagfile
		echo "$dS|$4|$allnum|$oknum|$chaallnum|$chaoknum" >> $resultfile
		log4s "${4}不是第一次运行，当前总数:$allnum,当前成功总数:$oknum,和上一次的总数差:$chaallnum,和上一次的成功差:$chaoknum"
	fi
}


shangchuan()
{
	#第一个参数是读取文件
	catlog=$1
	subuserall=`grep usersubscribe $catlog|grep $dS|awk -F'|' '{print $5}'`
	subuserok=`grep usersubscribe $catlog|grep $dS|awk -F'|' '{print $6}'`
	addsetall=`grep addSetting $catlog|grep $dS|awk -F'|' '{print $5}'`
	addsetok=`grep addSetting $catlog|grep $dS|awk -F'|' '{print $6}'`
	ringsetall=`grep ringsetorder $catlog|grep $dS|awk -F'|' '{print $5}'`
	ringsetok=`grep ringsetorder $catlog|grep $dS|awk -F'|' '{print $6}'`
	ringall=`grep ringorder $catlog|grep $dS|awk -F'|' '{print $5}'`
	ringok=`grep ringorder $catlog|grep $dS|awk -F'|' '{print $6}'`
	jiaoyanflag=`grep usersubscribe $catlog|grep $dS|awk -F'|' '{print $1}'`
	if [ X$subuserall = X ] || [ X$subuserok = X ] || [ X$addsetall = X ] || [ X$addsetok = X ] || [ X$ringsetall = X ] || [ X$ringsetok = X ] || [ X$ringall = X ] || [ X$ringok = X ]
	then
		log4s "WARN 没有差值，不上报，请检查是第一次执行还是执行异常"
		exit 0;
	fi
	echo "insert into inms_pm_data (jobid,host,account,pid,tid,endtime,seqno,inserttime,statnum,stat01,stat02,stat03,stat04,stat05,stat06,stat07,stat08) values (\"031017\",\"$hostname\",\"$wai\",\"\",\"\",\"$dSn\",1,\"$dSn\",8,\"$subuserall\",\"$subuserok\",\"$addsetall\",\"$addsetok\",\"$ringsetall\",\"$ringsetok\",\"$ringall\",\"$ringok\")"|dbaccess ${servername}@${databasename}
	if [ $? = 0 ]
	then
		log4s "$dS SUCCESS 导入inms_pm_data成功"
	else
		log4s "$dS ERROR 导入inms_pm_data失败"
		echo "031017|$hostname|$wai|||$dSn|1|$dSn|8|$subuserall|$subuserok|$addsetall|$addsetok|$ringsetall|$ringsetok|$ringall|$ringok||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
	fi
	echo "insert into inms_pm_datamgr (jobid,host,account,pid,tid,endtime,datanum) values (\"031017\",\"$hostname\",\"$wai\",\"\",\"\",\"$dSn\",1)"|dbaccess ${servername}@${databasename}
	if [ $? = 0 ]
	then
		log4s "$dS SUCCESS 导入inms_pm_datamgr成功"
	else
		log4s "$dS ERROR 导入inms_pm_datamgr失败"
		echo "031017|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
	fi
	
	#echo "031017|$hostname|$wai|||$dSn|1|8|$dSn|$subuserall|$subuserok|$addsetall|$addsetok|$ringsetall|$ringsetok|$ringall|$ringok|" >$dodir/finalinms_pm_data.$dS.unl
	#echo "031017|$hostname|$wai|||$dSn|1|">$dodir/finalinms_pm_datamgr.$dS.unl
	#
	#echo "load from $dodir/finalinms_pm_data.$dS.unl insert into inms_pm_data"|dbaccess ${servername}@${databasename}
	#echo "load from $dodir/finalinms_pm_datamgr.$dS.unl insert into inms_pm_datamgr"|dbaccess ${servername}@${databasename}
}



shibai()
{
	baddata=`ls $dodir/bad.inms_pm_data.*.unl 2>/dev/null|wc -l|awk '{print $1}'`
	if [ X$baddata != X ] && [ X$baddata != X0 ]
	then
		log4s "存在inms_pm_data失败文件"
		cat $dodir/bad.inms_pm_data.*.unl > $dodir/failresent_data.unl.temp
		cat $dodir/failresent_data.unl.temp|awk 'BEGIN{FS=OFS="|"}{$8="'"$dSn"'"}{print $0}' >$dodir/failresent_data.unl
		echo "load from $dodir/failresent_data.unl insert into inms_pm_data"|dbaccess ${servername}@${databasename}
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
		echo "load from $dodir/failresent_datamgr.unl insert into inms_pm_datamgr"|dbaccess ${servername}@${databasename}
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
if [ $# != 1 ]
then
	log4s "参数个数不对，请使用go或者chongchuan"
fi
if [ X$1 = Xgo ]
then
	if [ $autofailresent = 1 ]
	then
		shibai
	fi
	
	tongji $RingString    			"${Ringfilter[*]}"    			$rizhilog  "ringorder"       $RingString1
	tongji $RingsetString 			"${Ringsetfilter[*]}" 			$rizhilog  "ringsetorder"    $RingsetString1
	tongji $AddToneString 			"${AddTonefilter[*]}" 			$rizhilog  "addSetting"
	tongji $UserManagerString 	"${UserManagerfilter[*]}"	  $rizhilog  "usersubscribe"
	shangchuan $resultfile
	
	if [ ! -d $bakdir ]
	then
		mkdir $bakdir
	fi
	mv result.log.${d7dayago}* $bakdir/ 2>/dev/null
fi
if [ X$1 = Xchongchuan ]
then
	shibai
fi
