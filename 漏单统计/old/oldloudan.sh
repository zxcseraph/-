#!/bin/sh

dodir=/home/icaa/zxc/loudan/workdir					#�ű�����Ŀ¼�����в������������Ŀ¼ִ��
shengfencode=02										#ʡ��id�������02
log=$dodir/root.log									#������¼��־
jilu=$dodir/result.log								#��¼ÿ��Ļ�������
alarmlog=$dodir/alarm.log							#��¼���и澯����־
jobid=10086											#���ܷ���������
alarmcode=10010										#�澯id
servername=hdr1										#���ݿ�servername
databasename=test									#���ݿ��ʵ����   ����newip@dbm1��newip����ʵ������dbm1����servername
wucha=10											#���ٷֱȣ���������ű������һ���澯
orifinalwucha=1										#ԭʼ�ļ��������ļ������ٷֱ�
d1dayago=`date -d "-1 days" +"%Y%m%d"`
d2dayago=`date -d "-2 days" +"%Y%m%d"`
#��Ƶ���
#��Ƶ������л����ļ���������
crbtfile="VGOP_TONEPLAYINFO_${d1dayago}_${shengfencode}.rar"
#��Ƶԭʼ�ļ���������
crbtorifile="*.SRF.LOG.${d1dayago}*"
#��Ƶԭʼ�ļ������������Ҫ���ֵ��˻��������������˻���
crbtorifilenames=("AS61" "AS62" "CN41" "CN42" "CN51" "CN52")
#��Ƶ�ļ����Ŀ¼
crbtfiledir=/data/log/image/data/TonePlayInfo
#��Ƶԭʼ�ļ����Ŀ¼
crbtfileoridir=/data/log/
#��Ƶ�ļ���ʱ����Ŀ¼
crbtworkdir=$dodir/crbt
#��Ƶԭʼ�ļ���ʱ����Ŀ¼
crbtworkdirori=$dodir/crbtori

#��Ƶ���
#��Ƶ������л����ļ���������
vrbtfile="CLJZ_V_TONEPLAYINFO_${d1dayago}????_${shengfencode}.zip"
#��Ƶԭʼ�ļ���������
vrbtorifile="*.SRF.LOG.${d1dayago}*"
#��Ƶԭʼ�ļ���������ͬ��Ƶ
vrbtorifilenames=("AS61" "AS62")
#��Ƶ�ļ����Ŀ¼
vrbtfiledir=/home/recftp/logfile/bak
#��Ƶԭʼ�ļ����Ŀ¼
vrbtfileoridir=/home/icaa/zxc/shipinyuanshi
#��Ƶ�ļ���ʱ����Ŀ¼
vrbtworkdir=$dodir/vrbt
#��Ƶԭʼ�ļ���ʱ����Ŀ¼
vrbtworkdirori=$dodir/vrbtori

d1dayY=${d1dayago:3:1}
d1daym=${d1dayago:5:1}
d1dayd=${d1dayago:6:2}
#��Ƶ�ļ�����
mima=${d1dayY}${d1daym}${d1dayd}@${shengfencode}
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
hostname=`hostname`
wai=`whoami`
#�����Ǹ��ֱ�־
crbt_record_num=last_crbt_record_num					#������Ƶ�����ļ�
vrbt_record_num=last_vrbt_record_num					#������Ƶ�����ļ�
crbtori_record_num=last_crbtori_record_num		#������Ƶ����֮ǰ�ļ�
vrbtori_record_num=last_vrbtori_record_num		#������Ƶ����֮ǰ�ļ�
lastday_crbtoripre=lastday_crbtori_						#������Ƶ����֮ǰ�ļ��ľ������������˻�ǰ׺��־
lastday_vrbtoripre=lastday_vrbtori_						#������Ƶ����֮ǰ�ļ��ľ������������˻�ǰ׺��־
log4s()
{
	echo "$dS $1" >> $log
	echo "$dS $1"
}
SendAlarm()
{
	log4s "$1"
	echo "$dS $hostname $alarmcode $1" >>$alarmlog
}

