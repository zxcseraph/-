#!/bin/sh
dodir=/home/informix/jiankong          	         #�ű�����Ŀ¼�����в������������Ŀ¼ִ��
log=$dodir/root.log                              #������¼��־
alarmlog=$dodir/alarm.log                        #��¼���и澯����־
alarmcode=123                                    #�澯��
remaindernum=1                                   #rmd�����е����������ķ�ֵ
fragdaynum=3                                     #��Ƭ��������ӽ������������ֵ������
ckptnum=3                                        #���ݿ⴦��ckpt״̬�������澯
testflag=1                                       #���Ա�־λ������ʹ��ʱ��ֵ����Ϊ0
TAGLOG=$dodir/taglog.log                           #��־��־

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
	log4s info "��������Ŀ¼"
	cp $jiaobenming $dodir
fi

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
log4s()
{
	#����ʱ����������������Ͻ���log4s
	dStmp=`date +"%Y%m%d%H%M%S"`
	echo "$dStmp $1 $2"
	echo "$dStmp $1 $2" >> $log
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
	echo $1 >> $baogao
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

	dbaccess sysmaster <<EOF
	unload to $dodir/table.$dS.temp
	select "$dS",a.lockid,a.partnum,b.tabname,c.tabname,b.dbsname,a.flags,a.nrows,d.seqscans
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
	sed 's/.$//' $dodir/table.$dS.temp > table.$dS.temp.a
	mv table.$dS.temp.a ${dodir}/table.new


	if [ ! -f ${dodir}/table.old ]
	then
		mv ${dodir}/table.new ${dodir}/table.old
	else
		gosqlite3 "create table seqfx(timenow text,lockid  integer,partnum integer,tabname1 text,tabname2 text,dbsname text,flags integer,nrows integer,seqscans integer);"
		gosqlite3 ".import ${dodir}/table.old seqfx"
		gosqlite3 ".import ${dodir}/table.new seqfx"
		gosqlite3 "create index idx_seqfx on seqfx(partnum);"
		gosqlite3 "select b.timenow,b.lockid,b.partnum,b.tabname1,b.tabname2,b.dbsname,b.flags,b.nrows,b.seqscans-a.seqscans from seqfx a,seqfx b where a.partnum=b.partnum and a.timenow<b.timenow;">${dodir}/table.${dS}.temp
		mv ${dodir}/fx.temp.db ${dodir}/fx.${dS}.db

		mv ${dodir}/table.new ${dodir}/table.old
		cp ${dodir}/table.old ${dodir}/table.${dS}.old
		cat ${dodir}/table.${dS}.temp|sort -r -t "|" -k 9 > ${dodir}/table.${dS}.unl

	fi
}

gohtml()
{
	if [ ! -f ${dodir}/table.${dS}.unl ]
	then
		log4s "������table.${dS}.unl���޷�����˳ɨ����"
		return 1;
	fi
	if [ ! -f $dodir/seqscan.log ]
	then
		touch $dodir/seqscan.log
		chmod 777 $dodir/seqscan.log
	fi
	>$baogao
	xhtml "<html><head><title>˳��ɨ���¼</title></head><body>" 
	xhtml "<table border="1">"
	xhtml "<tr>"
	xhtml "<th>����</th><th>partnum</th><th>����</th><th>˳��ɨ�����</th>"
	xhtml "</tr>"
	while read hang
	do
		tabname=`echo $hang|awk -F'|' '{print $5}'`
		partnum=`echo $hang|awk -F'|' '{print $3}'`
		nrows=`echo $hang|awk -F'|' '{print $8}'`
		seq=`echo $hang|awk -F'|' '{print $9}'|awk -F'.' '{print $1}'`
		if [ $seq -ge 50 ]
		then
			if [ $nrows -ge 500 ]
			then
				xhtml "<tr>"
				xhtml "<th>$tabname</th>"
				xhtml "<th>$partnum</th>"
				xhtml "<th>$nrows</th>"
				xhtml "<th>$seq</th>"
				xhtml "</tr>"
				echo "$dS $tabname $partnum table seq is too large" >> $dodir/seqscan.log
				sendalarm "$dS $tabname $partnum table seq is too large"
			fi
		else
			break;
		fi
	done < ${dodir}/table.${dS}.unl
	xhtml "</table>"
	xhtml "</body></html>"
}




cron_config
Table_Info
getrmd;
notintable;
getmaxfrag;
ckptcheck;
if [ $testflag = 0 ]
then
	log4s "��ʼɾ���м��ļ�"
	if [ $XITONG = LINUX ]
	then
		rm -rf $dodir/table.${d7dayago}*.unl
		rm -rf $dodir/seqscan.${d7dayago}*.html
		rm -rf $dodir/fx.${d7dayago}*.db
		rm -rf ${dodir}/fx.temp.db
		rm -rf ${dodir}/table.${dS}.temp
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
