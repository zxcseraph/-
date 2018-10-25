#!/bin/sh
dodir=`pwd`
log=$dodir/result.log
alarmlog=$dodir/alarm.log
memused_percent_threshold=80       #内存占用阀值
iowait_threshold=10                #iowait阀值，大于此值告警
cpuidle_threshold=10               #cpu idle值，低于此值告警
df_threshold=10                    #硬盘空间使用百分比，大于此值告警
servername=hdr1                    #数据库的servername
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
		echo "log4s 参数个数不对"
		echo "log4s 参数个数不对" >> $alarmlog
	fi
}
systeminfo()
{
	xtbanben=`cat /etc/issue|grep Linux`
	log4s info "系统版本为：${xtbanben}"
	log4s info "开始统计内存信息"
	cpunum=`cat /proc/cpuinfo |grep processor|awk -F':' '{print $1}'|uniq -c|awk '{print $1}'`
	totalmem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $1}'`
	usedmem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $2}'`
	freemem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $3}'`
	buffersmem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $5}'`
	cachedmem=`free |grep Mem|awk -F':' '{print $2}'|awk '{print $6}'`
	let trueusedmem=usedmem-buffersmem-cachedmem
	let trueusedmem_percent=trueusedmem/totalmem
	log4s info "内存总共：${totalmem}，当前真实占用为：${trueusedmem}"
	if [ $trueusedmem_percent -ge $memused_percent_threshold ]
	then
		log4s error "内存占用百分比为${trueusedmem_percent}，超过阀值${memused_percent_threshold}"
	else
		log4s info "内存占用百分比为${trueusedmem_percent}，检测正常"
	fi
	log4s info "开始执行vmstat 1 60，请等待"
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
		log4s error "执行vmstat60秒，iowait超过阀值${iowait_threshold}的个数为${iowaitnum}"
	else
		log4s info "iowait正常"
	fi
	if [ $cpuidlenum -ne 0 ]
	then
		log4s error "执行vmstat60秒，cpu idle超过阀值${cpuidle_threshold}的个数为${cpuidlenum}"
	else
		log4s info "cpu idle正常"
	fi
	log4s info "开始统计硬盘信息"
	df -P|grep -v "/dev/shm"|grep -v "/boot"|grep -v Filesystem|sed 's/%//g' > $dodir/df.log
	while read hang
	do
		dfshengyu=`echo "hang"|awk '{ print $(NF-1) }'`
		dfmulu=`echo "hang"|awk '{ print $(NF) }'`
		if [ $dfshengyu -gt $df_threshold ]
		then
			log4s error "目录${dfmulu}的使用率大于阀值${df_threshold}，请注意"
		else
			log4s info "目录${dfmulu}的使用率小于阀值${df_threshold}，检测正常"
		fi
	done < $dodir/df.log
}
onstatinfo()
{
	log4s info "开始统计数据库空间信息"
	echo "unload to ${dodir}/dbsinfo.unl select a.dbsnum,b.name,a.dbssize,a.dbsfree  from  (  select dbsnum,sum(chksize) dbssize,trunc(sum(nfree)*avg(pagesize)/1024/1024/1024,0) dbsfree  from syschunks  group by dbsnum  ) a, (select dbsnum,name  from sysdbspaces) b  where a.dbsnum=b.dbsnum"|dbaccess sysmaster@$servername
	while read hang
	do
		dbsname=`echo $hang|awk -F'|' '{print $2}'`
		dbsfree=`echo $hang|awk -F'|' '{print $4}'`
		if [ $dbsname != logdbs ] && [ $dbsname != phydbs ] && [ $dbsfree -lt 2 ]
		then
			log4s error "${dbsname} 剩余空间小于2G，请注意"
		else
			log4s info "${dbsname} 空间正常"
		fi
	done < ${dodir}/dbsinfo.unl
	dbsPdnum=`onstat -d|grep PD|wc -l|awk '{print $1}'`
	if [ $dbsPdnum != 0 ] 
	then
		log4s error "请使用onstat -d查看，存在DOWD掉的dbs，请注意"
	else
		log4s info "数据库dbs状态正常"
	fi
	
	log4s info "开始逻辑和物理日志检查"
	echo "unload ${dodir}phylogs.log select name from sysdbspaces where dbsnum=(select dbsnum from syschunks where chknum=(select pl_chunk from sysplog))"|dbaccess sysmaster@$servername
	phyweizhi=`head -1 ${dodir}phylogs.log|awk -F'|' '{print $1}'`
	if [ X$phyweizhi != Xphydbs ]
	then
		log4s error "物理日志没有放在phydbs下，请注意"
	else
		log4s info "物理日志存放位置正确。"
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