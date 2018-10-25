#!/bin/sh
dodir=/home/informix/frag          	#�ű�����Ŀ¼�����в������������Ŀ¼ִ��
log=$dodir/root.log                     #������¼��־
alarmlog=$dodir/alarm.log               #��¼���и澯����־
alarmcode=123                           #�澯��
remaindernum=100                          #rmd�����е����������ķ�ֵ
fragdaynum=3                            #��Ƭ��������ӽ������������ֵ������
testflag=1                              #���Ա�־λ������ʹ��ʱ��ֵ����Ϊ0

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
dMonly=`date +"%M"`
hostname=`hostname`
wai=`whoami`
okday=`date -d "+$fragdaynum days" +"%Y%m%d"`

errornum=0
log4s()
{
	#����ʱ����������������Ͻ���log4s
	echo "$dSt $1 $2"
	echo "$dSt $1 $2" >> $log
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

	if [ $testflag = 0 ]
	then
		rm -rf $unload1unl
		rm -rf $unload2unl
		rm -rf $alarmunl
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
	if [ $testflag = 0 ]
	then
		rm -rf $notin1unl
		rm -rf $notin2unl
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
	if [ $testflag = 0 ]
	then
		rm -rf $allfragtabinfounl
	fi
}
pdatabases()
{
	databasesunl="$dodir/databases.unl.temp.$dS"
	echo "unload to $databasesunl select * from sysdatabases where name='$1'"|dbaccess sysmaster 1>/dev/null 2>&1;
	if [ $? != 0 ]
	then
		log4s error "���ݿ� sysmaster �У���ȡdatabase��Ϣ����ʧ��"
		exit 1;
	fi
	databasesnum=`wc -l $databasesunl|awk '{print $1}'`
	if [ $databasesnum = 0 ]
	then
		log4s error "ϵͳ��û�иÿ⣬��˲��������ִ��"
		exit 1
	else
		log4s info "��database���ڣ���ʼ���г����˲�"
	fi
}

delfrag()
{
date >> $dodir/del_par_for_date.log 
for i in {1..5} 
do
(time dbaccess $1 <<!
 execute procedure del_par_for_date();
!
)  1>> $dodir/del_par_for_date.log 2>&1
echo $i
echo $i >>$dodir/del_par_for_date.log
mv $dodir/del_par_for_date.dbg $dodir/del_par_for_date.dbg.$dt.$i
done
date >>$dodir/del_par_for_date.log
}
if [ X$1 = X ]
then
	log4s error "��������ȷ�Ĳ���"
	exit 1;
fi

pdatabases $1;
getrmd $1;
notintable $1;
getmaxfrag $1;
if [ X$2 = X ]
then
	log4s info "��ǰΪ��ʱģʽ"
	if [ $errornum != 0 ]
	then
		log4s error "���ݿ� $1 �У��� $errornum ���ڴ������Բ�����ɾ����Ƭ���������������鿴alarm.log"
	else
		log4s info "���ݿ� $1 �У�һ����������ʼɾ����Ƭ"
		delfrag $1
	fi
fi
if [ X$2 = Xmanual ]
then
	log4s info "��ǰΪ�ֶ�ģʽ"
	if [ $errornum != 0 ]
	then
		log4s error "���ݿ� $1 �У��� $errornum ���ڴ��󣬾��������鿴alarm.log�����������ֶ�ģʽ�����������в���"
		delfrag $1
	else
		log4s info "���ݿ� $1 �У�һ����������ʼɾ����Ƭ"
		delfrag $1
	fi
fi