pdir()
{
	if [ ! -d $1 ]
	then
		mkdir $1
		log4s "$1 �����ڣ�����$1"
		if [ $? = 0 ]
		then
			log4s "����$1�ɹ�"
		else
			log4s "����$1ʧ��"
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
	#��ʼcrbt�ĳ�ʼ������
	log4s "��ʼcrbt��ʼ������"
	rm -rf $crbtworkdir/*
	cp $crbtfiledir/$crbtfile $crbtworkdir;
	if [ $? != 0 ]
	then
		SendAlarm "�ļ������ڣ���Ƶ���廰��ԭʼ�ļ�������"
	fi
	cd $crbtworkdir;
	unzip -P $mima $crbtfile
	rm -rf $crbtfile
	crbtfilenum=`ls $crbtworkdir 2>/dev/null|wc -l|awk '{print $1}'`
	if [ $crbtfilenum = 0 ]
	then
		SendAlarm "�ļ���������Ƶ���廰������Ϊ��"
	fi
}

vrbtinitfile()
{
	#��ʼvrbt�ĳ�ʼ������
	log4s "��ʼvrbt��ʼ������"
	rm -rf $vrbtworkdir/*
	cp $vrbtfiledir/$vrbtfile $vrbtworkdir;
	if [ $? != 0 ]
	then
		SendAlarm "�ļ������ڣ���Ƶ���廰�������ļ�������"
	fi
	cd $vrbtworkdir;
	unzip "*.zip";
	rm -rf $vrbtworkdir/$vrbtfile
	vrbtfilenum=`ls $vrbtworkdir 2>/dev/null|wc -l|awk '{print $1}'`
	if [ $vrbtfilenum = 0 ]
	then
		SendAlarm "�ļ���������Ƶ���廰������Ϊ��"
	fi
}
getfilenum()
{
	#$1�ǲ���Ŀ¼��$2������˵��
	cd $1;
	getnum=`wc -l *|tail -1|awk '{print $1}'`
	echo "$dS|$d1dayago|$2|$getnum" >>$jilu
	echo "$getnum"
}
crbtorigo()
{
	#��ʼcrbtԭʼ�ļ��ĳ�ʼ������
	log4s "��ʼcrbtԭʼ�ļ���ʼ������"
	rm -rf $crbtworkdirori/*
	cp $crbtfileoridir/$crbtorifile $crbtworkdirori;
	if [ $? != 0 ]
	then
		SendAlarm "�ļ������ڣ���Ƶ���廰��ԭʼ�����ļ�������"
	fi
	cd $crbtworkdirori;
	crbtorifilesumnnum=`wc -l $crbtworkdirori/*|tail -1|awk '{print $1}'`
	if [ $? = 0 ]
	then
		echo "$dS|$d1dayago|${crbtori_record_num}|$crbtorifilesumnnum" >>$jilu
		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01,stat02,stat03) values ('$jobid','$hostname','$wai','$dSn',1,'$dSn',3,'${crbtori_record_num}','$crbtorifilesumnnum',$d1dayago)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS ԭʼ�ļ��������컰���� ����inms_pm_data�ɹ�"
		else
			log4s "$dS ERROR ԭʼ�ļ��������컰���� ����inms_pm_dataʧ��"
			echo "$jobid|$hostname|$wai|||$dSn|1|$dSn|2|${crbtori_record_num}|$crbtorifilesumnnum|$d1dayago|||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
		fi
		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$jobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS ԭʼ�ļ��������컰���� ����inms_pm_datamgr�ɹ�"
		else
			log4s "$dS ERROR ԭʼ�ļ��������컰���� ����inms_pm_datamgrʧ��"
			echo "$jobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
		fi
	else
		SendAlarm "��ȡcrbtԭʼ�ļ����������쳣�������ļ����߽ű�"
	fi
	log4s "$dS|$d1dayago|${crbtori_record_num}|$crbtorifilesumnnum"
	
	
	for i in ${crbtorifilenames[*]}
	do
		hostnum=`wc -l ${i}*|tail -1|awk '{print $1}'`
		if [ $? = 0 ]
		then
			echo "$dS|$d1dayago|${lastday_crbtoripre}${i}|$hostnum" >>$jilu
			echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01,stat02,stat03) values ('$jobid','$hostname','$wai','$dSn',1,'$dSn',3,'${lastday_crbtoripre}${i}','$hostnum',$d1dayago)"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${i}���컰���� ����inms_pm_data�ɹ�"
			else
				log4s "$dS ERROR ${i}���컰���� ����inms_pm_dataʧ��"
				echo "$jobid|$hostname|$wai|||$dSn|1|$dSn|2|${lastday_crbtoripre}${i}|$hostnum|$d1dayago|||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
			fi
			echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$jobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${i}���컰���� ����inms_pm_datamgr�ɹ�"
			else
				log4s "$dS ERROR ${i}���컰���� ����inms_pm_datamgrʧ��"
				echo "$jobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
			fi
		else
			SendAlarm "��ȡ${i}�����쳣�������ļ����߽ű�"
		fi
		log4s "$dS|$d1dayago|${lastday_crbtoripre}${i}|$hostnum"
	done
}
vrbtorigo()
{
	#��ʼvrbtԭʼ�ļ��ĳ�ʼ������
	log4s "��ʼvrbtԭʼ�ļ���ʼ������"
	rm -rf $vrbtworkdirori/*
	cp $vrbtfileoridir/$vrbtorifile $vrbtworkdirori;
	if [ $? != 0 ]
	then
		SendAlarm "�ļ������ڣ���Ƶ���廰��ԭʼ�����ļ�������"
	fi
	cd $vrbtworkdirori;
	vrbtorifilesumnnum=`wc -l $vrbtworkdirori/*|tail -1|awk '{print $1}'`
	if [ $? = 0 ]
	then
		echo "$dS|$d1dayago|${vrbtori_record_num}|$vrbtorifilesumnnum" >>$jilu
		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01,stat02,stat03) values ('$jobid','$hostname','$wai','$dSn',1,'$dSn',3,'${vrbtori_record_num}','$vrbtorifilesumnnum',$d1dayago)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS ԭʼ�ļ��������컰���� ����inms_pm_data�ɹ�"
		else
			log4s "$dS ERROR ԭʼ�ļ��������컰���� ����inms_pm_dataʧ��"
			echo "$jobid|$hostname|$wai|||$dSn|1|$dSn|2|${vrbtori_record_num}|$vrbtorifilesumnnum|$d1dayago|||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
		fi
		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$jobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS ԭʼ�ļ��������컰���� ����inms_pm_datamgr�ɹ�"
		else
			log4s "$dS ERROR ԭʼ�ļ��������컰���� ����inms_pm_datamgrʧ��"
			echo "$jobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
		fi
	else
		SendAlarm "��ȡvrbtԭʼ�ļ����������쳣�������ļ����߽ű�"
	fi
	log4s "$dS|$d1dayago|${vrbtori_record_num}|$vrbtorifilesumnnum"
	
	
	for i in ${vrbtorifilenames[*]}
	do
		hostnum=`wc -l ${i}*|tail -1|awk '{print $1}'`
		if [ $? = 0 ]
		then
			echo "$dS|$d1dayago|${lastday_vrbtoripre}${i}|$hostnum" >>$jilu
			echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01,stat02,stat03) values ('$jobid','$hostname','$wai','$dSn',1,'$dSn',3,'${lastday_vrbtoripre}${i}','$hostnum',$d1dayago)"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${i}���컰���� ����inms_pm_data�ɹ�"
			else
				log4s "$dS ERROR ${i}���컰���� ����inms_pm_dataʧ��"
				echo "$jobid|$hostname|$wai|||$dSn|1|$dSn|2|${lastday_vrbtoripre}${i}|$hostnum|$d1dayago|||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
			fi
			echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$jobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${i}���컰���� ����inms_pm_datamgr�ɹ�"
			else
				log4s "$dS ERROR ${i}���컰���� ����inms_pm_datamgrʧ��"
				echo "$jobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
			fi
		else
			SendAlarm "��ȡ${i}�����쳣�������ļ����߽ű�"
		fi
		log4s "$dS|$d1dayago|${lastday_vrbtoripre}${i}|$hostnum"
	done
}
crbtgo()
{
	crbtinitfile;
	crbtrecordnum=`getfilenum $crbtworkdir "${crbt_record_num}"`
	if [ $? = 0 ]
	then
		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01,stat02,stat03) values ('$jobid','$hostname','$wai','$dSn',1,'$dSn',3,'${crbt_record_num}','$crbtrecordnum',$d1dayago)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS crbt���컰���� ����inms_pm_data�ɹ�"
		else
			log4s "$dS ERROR crbt���컰���� ����inms_pm_dataʧ��"
			echo "$jobid|$hostname|$wai|||$dSn|1|$dSn|2|${crbt_record_num}|$crbtrecordnum|$d1dayago|||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
		fi
		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$jobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS crbt���컰���� ����inms_pm_datamgr�ɹ�"
		else
			log4s "$dS ERROR crbt���컰���� ����inms_pm_datamgrʧ��"
			echo "$jobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
		fi
	else
		SendAlarm "��ȡcrbt�����쳣�������ļ����߽ű�"
	fi
	log4s "$dS|$d1dayago|${crbt_record_num}|$crbtrecordnum"
}

vrbtgo()
{
	vrbtinitfile;
	vrbtrecordnum=`getfilenum $vrbtworkdir "${vrbt_record_num}"`
	if [ $? = 0 ]
	then
		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01,stat02,stat03) values ('$jobid','$hostname','$wai','$dSn',1,'$dSn',3,'${vrbt_record_num}','$vrbtrecordnum',$d1dayago)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS vrbt���컰���� ����inms_pm_data�ɹ�"
		else
			log4s "$dS ERROR vrbt���컰���� ����inms_pm_dataʧ��"
			echo "$jobid|$hostname|$wai|||$dSn|1|$dSn|3|${crbt_record_num}|$vrbtrecordnum|$d1dayago|||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
		fi
		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$jobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS vrbt���컰���� ����inms_pm_datamgr�ɹ�"
		else
			log4s "$dS ERROR vrbt���컰���� ����inms_pm_datamgrʧ��"
			echo "$jobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
		fi
	else
		SendAlarm "��ȡvrbt�����쳣�������ļ����߽ű�"
	fi
	log4s "$dS|$d1dayago|${vrbt_record_num}|$vrbtrecordnum"
}
shibaichakan()
{
	#�鿴���ʧ���ļ�
	baddatafilenum=`ls $dodir/bad.inms_pm_data.*.unl 2>/dev/null |wc -l|awk '{print $1}'`
	if [ $baddatafilenum != 0 ]
	then
		badnum=`wc -l $dodir/bad.inms_pm_data.*.unl|tail -1|awk '{print $1}'`
		if [ X$badnum != X0 ]
		then
			SendAlarm "��ʧ���ļ�����ע��"
		fi
	fi
	baddatamgrfilenum=`ls $dodir/bad.inms_pm_datamgr.*.unl 2>/dev/null |wc -l|awk '{print $1}'`
	if [ $baddatamgrfilenum != 0 ]
	then
		badnum=`wc -l $dodir/bad.inms_pm_datamgr.*.unl|tail -1|awk '{print $1}'`
		if [ X$badnum != X0 ]
		then
			SendAlarm "��ʧ���ļ�����ע��"
		fi
	fi
}
bijiaocrbt()
{

	#crbt�Ƚ�
	d1dnum=`grep "${crbt_record_num}" $jilu|grep $d1dayago|tail -1|awk -F'|' '{print $4}'`
	d2dnum=`grep "${crbt_record_num}" $jilu|grep $d2dayago|tail -1|awk -F'|' '{print $4}'`
	if [ X$d1dnum = X0 ] || [ X$d1dnum = X ]
	then
		SendAlarm "����crbt�����쳣��鿴"
	fi
	if [ X$d2dnum = X ]
	then
		log4s "bijiaocrbt ��Ƶ�������� û��ǰ���¼�������Ƚ�"
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
			SendAlarm "$dS crbt���� ${d1dayago}ֵΪ��${d1dnum}��${d2dayago}ֵΪ��${d2dnum} ����ֵ�����ٷ�֮$wucha����ע��˲�"
		else
			log4s "$dS crbt��������"
		fi
	fi

}
bijiaovrbt()
{
	#vrbt�Ƚ�
	vd1dnum=`grep "${vrbt_record_num}" $jilu|grep $d1dayago|tail -1|awk -F'|' '{print $4}'`
	vd2dnum=`grep "${vrbt_record_num}" $jilu|grep $d2dayago|tail -1|awk -F'|' '{print $4}'`
	if [ X$vd1dnum = X0 ] || [ X$vd1dnum = X ]
	then
		SendAlarm "����crbt�����쳣��鿴"
	fi
	if [ X$vd2dnum = X ]
	then
		log4s "bijiaovrbt ��Ƶ�������� û��ǰ���¼�������Ƚ�"
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
			SendAlarm "$dS crbt���� ${d1dayago}ֵΪ��${vd1dnum}��${d2dayago}ֵΪ��${vd2dnum} ����ֵ�����ٷ�֮10����ע��˲�"
		else
			log4s "$dS vrbt��������"
		fi
	fi
}
gosqlite3()
{
	echo "$1"|sqlite3 ${dodir}/hb.temp.db.$dS
}
orihbbijiao()
{
	#$1��vrbt����crbt����all
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
			SendAlarm "orihbbijiao ��������ȷ"
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
				if [ $a2 -ge $wucha ]
				then
					SendAlarm "$a1 $d1dayago ֵΪ $a3 ��$d2dayago ֵΪ $a4 ����ֵ�����ٷ�֮$wucha����ע��˲�"
				fi
			done <$dodir/orihbbijiao.log.$dS
			
			
		else
			SendAlarm "����ļ�¼�������ԣ��޷����жԱ�"
		fi
		rm ${dodir}/orihbbijiao.log.$dS
		rm ${dodir}/hb.temp.db.$dS
	else
		log4s "orihbbijiao �ֵ�λ���� û��ǰ���¼���޷��Ƚ�"
	fi
	

}
orifinalbijiao()
{
	#$1��vrbt����crbt����all
	if [ X$1 = Xcrbt ]
	then
		crbtorinum=`grep $d1dayago $jilu|grep ${crbtori_record_num}|tail -1|awk -F'|' '{print $4}'`
		crbtfinalnum=`grep $d1dayago $jilu|grep ${crbt_record_num}|tail -1|awk -F'|' '{print $4}'`
		tfcrbtPERCENTAGE=$(printf "%d" $(((crbtorinum-crbtfinalnum)*100/crbtorinum)))
		fcrbtPERCENTAGE=`echo ${tfcrbtPERCENTAGE#-}`
		if [ $fcrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${crbtorinum}�������ļ�����Ϊ��${crbtfinalnum}����ֵΪ��${fcrbtPERCENTAGE}�������˰ٷ�֮${orifinalwucha}"
		fi
	elif [ X$1 = Xvrbt ]
	then
		vrbtorinum=`grep $d1dayago $jilu|grep ${vrbtori_record_num}|tail -1|awk -F'|' '{print $4}'`
		vrbtfinalnum=`grep $d1dayago $jilu|grep ${vrbt_record_num}|tail -1|awk -F'|' '{print $4}'`
		tfvrbtPERCENTAGE=$(printf "%d" $(((vrbtorinum-vrbtfinalnum)*100/vrbtorinum)))
		fvrbtPERCENTAGE=`echo ${tfvrbtPERCENTAGE#-}`
		if [ $fvrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${vrbtorinum}�������ļ�����Ϊ��${vrbtfinalnum}����ֵΪ��${fvrbtPERCENTAGE}�������˰ٷ�֮${orifinalwucha}"
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
			SendAlarm "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${crbtorinum}�������ļ�����Ϊ��${crbtfinalnum}����ֵΪ��${fcrbtPERCENTAGE}�������˰ٷ�֮${orifinalwucha}"
		fi
		if [ $fvrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${vrbtorinum}�������ļ�����Ϊ��${vrbtfinalnum}����ֵΪ��${fvrbtPERCENTAGE}�������˰ٷ�֮${orifinalwucha}"
		fi
	else
		SendAlarm "orifinalbijiao ��������ȷ"
	fi
}

shibai()
{
	baddata=`ls $dodir/bad.inms_pm_data.*.unl 2>/dev/null|wc -l|awk '{print $1}'`
	if [ X$baddata != X ] && [ X$baddata != X0 ]
	then
		log4s "����inms_pm_dataʧ���ļ�"
		cat $dodir/bad.inms_pm_data.*.unl > $dodir/failresent_data.unl.temp
		cat $dodir/failresent_data.unl.temp|awk 'BEGIN{FS=OFS="|"}{$8="'"$dSn"'"}{print $0}' >$dodir/failresent_data.unl
		echo "load from $dodir/failresent_data.unl insert into inms_pm_data"|dbaccess ${databasename}@${servername}
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
		echo "load from $dodir/failresent_datamgr.unl insert into inms_pm_datamgr"|dbaccess ${databasename}@${servername}
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
	echo "��������ʹ�÷�ʽΪ��commadn [crbt|vrbt|all]"

fi
