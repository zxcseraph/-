#!/bin/sh
set -x
dodir=/home/informix/zxc          	         #�ű�����Ŀ¼�����в������������Ŀ¼ִ��
log=$dodir/root.log                              #������¼��־
alarmlog=$dodir/alarm.log                        #��¼���и澯����־
alarmcode=123                                    #�澯��
remaindernum=1                                   #rmd�����е����������ķ�ֵ
fragdaynum=3                                     #��Ƭ��������ӽ������������ֵ������
ckptnum=3                                        #���ݿ⴦��ckpt״̬�������澯
testflag=1                                       #���Ա�־λ������ʹ��ʱ��ֵ����Ϊ0
TAGLOG=$dodir/taglog.log                           #��־��־
seq_alarmnum1=5												#˳ɨ��һ����ÿ�����ڲ���˳ɨ�����ķ�ֵ
seq_alarmrow1=10000										#˳ɨ��һ���������������ı�Ż����һ���澯
seq_alarmnum2=100											#˳ɨ�ڶ�����ÿ�����ڲ���˳ɨ�����ķ�ֵ
seq_alarmrow2=500											#˳ɨ�ڶ����������������ı�Ż����һ���澯
###���¾����ɸ���####
XITONGTEMP=`uname`                               
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`     #ϵͳ����
#ͨ��ʱ������                                    
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
dN=`date +"%H%M%S.%N"`                           
dMonly=`date +"%M"`                              
hostname=`hostname`                              
wai=`whoami`                                     
okday=`date -d "+$fragdaynum days" +"%Y%m%d"`    
jiaobenming=`echo $0|awk -F'/' '{print $NF}'`    
if [ $XITONG = LINUX ]
then
	d7dayago=`date -d "7 day ago" +"%Y%m%d"`
fi
seqbaogao=$dodir/seqscan.${dH}.html
errornum=0
export LC_TIME="POSIX"
if [ ! -d $dodir ]
then
	mkdir $dodir
	echo "��������Ŀ¼"
	cp $jiaobenming $dodir
fi
#��ȡx��֮ǰ�����庯��
DOY () 
{
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
getResidueMin()
{
	dMt=`date +"%M"|sed s'/^0//'`
	dSt=`date +"%S"|sed s'/^0//'`
	if [ $dMt -gt 22 ]
	then
		let lMt=60-dMt+22
	else
		let lMt=22-dMt
	fi

	echo $lMt

}
cron_config()
{
	PROGRAM=$dodir/$jiaobenming
	if [ $XITONG = LINUX ]
	then
	CRONTAB_CMD="22 * * * * . ./.bash_profile;sh $PROGRAM >> $dodir/cron.log 2>&1 &"
	fi
	if [ $XITONG = HP-UX ]
	then
	CRONTAB_CMD="22 * * * * . ./.profile;sh $PROGRAM >> $dodir/cron.log 2>&1 &"
	fi
	PROGRAMnum=`crontab -l|grep "$PROGRAM"|wc -l|awk '{print $1}'`
	if [ X$PROGRAMnum = X0 ]
	then
		crontab -l>$dodir/cron.temp
		echo "$CRONTAB_CMD" >> $dodir/cron.temp
		cat $dodir/cron.temp|crontab
	fi
}
cron_config_seq1min()
{
	PROGRAM="./$jiaobenming seq1min"
	if [ $XITONG = LINUX ]
	then
	CRONTAB_CMD="22 * * * * . ./.bash_profile;cd $dodir;sh $PROGRAM >> $dodir/cron.log 2>&1 &"
	fi
	if [ $XITONG = HP-UX ]
	then
	CRONTAB_CMD="22 * * * * . ./.profile;cd $dodir;sh $PROGRAM >> $dodir/cron.log 2>&1 &"
	fi
	PROGRAMnum=`crontab -l|grep "$PROGRAM"|wc -l|awk '{print $1}'`
	if [ X$PROGRAMnum = X0 ]
	then
		crontab -l>$dodir/cron.temp
		echo "$CRONTAB_CMD" >> $dodir/cron.temp
		cat $dodir/cron.temp|crontab
	fi
}
##################################################
#˵����
#ע�͹���	16�����ŵ����������úʹ�������
#						3�����ŵ������ִ�������жϺ͹�������
#���Ͻ��ĵط�����־���3������Ϊ�գ��ᵼ�°������ڷָʽ�޷��ָ������˼·
#���Ż�����־�ָʽ�����Ӱ��մ�С��ѭ��д�롣ģ��log4j
#�Ż��ĵط��������������ٶȣ����������ļ����
##################################################
################log4s������#################
log4spath=$dodir								#�����־Ŀ¼
log4sechoCategory=info				#�������Ļ��־�������ƣ�������debug=0��warn=1��info=2��error=3
log4swriteCategory=debug			#������ļ���־�������ƣ�������debug=0��warn=1��info=2��error=3
log4slogname=root.log					#�����־����
isecho=1											#�������־��ͬʱ�Ƿ��ӡ����Ļ��0�ǲ���ӡ��1�Ǵ�ӡ

splittype=none								#��־�ָʽ��none���ָday�������ڷָ��׺��ΪYYYY-MM-DD��numΪ������ģʽ�ָ���ʹ��numģʽ�������дsplitnum���������û˼·�ݲ�֧��
splitnum=1000


################log4s����У�鲢��ʼ�����������ó�����Ϊ��ʼ��ֻ��Ҫһ��#############
log4scheck()
{
	if [ X$log4spath = X ]
	then
		echo "log4spath������Ҫ����"
		exit 1;
	fi
	if [ X$log4sechoCategory = X ]
	then
		echo "log4sechoCategory������Ҫ����"
		exit 1;
	fi
	if [ X$log4swriteCategory = X ]
	then
		echo "log4swriteCategory������Ҫ����"
		exit 1;
	fi
	if [ X$log4slogname = X ]
	then
		echo "log4slogname������Ҫ����"
		exit 1;
	fi
	if [ X$isecho = X ]
	then
		echo "isecho������Ҫ����"
		exit 1;
	fi
	if [ X$splittype = X ]
	then
		echo "splittype������Ҫ����"
		exit 1;
	fi
	if [ X$splittype = Xnum ]
	then
		if [ X$splitnum = X ]
		then
			echo "splitnum������Ҫ����"
			exit 1;
		fi
	fi
	log4sechoCategoryToU=`echo $log4sechoCategory|tr '[a-z]' '[A-Z]'`
	log4swriteCategoryToU=`echo $log4swriteCategory|tr '[a-z]' '[A-Z]'`

	case $log4sechoCategoryToU in
		DEBUG)
			log4sechoCategorylevel=0
			;;
		WARN)
			log4sechoCategorylevel=1
			;;
		INFO)
			log4sechoCategorylevel=2
			;;
		ERROR)
			log4sechoCategorylevel=3
			;;
		*)
			log4sechoCategorylevel=3
			;;
	esac
	case $log4swriteCategoryToU in
		DEBUG)
			log4swriteCategorylevel=0
			;;
		WARN)
			log4swriteCategorylevel=1
			;;
		INFO)
			log4swriteCategorylevel=2
			;;
		ERROR)
			log4swriteCategorylevel=3
			;;
		*)
			log4swriteCategorylevel=3
			;;
	esac
}
################log4s������#################
log4slog=${log4spath}/${log4slogname}
log4scheck;
#log4s()                       #$1�Ǽ���$2������
#{
#	nowdate=`date +"%Y-%m-%d %H:%M:%S"`
#	######�ж����򣬱�֤�����Ͻ���
#	#�ж�Ŀ¼����־�ļ������Զ�����Ŀ¼�����ǻ��Զ������ļ�
#	if [ ! -d $log4spath ]
#	then
#		echo "$nowdate log4s���õ�Ŀ¼�����ڣ���ȷ�������Ƿ���ȷ"
#		exit 1;
#	fi
#	if [ ! -f $log4slog ]
#	then
#		echo "$nowdate log4s��־�����ڣ�����log4s��־�ļ�"
#		echo "$nowdate log4s��־�����ڣ�����log4s��־�ļ�" >> $log4slog
#	fi
#	
#	#�жϲ�������
#	if [ $# -ne 2 ]
#	then
#		echo "��������Ϊ2��"
##		exit 1;
#	fi
#	log4sindex=0
#	
#	###�ָ���־��
#	#���շָ�
#	if [ $splittype = day ]
#	then
#		lastlineday=`tail -1 $log|awk  '{print $1}'`
#		if [ X$lastlineday = X ]
#		then
#			lastlineday=`tail -2 $log|head -1|awk  '{print $1}'`
#			if [ X$lastlineday = X ]
#			then
#				lastlineday=`tail -3 $log|head -1|awk  '{print $1}'`
#			fi
#		fi
#		nowday=`echo $nowdate|awk '{print $1}'`
#		if [ X$lastlineday != X$nowday ] && [ X$lastlineday != X ]
#		then
#			mv ${log4slog} ${log4slog}.$lastlineday
#			touch $log4slog
#		fi
#	fi
#	#�������ָ�
#	if [ $splittype = num ]
#	then
#		if [ ! -f $log4slog ]
#		then
#			echo "��־�ļ������ڣ����������Ƿ���ȷ"
#			exit 1;
#		fi
#		lognum=`wc -l $log4slog|awk '{print $1}'`
#		if [ $lognum -ge $splitnum ]
#		then
#			temptag=`date +"%Y%m%d%H%M%S"`
#			mv ${log4slog} ${log4slog}.${temptag}
#			touch $log4slog
#		fi
#	fi
#
#	######��������
#	log4sinlevel=`echo $1|tr '[a-z]' '[A-Z]'`
#	case $log4sinlevel in
#		DEBUG)
#			log4snowlevel=0
#			;;
#		WARN)
#			log4snowlevel=1
#			;;
#		INFO)
#			log4snowlevel=2
#			;;
#		ERROR)
#			log4snowlevel=3
#			;;
#		*)
#			log4snowlevel=3
#			;;
#	esac
#	if [ $log4snowlevel -ge $log4sechoCategorylevel ] && [ $isecho = 1 ]
#	then
#		echo "$nowdate log4s.${log4sinlevel}   $2"
#	fi
#	if [ $log4snowlevel -ge $log4swriteCategorylevel ]
#	then
#		echo "$nowdate log4s.${log4sinlevel}   $2" >> $log4slog
#	fi
#}
log4s()
{
	echo "$1 $2" >> $log4slog
}
errornum=0
sendalarm()
{
	dStmp=`date +"%Y%m%d%H%M%S"`
	log4s error "$1"
	echo "$dStmp $alarmcode $1" >> $alarmlog
	let errornum=errornum+1
}
gosqlite3()
{
	echo "$1"|sqlite3 ${dodir}/fx.temp.db
}
xhtml()
{
	echo $1 >> $seqbaogao
}


#remainderƬ�������˲�
getrmd()
{
	#$1�ǿ���
	#�ȵ���ָ��������з�Ƭ
	unload1unl="$dodir/$1.fragment.unl.$dS"
	unload2unl="$dodir/$1.fragment.unl.temp.$dS"
	alarmunl="${unload1unl}.$dS"
	echo "unload to $unload1unl select c.tabname,a.partn,b.nrows,a.exprtext[1,9] from sysfragments a,sysmaster:sysptnhdr b,systables c where a.partn=b.partnum and a.tabid=c.tabid" | dbaccess $1 1>/dev/null 2>&1
	if [ $? != 0 ]
	then
		sendalarm "���ݿ� $1 �У�����sysfragments������ʧ��"
	fi
	grep -a remainder $unload1unl>$unload2unl
	awk -v b="$remaindernum" 'BEGIN{FS="|";OFS="|";a=0} {if($3>b && $4=="remainder"){$1=$1;print $0}}' $unload2unl > ${alarmunl}
	alarmunlnum=`wc -l ${alarmunl}|awk '{print $1}'`
	if [ $alarmunlnum != 0 ]
	then
		while read hang
		do
			tabname=`echo "$hang"|awk -F'|' '{print $1}'`
			partnum=`echo "$hang"|awk -F'|' '{print $2}'`
			rows=`echo "$hang"|awk -F'|' '{print $3}'`
			sendalarm "���ݿ� $1 �У��� ${tabname} ��remainder���� ${rows} �����ݣ�������ֵ ${remaindernum} ����remainder��Ƭ��partnumֵΪ ${partnum} "
		done < ${alarmunl}
	else
		log4s info "���ݿ� $1 �У��� ${tabname} ��rmd�����е�����������"
	fi

}
#�ж���tlm_table���ڵ���fragtabinfo�����ڵı�����෴
notintable()
{
	#$1�ǿ���
	notin1unl="$dodir/notin1.unl.$dS"
	echo "unload to ${notin1unl} select distinct(table_name) from tlm_table where table_name not in(select tabname from fragtabinfo)"|dbaccess $1 1>/dev/null 2>&1;
	if [ $? != 0 ]
	then
		sendalarm "���ݿ� $1 �У��жϱ������tlm_table���ǲ�������fragtabinfoʱ�������ݿ⵼������ʧ��"
	fi
	notin1num=`wc -l $notin1unl|awk '{print $1}'`
	if [ $notin1num != 0 ]
	then
		while read hang
		do
			tabname=`echo $hang|awk -F'|' '{print $1}'`
			sendalarm "���ݿ� $1 �У��� $tabname ������tlm_table�����ǲ�������fragtabinfo��"
		done < $notin1unl
	else
		log4s info "���ݿ� $1 �У�tlm_table���м�¼�ı�������fragtabinfo�У�����"
	fi
	notin2unl="$dodir/notin2.unl.$dS"
	echo "unload to ${notin2unl} select distinct(tabname) from fragtabinfo where tabname not in(select table_name from tlm_table)"|dbaccess $1 1>/dev/null 2>&1;
	if [ $? != 0 ]
	then
		sendalarm "���ݿ� $1 �У��жϱ������fragtabinfo���ǲ�������tlm_tableʱ�������ݿ⵼������ʧ��"
	fi
	notin2num=`wc -l $notin2unl|awk '{print $1}'`
	if [ $notin2num != 0 ]
	then
		while read hang
		do
			tabname=`echo $hang|awk -F'|' '{print $1}'`
			sendalarm "���ݿ� $1 �У��� $tabname ������fragtabinfo�����ǲ������ڱ�tlm_table��"
		done < $notin2unl
	else
		log4s info "���ݿ� $1 �У���fragtabinfo�м�¼�ı�������tlm_table�У�����"
	fi

}

#�жϷ�Ƭ�������ڣ���ǰֻ�ܴ�fragtabinfo��ȡ)
getmaxfrag()
{
	allfragtabinfounl="$dodir/allfragtabinfo.unl.$dS"
	echo "unload to $allfragtabinfounl select tabname,max(endtime[1,8]) from fragtabinfo group by tabname"|dbaccess $1 1>/dev/null 2>&1;
	if [ $? != 0 ]
	then
		sendalarm "���ݿ� $1 �У��жϷ�Ƭ�������ʱ�������ݿ⵼������ʧ��"
	fi
	allfragtabinfounlnum=`wc -l $allfragtabinfounl|awk '{print $1}'`
	if [ $allfragtabinfounlnum != 0 ]
	then
		while read hang
		do
			tabname=`echo $hang|awk -F'|' '{print $1}'`
			tablastday=`echo $hang|awk -F'|' '{print $2}'`
			if [ $okday -gt $tablastday ]
			then
				sendalarm "���ݿ� $1 �У��� $tabname ��Ƭ�����һƬ�����һ��ʱ��Ϊ $tablastday ,С��Ԥ��� $fragdaynum ��ķ�ֵ"
			else
				log4s "���ݿ� $1 �У��� $tabname ��Ƭʱ������"
			fi
		done < $allfragtabinfounl
	else
		log4s info "���ݿ� $1 �У����б���fragtabinfo�е��������ڶ�����3�������ڣ���������ʹ��"
	fi

}
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
#		if [ $tflag = 1 ]
#		then
#			if [ $i = 1 ]
#			then
#				echo 1 > $ckptunl
#			elif [ $i = 2 ]
#			then
#				echo 0 >  $ckptunl
#			fi
#		elif [ $tflag = 2 ]
#		then
#			if [ $i = 1 ]
#			then
#				echo 0 > $ckptunl
#			elif [ $i = 2 ]
#			then
#				echo 1 >  $ckptunl
#			fi
#		elif [ $tflag = 3 ]
#		then
#			if [ $i = 1 ]
#			then
#				echo 1 > $ckptunl
#			elif [ $i = 2 ]
#			then
#				echo 1 >  $ckptunl
#			fi
#		fi
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
Table_Info()
{
	tabinfoworkdir=`pwd`
	dSt=`date +"%Y%m%d%H%M%S"`
	dbaccess sysmaster <<EOF
	unload to $tabinfoworkdir/table.$dS.temp
	select "$dSt",a.lockid,a.partnum,b.tabname,c.tabname,b.dbsname,a.flags,a.nrows,d.seqscans
	from sysmaster:sysptnhdr a, sysmaster:systabnames b,sysmaster:systabnames c
	--�������sysptprof���
	,sysmaster:sysptprof d
	where a.partnum=b.partnum
	and a.lockid=c.partnum
	--from�г�������systabnames����Ϊ�˷ֱ��ṩpartnum��lockid��tabname��ȷ�������ͱ�Ĺ�ϵ��
	and a.flags not in ('2310','2054','3334','3078','2081')
	--ָ�����ݿ�
	--and b.dbsname='min'
	--ҵ�����أ�
	and a.partnum=d.partnum and d.seqscans>0
	group by a.lockid,a.partnum,b.tabname,c.tabname,b.dbsname,a.nrows,d.seqscans,a.flags
	order by a.partnum
EOF
	sed 's/.$//' $tabinfoworkdir/table.$dSt.temp > table.$dSt.temp.a
	rm -rf $tabinfoworkdir/table.$dSt.temp
	mv table.$dSt.temp.a ${tabinfoworkdir}/table.new


	if [ ! -f ${tabinfoworkdir}/table.old ]
	then
		mv ${tabinfoworkdir}/table.new ${tabinfoworkdir}/table.old
	else
		gosqlite3 "create table seqfx(timenow text,lockid  integer,partnum integer,tabname1 text,tabname2 text,dbsname text,flags integer,nrows integer,seqscans integer);"
		gosqlite3 ".import ${tabinfoworkdir}/table.old seqfx"
		gosqlite3 ".import ${tabinfoworkdir}/table.new seqfx"
		gosqlite3 "create index idx_seqfx on seqfx(partnum);"
		gosqlite3 "select b.timenow,b.lockid,b.partnum,b.tabname1,b.tabname2,b.dbsname,b.flags,b.nrows,b.seqscans-a.seqscans from seqfx a,seqfx b where a.partnum=b.partnum and a.timenow<b.timenow;">${tabinfoworkdir}/table.${dSt}.temp
		mv ${dodir}/fx.temp.db ${tabinfoworkdir}/fx.${dSt}.db

		mv ${tabinfoworkdir}/table.new ${tabinfoworkdir}/table.old
		cp ${tabinfoworkdir}/table.old ${tabinfoworkdir}/table.${dSt}.old
		cat ${tabinfoworkdir}/table.${dSt}.temp|sort -r -t "|" -k 9 > ${tabinfoworkdir}/table.${dSt}.unl
		gohtml ${dSt}
	fi
}

gohtml()
{
	dSt=$1
	tableunl=${tabinfoworkdir}/table.$1.unl
	if [ ! -f $tableunl ]
	then
		log4s "������$tableunl���޷�����˳ɨ����"
		return 1;
	fi
	if [ ! -f $dodir/seqscan.log ]
	then
		touch $dodir/seqscan.log
		chmod 777 $dodir/seqscan.log
	fi
	if [ ! -f $seqbaogao ]
	then
		touch $seqbaogao
		chmod 777 $seqbaogao
	fi
	firstxhtmlnu=`wc -l $seqbaogao|awk '{print $1}'`
	if [ X$firstxhtmlnu = X0 ]
	then
		log4s info "�����޼�¼�����ɱ���ͷ��"
		xhtml "<html><head><title>˳��ɨ���¼</title></head><body>" 
		xhtml "<table border="1">"
		xhtml "<tr>"
		xhtml "<th>ʱ��</th><th>����</th><th>partnum</th><th>����</th><th>˳��ɨ�����</th>"
		xhtml "</tr>"
	else
		log4s info "�����Ѿ����ڼ�¼��ȡ������β��"
		mv $seqbaogao ${seqbaogao}.${dSt}
		sed "/<\/table>/d" ${seqbaogao}.${dSt}|sed "/<\/body>/d" > $seqbaogao
		rm -rf ${seqbaogao}.${dSt}
	fi
	while read hang
	do
		tabname=`echo $hang|awk -F'|' '{print $5}'`
		partnum=`echo $hang|awk -F'|' '{print $3}'`
		nrows=`echo $hang|awk -F'|' '{print $8}'`
		seq=`echo $hang|awk -F'|' '{print $9}'|awk -F'.' '{print $1}'`
		if [ $seq -ge $seq_alarmnum1 ]
		then
			if [ $nrows -ge $seq_alarmrow1 ]
			then
				xhtml "<tr>"
				xhtml "<th>$dSt</th>"
				xhtml "<th>$tabname</th>"
				xhtml "<th>$partnum</th>"
				xhtml "<th>$nrows</th>"
				xhtml "<th>$seq</th>"
				xhtml "</tr>"
				echo "$dSt ������$tabname ,partnum��$partnum ,������$nrows ,alarm1 table seq is too large" >> $dodir/seqscan.log
				sendalarm "$dSt ������$tabname ,partnum��$partnum ,������$nrows ,alarm1 table seq is too large"
			fi
		else
			break;
		fi
	done < ${tabinfoworkdir}/table.${dSt}.unl
	xhtml "</table>"
	xhtml "</body></html>"
}




#cron_config
#getrmd;
#notintable;
#getmaxfrag;
#ckptcheck;
if [ $testflag = 0 ]
then
	log4s "��ʼɾ���м��ļ�"
	if [ $XITONG = LINUX ]
	then
		rm -rf $dodir/table.${d7dayago}*.unl
		rm -rf $dodir/seqscan.${d7dayago}*.html
		rm -rf $dodir/fx.${d7dayago}*.db
		rm -rf ${dodir}/fx.temp.db
		rm -rf ${dodir}/table.${d7dayago}*.temp
		rm -rf ${dodir}/${d7dayago}??
		rm -rf $allfragtabinfounl
		rm -rf $ckptunl
		rm -rf $unload1unl
		rm -rf $unload2unl
		rm -rf $alarmunl
		rm -rf $notin1unl
		rm -rf $notin2unl
	fi
else
	log4s "����ģʽ����ɾ���м��ļ�"
fi
if [ X$1 = Xseq1min ]
then
	cron_config_seq1min
	if [ ! -d $dH ]
	then
		mkdir $dH
	fi
	cp $jiaobenming $dH
	cd $dH
	startint=0
	while true
	do
		if [ $startint = 60 ]
		then
			log4s info "��ǰѭ�� $dH �Ѿ�����һСʱ�����н���"
			exit 0;
		fi
		sh ./$jiaobenming seqbasic
		sleep 60;
		let startint=startint+1
	done
fi
if [ X$1 = Xseq1min_manual ]
then
	cron_config_seq1min
	runmin=`getResidueMin`
	if [ ! -d $dH ]
	then
		mkdir $dH
	fi
	cp $jiaobenming $dH
	cd $dH
	startint=0
	while true
	do
		if [ $startint = $runmin ]
		then
			log4s info "��ǰѭ����Ϊ�ֶ�ѭ�� $dH �Ѿ����� $startint ���ӣ����н���������������ʱcronִ��"
			exit 0;
		fi
		sh ./$jiaobenming seqbasic
		sleep 60;
		let startint=startint+1
	done
fi
if [ X$1 = Xseqbasic ]
then
	Table_Info;
fi