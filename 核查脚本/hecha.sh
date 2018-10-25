#!/bin/sh
dodir=`pwd`
log=$dodir/result.log
alarmlog=$dodir/alarm.log
memused_percent_threshold=80       #�ڴ�ռ�÷�ֵ
iowait_threshold=10                #iowait��ֵ�����ڴ�ֵ�澯
cpuidle_threshold=10               #cpu idleֵ�����ڴ�ֵ�澯
df_threshold=10                    #Ӳ�̿ռ�ʹ�ðٷֱȣ����ڴ�ֵ�澯
servername=hdr1                    #���ݿ��servername
testflag=1
log4s()
{
	if [ $# = 2 ]
	then
		if [ $1 = info ]
		then
			echo "OK $2"
			echo "OK $2" >> $log
		elif [ $1 = error ]
		then
			echo "ERROR $2"
			echo "ERROR $2" >> $alarmlog
		else
			echo "NULL $2"
			echo "NULL $2" >> $log
		fi
	else
		echo "log4s ������������"
		echo "log4s ������������" >> $alarmlog
	fi
}
systeminfo()
{
	xtbanben=`cat /etc/issue|grep Linux`
	log4s info "ϵͳ�汾Ϊ��${xtbanben}"
	log4s info "��ʼͳ���ڴ���Ϣ"
	cpunum=`cat /proc/cpuinfo |grep processor|awk -F':' '{print $1}'|uniq -c|awk '{print $1}'`
	totalmem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $1}'`
	usedmem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $2}'`
	freemem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $3}'`
	buffersmem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $5}'`
	cachedmem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $6}'`
	let trueusedmem=usedmem-buffersmem-cachedmem
	let trueusedmem_percent=trueusedmem/totalmem
	log4s info "�ڴ��ܹ���${totalmem}����ǰ��ʵռ��Ϊ��${trueusedmem}"
	if [ $trueusedmem_percent -ge $memused_percent_threshold ]
	then
		log4s error "�ڴ�ռ�ðٷֱ�Ϊ${trueusedmem_percent}��������ֵ${memused_percent_threshold}"
	else
		log4s info "�ڴ�ռ�ðٷֱ�Ϊ${trueusedmem_percent}���������"
	fi
	log4s info "��ʼִ��vmstat 1 60����ȴ�"
	vmstat 1 60 > $dodir/vmstat.log
	grep -v procs $dodir/vmstat.log|grep -v swpd > $dodir/vmstatchuli.log
	iowaitnum=0
	cpuidlenum=0
	while read hang
	do
		iowait=`echo "$hang"|awk '{ print $(NF-1) }'`
		if [ $iowait -ge $iowait_threshold ]
		then
			let iowaitnum=iowaitnum+1
		fi
		cpuidle=`echo "$hang"|awk '{ print $(NF-2) }'`
		if [ $cpuidle -lt $cpuidle_threshold ]
		thne
			let cpuidlenum=cpuidlenum+1
		fi
	done < $dodir/vmstatchuli.log
	
	if [ $iowaitnum -ne 0 ]
	then
		log4s error "ִ��vmstat60�룬iowait������ֵ${iowait_threshold}�ĸ���Ϊ${iowaitnum}"
	else
		log4s info "iowait����"
	fi
	if [ $cpuidlenum -ne 0 ]
	then
		log4s error "ִ��vmstat60�룬cpu idle������ֵ${cpuidle_threshold}�ĸ���Ϊ${cpuidlenum}"
	else
		log4s info "cpu idle����"
	fi
	log4s info "��ʼͳ��Ӳ����Ϣ"
	df -P|grep -v "/dev/shm"|grep -v "/boot"|grep -v Filesystem|sed 's/%//g' > $dodir/df.log
	while read hang
	do
		dfshengyu=`echo "hang"|awk '{ print $(NF-1) }'`
		dfmulu=`echo "hang"|awk '{ print $(NF) }'`
		if [ $dfshengyu -gt $df_threshold ]
		then
			log4s error "Ŀ¼${dfmulu}��ʹ���ʴ��ڷ�ֵ${df_threshold}����ע��"
		else
			log4s info "Ŀ¼${dfmulu}��ʹ����С�ڷ�ֵ${df_threshold}���������"
		fi
	done < $dodir/df.log
}
onstatinfo()
{
	log4s info "��ʼͳ�����ݿ�ռ���Ϣ"
	echo "unload to ${dodir}/dbsinfo.unl select a.dbsnum,b.name,a.dbssize,a.dbsfree  from  (  select dbsnum,sum(chksize) dbssize,trunc(sum(nfree)*avg(pagesize)/1024/1024/1024,0) dbsfree  from syschunks  group by dbsnum  ) a, (select dbsnum,name  from sysdbspaces) b  where a.dbsnum=b.dbsnum"|dbaccess sysmaster@$servername
	while read hang
	do
		dbsname=`echo $hang|awk -F'|' '{print $2}'`
		dbsfree=`echo $hang|awk -F'|' '{print $4}'`
		if [ $dbsname != logdbs ] && [ $dbsname != phydbs ] && [ $dbsfree -lt 2 ]
		then
			log4s error "${dbsname} ʣ��ռ�С��2G����ע��"
		else
			log4s info "${dbsname} �ռ�����"
		fi
	done < ${dodir}/dbsinfo.unl
	dbsPdnum=`onstat -d|grep PD|wc -l|awk '{print $1}'`
	if [ $dbsPdnum != 0 ] 
	then
		log4s error "��ʹ��onstat -d�鿴������DOWD����dbs����ע��"
	else
		log4s info "���ݿ�dbs״̬����"
	fi
	
	log4s info "��ʼ�߼���������־���"
	echo "unload ${dodir}phylogs.log select name from sysdbspaces where dbsnum=(select dbsnum from syschunks where chknum=(select pl_chunk from sysplog))"|dbaccess sysmaster@$servername
	phyweizhi=`head -1 ${dodir}phylogs.log|awk -F'|' '{print $1}'`
	if [ X$phyweizhi != Xphydbs ]
	then
		log4s error "������־û�з���phydbs�£���ע��"
	else
		log4s info "������־���λ����ȷ��"
	fi
	onstat -l > ${dodir}/onstat.log
	echo "unload to ${dodir}/logaddr.unl select substr(HEX(address),11,8) address from syslogfil"
}
qingli()
{
	if [ $testflag = 0 ]
	then
		$dodir/vmstat.log
		$dodir/vmstatchuli.log
		$dodir/df.log
		${dodir}/dbsinfo.unl
		${dodir}phylogs.log
		${dodir}/onstat.log
	fi
}