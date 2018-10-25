#!/bin/sh

dodir=/home/icaa/loudan/workdir         #�ű�����Ŀ¼�����в������������Ŀ¼ִ��
shengfencode=14                         #ʡ��id�������02
log=$dodir/root.log                     #������¼��־
jilu=$dodir/result.log                  #��¼ÿ��Ļ�������
alarmlog=$dodir/alarm.log               #��¼���и澯����־
crbtorijobid=031018                     #���ܷ�����Ƶԭʼ�ļ��������
vrbtorijobid=031019                     #���ܷ�����Ƶԭʼ�ļ��������
alljobid=031020                         #���ܷ��������ļ��������
crbtalarmcode=00003101841               #��Ƶ�澯��
vrbtalarmcode=00003101842               #��Ƶ�澯��
servername=hdr1                         #���ݿ�servername
databasename=zxc                        #���ݿ��ʵ����   ����newip@dbm1��newip����ʵ������dbm1����servername
wucha=10                                #���ٷֱȣ���������ű������һ���澯
orifinalwucha=1                         #ԭʼ�ļ��������ļ������ٷֱ�
new0wucha=1															#��Ƶ�����ļ���000000000000�ĸ�����ǰһ������ٷֱȣ���������͸澯
newerrgeshu=100													#��Ƶ�����ļ���000000000000�ĸ�������������͸澯
d1dayago=`date -d "-24 days" +"%Y%m%d"`
d2dayago=`date -d "-25 days" +"%Y%m%d"`
#��Ƶ���
#��Ƶ������л����ļ���������
crbtfile="VGOP_TONEPLAYINFO_${d1dayago}_${shengfencode}.rar"
#��Ƶԭʼ�ļ���������
crbtorifile="*.SRF.LOG.${d1dayago}*"
#��Ƶԭʼ�ļ������� truecrbthostname���ļ����е��������������е��������Ķ�Ӧ����Ϊ�ļ��е����������Ǵ�д������ʶ��������������Ҫ����һ��ת����crbtorifilenames���ļ��е���������
#declare -A truecrbthostname=(["CLAS11"]="JX-clas11" ["CLAS31"]="JX-clas31" ["NCCN11"]="JX-nccn11" ["NCCN12"]="JX-nccn12" ["NCCN13"]="JX-nccn13" ["NCCN21"]="JX-nccn21" ["NCCN22"]="JX-nccn22" ["NCCN23"]="JX-nccn23" ["NCCN31"]="JX-nccn31" ["NCCN32"]="JX-nccn32" ["NCCN33"]="JX-nccn33")
gettruecrbthostname()
{
	#$1 �ǻ�ȡ���������������������Ҫ���ʽ��������
	case $1 in
		CLAS11)
			echo "JX-clas11"
			;;
		CLAS31)
			echo "JX-clas31"
			;;
		NCCN11)
			echo "JX-nccn11"
			;;
		NCCN12)
			echo "JX-nccn12"
			;;
		NCCN13)
			echo "JX-nccn13"
			;;
		NCCN21)
			echo "JX-nccn21"
			;;
		NCCN22)
			echo "JX-nccn22"
			;;
		NCCN23)
			echo "JX-nccn23"
			;;
		NCCN31)
			echo "JX-nccn31"
			;;
		NCCN32)
			echo "JX-nccn32"
			;;
		NCCN33)
			echo "JX-nccn33"
			;;
		*)
			echo "JX-Unknown"
	esac
}
crbtorifilenames=("CLAS11" "CLAS31" "NCCN11" "NCCN12" "NCCN13" "NCCN21" "NCCN22" "NCCN23" "NCCN31" "NCCN32" "NCCN33")
#��Ƶ�ļ����Ŀ¼
crbtfiledir=/home/icaa/loudan/jxziyuan/crbt
#��Ƶԭʼ�ļ����Ŀ¼
crbtfileoridir=/home/icaa/loudan/jxziyuan/crbtyuanshi
#��Ƶ�ļ���ʱ����Ŀ¼
crbtworkdir=$dodir/crbt
#��Ƶԭʼ�ļ���ʱ����Ŀ¼
crbtworkdirori=$dodir/crbtori
#��Ƶԭʼ�ļ��쳣�������������Ƶԭʼ�ļ�����ͳ�ƾ��ȣ���������Ӱ��ܴ���ȷ���Ƿ�򿪣�1Ϊ�򿪣�0Ϊ�ر�
crbtoriyichang=1
#��Ƶ�����ļ�000000000000����1Ϊ�򿪣�2Ϊ�ر�
new0error=1
#��Ƶ���
#��Ƶ������л����ļ���������
vrbtfile="CLJZ_V_TONEPLAYINFO_${d1dayago}????_${shengfencode}.zip"
#��Ƶԭʼ�ļ���������
vrbtorifile="*.SRF.LOG.*.${d1dayago}*"
#��Ƶԭʼ�ļ���������ͬ��Ƶ
declare -A truevrbthostname=(["AS31"]="JX-as31")
vrbtorifilenames=("AS31")
#��Ƶ�ļ����Ŀ¼
vrbtfiledir=/home/icaa/loudan/jxziyuan/vrbt
#��Ƶԭʼ�ļ����Ŀ¼
vrbtfileoridir=/home/icaa/loudan/jxziyuan/vrbtyuanshi
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
dYonly=`date +"%Y"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dSn=`date +"%Y-%m-%d %H:%M:%S"`
dMonly=`date +"%M"`
hostname=JX-`hostname`
wai=`whoami`
#�����Ǹ��ֱ�־
crbt_record_num=last_crbt_record_num					#������Ƶ�����ļ�
vrbt_record_num=last_vrbt_record_num					#������Ƶ�����ļ�
crbtori_record_num=last_crbtori_record_num		#������Ƶ����֮ǰ�ļ�
vrbtori_record_num=last_vrbtori_record_num		#������Ƶ����֮ǰ�ļ�
lastday_crbtoripre=lastday_crbtori_						#������Ƶ����֮ǰ�ļ��ľ������������˻�ǰ׺��־
lastday_vrbtoripre=lastday_vrbtori_						#������Ƶ����֮ǰ�ļ��ľ������������˻�ǰ׺��־
new0errorflag=last_crbt_000_error
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
		SendAlarm "�ļ������ڣ���Ƶ���廰��ԭʼ�ļ�������" crbt
	fi
#	#�ж��ļ���Ӧ�����������Ƿ���д��ȫ
#	for key in ${crbtorifilenames[@]}
#	do
#	    if [ X${truecrbthostname[$key]} = X ]
#	    then
#	    	SendAlarm "$key û�ж�Ӧ��������������ʱ�ļ���Ϊ������������" crbt
#	    	truecrbthostname[$key]=$key
#	    fi
#	done
	cd $crbtworkdir;
	unzip -P $mima $crbtfile
	rm -rf $crbtfile
	crbtfilenum=`ls $crbtworkdir 2>/dev/null|wc -l|awk '{print $1}'`
	if [ $crbtfilenum = 0 ]
	then
		SendAlarm "�ļ���������Ƶ���廰������Ϊ��" crbt
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
		SendAlarm "�ļ������ڣ���Ƶ���廰�������ļ�������" vrbt
	fi
	#�ж��ļ���Ӧ�����������Ƿ���д��ȫ
	for key in ${vrbtorifilenames[@]}
	do
	    if [ X${truevrbthostname[$key]} = X ]
	    then
	    	SendAlarm "$key û�ж�Ӧ��������������ʱ�ļ���Ϊ������������" vrbt
	    	truevrbthostname[$key]=$key
	    fi
	done
	cd $vrbtworkdir;
	unzip "*.zip";
	rm -rf $vrbtworkdir/$vrbtfile
	vrbtfilenum=`ls $vrbtworkdir 2>/dev/null|wc -l|awk '{print $1}'`
	if [ $vrbtfilenum = 0 ]
	then
		SendAlarm "�ļ���������Ƶ���廰������Ϊ��" vrbt
	fi
}
getfilenum()
{
	#$1�ǲ���Ŀ¼
	cd $1;
	getnum=`wc -l *|tail -1|awk '{print $1}'`
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
		SendAlarm "�ļ������ڣ���Ƶ���廰��ԭʼ�����ļ�������" crbt
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
#			log4s "$dS SUCCESS ԭʼ�ļ��������컰���� ����inms_pm_data�ɹ�"
#		else
#			log4s "$dS ERROR ԭʼ�ļ��������컰���� ����inms_pm_dataʧ��"
#			echo "$crbtorijobid|$hostname|$wai|||$dSn|1|$dSn|2|${crbtorifilesumnnum}|||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
#		fi
#		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$crbtorijobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
#		if [ $? = 0 ]
#		then
#			log4s "$dS SUCCESS ԭʼ�ļ��������컰���� ����inms_pm_datamgr�ɹ�"
#		else
#			log4s "$dS ERROR ԭʼ�ļ��������컰���� ����inms_pm_datamgrʧ��"
#			echo "$crbtorijobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
#		fi
	else
		SendAlarm "��ȡcrbtԭʼ�ļ����������쳣�������ļ����߽ű�" crbt
	fi
	log4s "$dS|$d1dayago|${crbtori_record_num}|$crbtorifilesumnnum"
	
	crbtorifilescount=0
	for i in ${crbtorifilenames[*]}
	do
		#���ȴ����쳣����
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
			truecrbthostnamefanyi=`gettruecrbthostname ${i}`
			echo "$dS|$d1dayago|${lastday_crbtoripre}${truecrbthostnamefanyi}|$hostnum" >>$jilu
			echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01) values ('$crbtorijobid','${truecrbthostnamefanyi}','$wai','$dSn',1,'$dSn',1,'$hostnum')"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${truecrbthostnamefanyi}���컰���� ����inms_pm_data�ɹ�"
			else
				log4s "$dS ERROR ${truecrbthostnamefanyi}���컰���� ����inms_pm_dataʧ��"
				echo "$crbtorijobid|${truecrbthostnamefanyi}|$wai|||$dSn|1|$dSn|1|$hostnum|||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
			fi
			echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$crbtorijobid','${truecrbthostnamefanyi}','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${truecrbthostnamefanyi}���컰���� ����inms_pm_datamgr�ɹ�"
			else
				log4s "$dS ERROR ${truecrbthostnamefanyi}���컰���� ����inms_pm_datamgrʧ��"
				echo "$crbtorijobid|${truecrbthostnamefanyi}|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
			fi
		else
			SendAlarm "��ȡ${truecrbthostnamefanyi}�����쳣�������ļ����߽ű�" crbt
		fi
		log4s "$dS|$d1dayago|${lastday_crbtoripre}${truecrbthostnamefanyi}|$hostnum"
		let crbtorifilescount=crbtorifilescount+hostnum
	done
	if [ X$crbtorifilesumnnum != X$crbtorifilescount ]
	then
		SendAlarm "ȡ��crbtoriȫ������$crbtorifilesumnnum�ͷ�����ͳ�ƵĽ��$crbtorifilescount��ͬ�����������Ƿ�����ȫ" crbt
	fi
}
vrbtorigo()
{
	#��ʼvrbtԭʼ�ļ��ĳ�ʼ������
	log4s "��ʼvrbtԭʼ�ļ���ʼ������"
	rm -rf $vrbtworkdirori/*
	cp $vrbtfileoridir/$vrbtorifile $vrbtworkdirori;
	if [ $? != 0 ]
	then
		SendAlarm "�ļ������ڣ���Ƶ���廰��ԭʼ�����ļ�������" vrbt
	fi
	cd $vrbtworkdirori;
	vrbtorifilesumnnum=`wc -l $vrbtworkdirori/*|tail -1|awk '{print $1}'`
	if [ $? = 0 ]
	then
		echo "$dS|$d1dayago|${vrbtori_record_num}|$vrbtorifilesumnnum" >>$jilu
#		echo "insert into inms_pm_data (jobid,host,account,endtime,seqno,inserttime,statnum,stat01) values ('$vrbtorijobid','$hostname','$wai','$dSn',1,'$dSn',3,'${vrbtorifilesumnnum}')"|dbaccess ${databasename}@${servername}
#		if [ $? = 0 ]
#		then
#			log4s "$dS SUCCESS ԭʼ�ļ��������컰���� ����inms_pm_data�ɹ�"
#		else
#			log4s "$dS ERROR ԭʼ�ļ��������컰���� ����inms_pm_dataʧ��"
#			echo "$vrbtorijobid|$hostname|$wai|||$dSn|1|$dSn|2|${vrbtorifilesumnnum}|||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
#		fi
#		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$vrbtorijobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
#		if [ $? = 0 ]
#		then
#			log4s "$dS SUCCESS ԭʼ�ļ��������컰���� ����inms_pm_datamgr�ɹ�"
#		else
#			log4s "$dS ERROR ԭʼ�ļ��������컰���� ����inms_pm_datamgrʧ��"
#			echo "$vrbtorijobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
#		fi
	else
		SendAlarm "��ȡvrbtԭʼ�ļ����������쳣�������ļ����߽ű�" vrbt
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
				log4s "$dS SUCCESS ${truevrbthostname[$i]}���컰���� ����inms_pm_data�ɹ�"
			else
				log4s "$dS ERROR ${truevrbthostname[$i]}���컰���� ����inms_pm_dataʧ��"
				echo "$vrbtorijobid|${truevrbthostname[$i]}|$wai|||$dSn|1|$dSn|1|${hostnum}|||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
			fi
			echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$vrbtorijobid','${truevrbthostname[$i]}','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
			if [ $? = 0 ]
			then
				log4s "$dS SUCCESS ${truevrbthostname[$i]}���컰���� ����inms_pm_datamgr�ɹ�"
			else
				log4s "$dS ERROR ${truevrbthostname[$i]}���컰���� ����inms_pm_datamgrʧ��"
				echo "$vrbtorijobid|${truevrbthostname[$i]}|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
			fi
		else
			SendAlarm "��ȡ${truevrbthostname[$i]}�����쳣�������ļ����߽ű�" vrbt
		fi
		log4s "$dS|$d1dayago|${lastday_vrbtoripre}${truevrbthostname[$i]}|$hostnum"
		let vrbtorifilescount=vrbtorifilescount+hostnum
	done
	if [ X$vrbtorifilesumnnum != X$vrbtorifilescount ]
	then
		SendAlarm "ȡ��vrbtoriȫ������$vrbtorifilesumnnum�ͷ�����ͳ�ƵĽ��$vrbtorifilescount��ͬ�����������Ƿ�����ȫ" vrbt
	fi
}
new0errgo()
{
	if [ $new0error = 1 ]
	then
		new0errnum=`grep 000000000000 $crbtworkdir/*|wc -l|awk '{print $1}'` 
		echo "$dS|$d1dayago|$new0errorflag|$new0errnum" >> $jilu
		if [ $new0errnum -ge $newerrgeshu ]
		then
			SendAlarm "��Ƶ�������ջ�����000000000000�ĸ���Ϊ${new0errnum} ���ڷ�ֵ${newerrgeshu}����ע��" crbt
		else
			log4s "��Ƶ�������ջ�����000000000000�ĸ���Ϊ${new0errnum} С�ڷ�ֵ${newerrgeshu},�������"
		fi
		new0errord2dnum=`grep $d2dayago $jilu|grep $new0errorflag|tail -1|awk -F'|' '{print $4}'`
		if [ X$new0errord2dnum != X ]
		then
			if [ $new0errnum -gt $new0errord2dnum ]
			then
				#����Ĵ��������
				new0da=$new0errnum
				new0xiao=$new0errord2dnum
			else
				#����Ĵ��ڽ����
				new0da=$new0errord2dnum
				new0xiao=$new0errnum
			fi
			let new0wuchat=(new0da-new0xiao)*100/$new0errord2dnum
			if [ $new0wuchat -ge $new0wucha ]
			then
				SendAlarm "��Ƶ�������ջ�����000000000000�ĸ���Ϊ${new0errnum} ����������ȣ��仯ֵΪ�ٷ�֮${new0wuchat}�����ڰٷ�֮${new0wucha}����ע��" crbt
			else
				log4s "��Ƶ�������ջ�����000000000000�ĸ���Ϊ${new0errnum} ����������ȣ��仯ֵΪ�ٷ�֮${new0wuchat}��С�ڰٷ�֮${new0wucha}"
			fi
		else
			log4s "��Ƶ�������ջ�����000000000000�ĸ���Ϊ${new0errnum}��û����������ݣ��޷��Ƚ�"
		fi
	else
		log4s "û��������Ƶ���ջ���000000000000�жϣ������бȽ�"
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
			log4s "$dS SUCCESS crbt���컰���� ����inms_pm_data�ɹ�"
		else
			log4s "$dS ERROR crbt���컰���� ����inms_pm_dataʧ��"
			echo "$alljobid|$hostname|$wai|||$dSn|1|$dSn|2|${crbt_record_num}|$crbtrecordnum||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
		fi
		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$alljobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS crbt���컰���� ����inms_pm_datamgr�ɹ�"
		else
			log4s "$dS ERROR crbt���컰���� ����inms_pm_datamgrʧ��"
			echo "$alljobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
		fi
	else
		SendAlarm "��ȡcrbt�����쳣�������ļ����߽ű�" crbt
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
			log4s "$dS SUCCESS vrbt���컰���� ����inms_pm_data�ɹ�"
		else
			log4s "$dS ERROR vrbt���컰���� ����inms_pm_dataʧ��"
			echo "$alljobid|$hostname|$wai|||$dSn|1|$dSn|2|${vrbt_record_num}|$vrbtrecordnum||||||||||||||||||||||||||||" >> $dodir/bad.inms_pm_data.$dS.unl
		fi
		echo "insert into inms_pm_datamgr (jobid,host,account,endtime,datanum) values ('$alljobid','$hostname','$wai','$dSn',1)"|dbaccess ${databasename}@${servername}
		if [ $? = 0 ]
		then
			log4s "$dS SUCCESS vrbt���컰���� ����inms_pm_datamgr�ɹ�"
		else
			log4s "$dS ERROR vrbt���컰���� ����inms_pm_datamgrʧ��"
			echo "$alljobid|$hostname|$wai|||$dSn|1|" >> $dodir/bad.inms_pm_datamgr.$dS.unl
		fi
	else
		SendAlarm "��ȡvrbt�����쳣�������ļ����߽ű�" vrbt
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
		SendAlarm "����crbt�����쳣��鿴" crbt
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
			SendAlarm "$dS crbt���� ${d1dayago}ֵΪ��${d1dnum}��${d2dayago}ֵΪ��${d2dnum} ����ֵ�����ٷ�֮$wucha����ע��˲�" crbt
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
		SendAlarm "����vrbt�����쳣��鿴" vrbt
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
			SendAlarm "$dS vrbt���� ${d1dayago}ֵΪ��${vd1dnum}��${d2dayago}ֵΪ��${vd2dnum} ����ֵ�����ٷ�֮$wucha����ע��˲�" vrbt
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
	xd2dnum=`grep "|$d2dayago|" $jilu|wc -l|awk '{print $1}'`
	if [ $xd2dnum -gt 0 ]
	then
		if [ X$1 = Xcrbt ]
		then
			mustnum1=`echo ${#crbtorifilenames[@]}`
			mustnum2=0
			if [ $new0error = 1 ]
			then
				let mustnum=mustnum1+mustnum2+3
			else
				let mustnum=mustnum1+mustnum2+2
			fi

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
			SendAlarm "orihbbijiao ��������ȷ" $1
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
					SendAlarm "$a1 $d1dayago ֵΪ 0 ��$d2dayago ֵΪ $a4��������޴���ע��˲�" $1
				else
					if [ $a2 -ge $wucha ]
					then
						SendAlarm "$a1 $d1dayago ֵΪ $a3 ��$d2dayago ֵΪ $a4 ����ֵ�����ٷ�֮$wucha����ע��˲�" $1
					fi
				fi 
			done <$dodir/orihbbijiao.log.$dS
			
			
		else
			SendAlarm "����ļ�¼�������ԣ��޷����жԱ�" $1
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
			SendAlarm "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${crbtorinum}�������ļ�����Ϊ��${crbtfinalnum}����ֵΪ���ٷ�֮${fcrbtPERCENTAGE}�������˰ٷ�֮${orifinalwucha}" crbt
		else
			log4s "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${crbtorinum}�������ļ�����Ϊ��${crbtfinalnum}����ֵΪ���ٷ�֮${fcrbtPERCENTAGE}��С����ǰ�趨�İٷ�֮${orifinalwucha}���������"
		fi
	elif [ X$1 = Xvrbt ]
	then
		vrbtorinum=`grep $d1dayago $jilu|grep ${vrbtori_record_num}|tail -1|awk -F'|' '{print $4}'`
		vrbtfinalnum=`grep $d1dayago $jilu|grep ${vrbt_record_num}|tail -1|awk -F'|' '{print $4}'`
		tfvrbtPERCENTAGE=$(printf "%d" $(((vrbtorinum-vrbtfinalnum)*100/vrbtorinum)))
		fvrbtPERCENTAGE=`echo ${tfvrbtPERCENTAGE#-}`
		if [ $fvrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${vrbtorinum}�������ļ�����Ϊ��${vrbtfinalnum}����ֵΪ���ٷ�֮${fvrbtPERCENTAGE}�������˰ٷ�֮${orifinalwucha}" vrbt
		else
			log4s "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${vrbtorinum}�������ļ�����Ϊ��${vrbtfinalnum}����ֵΪ���ٷ�֮${fvrbtPERCENTAGE}��С����ǰ�趨�İٷ�֮${orifinalwucha}���������"
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
			SendAlarm "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${crbtorinum}�������ļ�����Ϊ��${crbtfinalnum}����ֵΪ���ٷ�֮${fcrbtPERCENTAGE}�������˰ٷ�֮${orifinalwucha}" crbt
		else
			log4s "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${crbtorinum}�������ļ�����Ϊ��${crbtfinalnum}����ֵΪ���ٷ�֮${fcrbtPERCENTAGE}��С����ǰ�趨�İٷ�֮${orifinalwucha}���������"
		fi
		if [ $fvrbtPERCENTAGE -gt $orifinalwucha ]
		then
			SendAlarm "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${vrbtorinum}�������ļ�����Ϊ��${vrbtfinalnum}����ֵΪ���ٷ�֮${fvrbtPERCENTAGE}�������˰ٷ�֮${orifinalwucha}" vrbt
		else
			log4s "��Ƶ������л�����ԭʼ�ļ�����Ϊ��${vrbtorinum}�������ļ�����Ϊ��${vrbtfinalnum}����ֵΪ���ٷ�֮${fvrbtPERCENTAGE}��С����ǰ�趨�İٷ�֮${orifinalwucha}���������"
		fi
	else
		SendAlarm "orifinalbijiao ��������ȷ" $1
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
	new0errgo
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
	new0errgo
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
