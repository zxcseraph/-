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
dodir=/home/informix/tongji    #����Ŀ¼��Ҳ���ǽű����ŵ�Ŀ¼
bakdir=$dodir/bak
rizhilog=/home/informix/tongji/prbt.log  #��־ȫ·��
log=$dodir/root.log
resultfile=$dodir/result.log.$dS
databasename=appdb1	#���ݿ����
servername=test			#���ݿ�servername
autofailresent=1   #ʧ���Զ��ش���0Ϊ��Ҫ�ֶ�ִ�У�1Ϊ�Զ��ش�
jiange=5			#ʱ�������������õ�cron����д
fengetype=1   #��־�ָ�ģʽ��1Ϊ���ڷָ����չ
fengeflag=1   #�ָ��׺����1Ϊ".2018-01-02"������չ
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
	echo "ָ����־�ļ�$rizhilog������"
	exit 1;
fi
if [ ! -d $dodir ]
then
	echo "����Ŀ¼$dodir������"
	exit 1;
fi
log4s()
{
	echo "$1" >> $log
	echo "$1"
}

SendAlarm()
{
	#�ò���������Ҫ�ϱ��Ĳ��������ϱ�
	echo "$1"
}
tongji()
{
	#��һ�������ǹؼ��֣��ڶ����ǳɹ���־����,�������ؼ�������־���ƣ����ĸ������ƣ��������������ؼ���
	GrepString="$1"
	filter=$2
	logtempname=$4.temp.$dS    #��ʱ�ļ���ͳ�Ƴ�ȫ����Ϊ�˴����ٶȿ�
	lasttagfile=$4.old     #�ܹ�һ��֮���֤��
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
	#��ǰ��ȡ������
	allnum=`wc -l $logtempname|awk '{print $1}'`
	
	#��ǰ��ȡ�ĳɹ�����
	oknum=0
	for i in ${filter[*]}; do
    oktempnum=`grep "$i" $logtempname|wc -l|awk '{print $1}'`
    let oknum=oknum+oktempnum
  done
	
	if [ ! -f $lasttagfile ]
	then
		echo "$dS|$4|$allnum|$oknum" >> $lasttagfile
		echo "$dS|$4|$allnum|$oknum" >> $resultfile
		log4s "${4}��һ�����У���ǰ����:$allnum,��ǰ�ɹ�����:$oknum"
		rm $logtempname
	else
		oldallnum=`tail -1 $lasttagfile|awk -F'|' '{print $3}'`
		if [ $? != 0 ]
		then
			log4s "$dS ERROR ��ȡ$lasttagfile������ʧ��"
			exit 1;
		fi
		oldoknum=`tail -1 $lasttagfile|awk -F'|' '{print $4}'`
		if [ $? != 0 ]
		then
			log4s "$dS ERROR ��ȡ$lasttagfile������ʧ��"
			exit 1;
		fi
		let chaallnum=allnum-oldallnum
		let chaoknum=oknum-oldoknum
		if [ X$chaallnum = X ] || [ X$chaoknum = X ]
		then
			log4s "$dS ERROR �����ֵʧ��"
			exit 1;
		fi
		rm $logtempname
		echo "$dS|$4|$allnum|$oknum" >> $lasttagfile
		echo "$dS|$4|$allnum|$oknum|$chaallnum|$chaoknum" >> $resultfile
		log4s "${4}���ǵ�һ�����У���ǰ����:$allnum,��ǰ�ɹ�����:$oknum,����һ�ε�������:$chaallnum,����һ�εĳɹ���:$chaoknum"
	fi
}


shangchuan()
{
	#��һ�������Ƕ�ȡ�ļ�
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
		log4s "WARN û�в�ֵ�����ϱ��������ǵ�һ��ִ�л���ִ���쳣"
		exit 0;
	fi
	echo "insert into inms_pm_data (jobid,host,account,pid,tid,endtime,seqno,inserttime,statnum,stat01,stat02,stat03,stat04,stat05,stat06,stat07,stat08) values (\"031017\",\"$hostname\",\"$wai\",\"\",\"\",\"$dSn\",1,\"$dSn\",8,\"$subuserall\",\"$subuserok\",\"$addsetall\",\"$addsetok\",\"$ringsetall\",\"$ringsetok\",\"$ringall\",\"$ringok\")"|dbaccess ${servername}@${databasename}
	if [ $? = 0 ]
	then
		log4s "$dS SUCCESS ����inms_pm_data�ɹ�"
	else
		log4s "$dS ERROR ����inms_pm_dataʧ��"
		echo "031017|$hostname|$wai|||$dSn|1|$dSn|8|$subuserall|$subuserok|$addsetall|$addsetok|$ringsetall|$ringsetok|$ringall|$ringok||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
	fi
	echo "insert into inms_pm_datamgr (jobid,host,account,pid,tid,endtime,datanum) values (\"031017\",\"$hostname\",\"$wai\",\"\",\"\",\"$dSn\",1)"|dbaccess ${servername}@${databasename}
	if [ $? = 0 ]
	then
		log4s "$dS SUCCESS ����inms_pm_datamgr�ɹ�"
	else
		log4s "$dS ERROR ����inms_pm_datamgrʧ��"
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
		log4s "����inms_pm_dataʧ���ļ�"
		cat $dodir/bad.inms_pm_data.*.unl > $dodir/failresent_data.unl.temp
		cat $dodir/failresent_data.unl.temp|awk 'BEGIN{FS=OFS="|"}{$8="'"$dSn"'"}{print $0}' >$dodir/failresent_data.unl
		echo "load from $dodir/failresent_data.unl insert into inms_pm_data"|dbaccess ${servername}@${databasename}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS ʧ���ش�inms_pm_data�ɹ�"
			rm $dodir/bad.inms_pm_data.*.unl
			rm $dodir/failresent_data.unl.temp
			rm $dodir/failresent_data.unl
		else
			log4s "$dS ERROR ʧ���ش�inms_pm_dataʧ��"
			rm $dodir/failresent_data.unl.temp
			rm $dodir/failresent_data.unl
		fi
	fi
	
	badmgr=`ls $dodir/bad.inms_pm_datamgr.*.unl 2>/dev/null|wc -l|awk '{print $1}'`
	if [ X$badmgr != X ] && [ X$badmgr != X0 ]
	then
		log4s "����inms_pm_datamgrʧ���ļ�"
		cat $dodir/bad.inms_pm_datamgr.*.unl > $dodir/failresent_datamgr.unl
		echo "load from $dodir/failresent_datamgr.unl insert into inms_pm_datamgr"|dbaccess ${servername}@${databasename}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS ʧ���ش�inms_pm_datamgr�ɹ�"
			rm $dodir/bad.inms_pm_datamgr.*.unl
			rm $dodir/failresent_datamgr.unl
		else
			log4s "$dS ERROR ʧ���ش�inms_pm_datamgrʧ��"
			rm $dodir/failresent_datamgr.unl
		fi
	fi
}
if [ $# != 1 ]
then
	log4s "�����������ԣ���ʹ��go����chongchuan"
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
