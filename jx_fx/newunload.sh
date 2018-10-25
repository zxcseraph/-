#!/bin/sh
dbid=$1
DIR=$2
log=$DIR/unload.log
TAGLOG=$DIR/taglog.log
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
dH=`date +"%Y%m%d%H"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dMonly=`date +"%M"`
PWDDIR=`pwd`

XN=1			#如果为0则不启动性能统计

export LC_TIME="POSIX"


if [ ! -d $DIR ]
then
	log4s "${DIR}不存在，自动建立目录"
	mkdir $DIR
	if [ $? = 0 ]
	then
		log4s "${DIR}创建成功"
	else
		log4s "${DIR}创建失败"
		exit 1;
	fi
fi
log4s()
{
	echo "$1" >> $log
	echo "$1"
}
if [ ! -f $DIR/newunload_xn_top.sh ]
then
	log4s "复制top脚本到${DIR}下"
	cp $PWDDIR/newunload_xn_top.sh $DIR/newunload_xn_top.sh
fi
if [ ! -f $DIR/newunload_xn_sar_vm.sh ]
then
	log4s "复制sar_vm脚本到${DIR}下"
	cp $PWDDIR/newunload_xn_sar_vm.sh $DIR/newunload_xn_sar_vm.sh
fi
Global_Info()
{
	#Global_Info.ENV 每天一次
	log4s "Global_Info模块开始执行"
	dbaccess sysmaster<<EOF
	unload to ${DIR}/env.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	b.env_value servername,
	a.type drtype,a.state drstate,
	a.name drpaired,d.env_value idsdir,
	c.env_value onconfig
	from sysdri a,
	(
		select env_value from sysenv
		where env_name="INFORMIXSERVER"
	) b,
	(
		select env_value from sysenv
		where env_name="ONCONFIG"
	) c,
	(
		select env_value from sysenv
		where env_name="INFORMIXDIR"
	) d
EOF
	if [ $? = 0 ]
	then
		log4s "Global_Info.ENV操作成功"
	else
		log4s "Global_Info.ENV操作失败"
	fi
	#Global Info.Machine Info
	os_nodename=`hostname`
	os_name=`uname -s`
	db_version=`onstat -V |awk '{print $6}'`
	
	if [ $os_name = 'AIX' ]; then
	os_version=`oslevel -r`
	os_kernel_type=`prtconf -k|awk '{print $3}'`
	os_num_procs=`bindprocessor -q|awk '{print NF-4}'`
	os_type_procs=`uname -p`
	os_mem_total=`prtconf -m|awk '{printf "%d", $3/1024+1}'`
	fi
	
	if [ $os_name = 'Linux' ]; then
	os_version=`uname -r`
	os_kernel_type=`uname -p`
	os_num_procs=`cat /proc/cpuinfo|grep proce|wc -l`
	os_type_procs=`uname -p`
	os_mem_total=`cat /proc/meminfo|grep MemTotal|awk '{printf "%d", $2/1024/1024+1}'`
	fi
	
	if [ $os_name = 'HP-UX' ]; then
	os_version=`uname -r`
	os_kernel_type=`uname -m`
	os_num_procs=`machinfo | grep "^[0-9\ ]*logical"|awk '{print $1}'`
	os_type_procs=' '
	os_mem_total=`machinfo |grep Memory|awk '{printf "%d" ,$2/1024+1}'`
	fi
	echo "$dbid|$time|$timenowUTC|$os_nodename|$os_name|$os_version|$os_kernel_type|$os_num_procs|$os_type_procs|$os_mem_total|$db_version|" >>${DIR}/machineinfo.${dS}.temp
	
	#Global_Info.Time
	#前两个字段需要统计时才能生成，cnum也是统计统计时间段内的个数
	dbaccess sysmaster<<EOF
	unload to ${DIR}/Time.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	dbinfo('UTC_TO_DATETIME',sh_pfclrtime) onstat_CLR_time ,
	TO_CHAR(dbinfo('UTC_TO_DATETIME',sh_boottime),'%Y%m%d%H%M%S') start_time,
	 substr($timenowUTC-sh_boottime,1,10) runsecond from sysshmvals;
EOF
	if [ $? = 0 ]
	then
		log4s "Global_Info.Time操作成功"
	else
		log4s "Global_Info.Time操作失败"
	fi
	#Global Info.Database Info
	dbaccess sysmaster<<EOF
	unload to ${DIR}/database.${dt}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	name,owner,created,is_logging,is_buff_log,is_ansi,is_nls
	from sysdatabases
	where name not in ('sysmaster','sysutils','sysadmin','sysuser','onpload','syscdr');
EOF
	if [ $? = 0 ]
	then
		log4s "Global_Info.Time操作成功"
	else
		log4s "Global_Info.Time操作失败"
	fi
	cp ${DIR}/database.${dt}.temp ${DIR}/database.unl
	cat ${DIR}/env.${dS}.temp						>> ${DIR}/env.${dt}.temp
	cat ${DIR}/machineinfo.${dS}.temp		>> ${DIR}/machineinfo.${dt}.temp
	cat ${DIR}/Time.${dS}.temp					>> ${DIR}/Time.${dt}.temp
	rm ${DIR}/env.${dS}.temp
	rm ${DIR}/machineinfo.${dS}.temp
	rm ${DIR}/Time.${dS}.temp
}

DB_Profile()
{
	#DB Profile.IO_Info
	#这个是需要差值的环比类型
	log4s "DB_Profile模块开始操作"
	dbaccess sysmaster<<EOF
	unload to ${DIR}/io.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,dskreads.value dskreads,pagreads.value pagreads,bufreads.value bufreads,
	dskwrites.value dskwrites,pagwrites.value pagwrites,bufwrites.value bufwrites,
	plgwrites.value plgwrites,plgpagewrites.value plgpagewrites,llgrecs.value llgrecs,
	llgpagewrites.value llgpagewrites
	from
	(select value from sysprofile where name="dskreads")       dskreads,
	(select value from sysprofile where name="pagreads")       pagreads,
	(select value from sysprofile where name="bufreads")       bufreads,
	(select value from sysprofile where name="dskwrites")      dskwrites,
	(select value from sysprofile where name="pagwrites")      pagwrites,
	(select value from sysprofile where name="bufwrites")      bufwrites,
	(select value from sysprofile where name="plgwrites")      plgwrites,
	(select value from sysprofile where name="plgpagewrites")  plgpagewrites,
	(select value from sysprofile where name="llgrecs")        llgrecs,
	(select value from sysprofile where name="llgpagewrites")  llgpagewrites
EOF
	if [ $? = 0 ]
	then
		log4s "DB_Profile.IO_Info操作成功"
	else
		log4s "DB_Profile.IO_Info操作失败"
	fi
	#DB Profile.SQL_Profile
	dbaccess sysmaster<<EOF
	unload to ${DIR}/sql.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,isreads.value isreads,iswrites.value iswrites,isrewrites.value isrewrites,isdeletes.value isdeletes,
	iscommits.value iscommits,isrollbacks.value isrollbacks,seqscans.value seqscans,totalsorts.value totalsorts,
	memsorts.value memsorts,disksorts.value disksorts 
	from
	(select value from sysprofile where name="isreads")      isreads,
	(select value from sysprofile where name="iswrites")     iswrites,
	(select value from sysprofile where name="isrewrites")   isrewrites,
	(select value from sysprofile where name="isdeletes")    isdeletes,
	(select value from sysprofile where name="iscommits")    iscommits,
	(select value from sysprofile where name="isrollbacks")  isrollbacks,
	(select value from sysprofile where name="seqscans")     seqscans,
	(select value from sysprofile where name="totalsorts")   totalsorts,
	(select value from sysprofile where name="memsorts")     memsorts,
	(select value from sysprofile where name="disksorts")    disksorts
EOF
	if [ $? = 0 ]
	then
		log4s "DB_Profile.SQL_Profile操作成功"
	else
		log4s "DB_Profile.SQL_Profile操作失败"
	fi
	#DB_Profile.Event_Info
	dbaccess sysmaster<<EOF
	unload to ${DIR}/envinfo.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,numckpts.value numckpts,ckptwts.value ckptwts,lockwts.value lockwts,
	lktouts.value lktouts,buffwts.value buffwts,latchwts.value latchwts,
	deadlks.value deadlks,ovlock.value ovlock,ovuser.value ovuser,ovtrans.value ovtrans
	from
	(select value from sysprofile where name="numckpts")   numckpts,
	(select value from sysprofile where name="ckptwts")    ckptwts,
	(select value from sysprofile where name="lockwts")    lockwts,
	(select value from sysprofile where name="lktouts")    lktouts,
	(select value from sysprofile where name="buffwts")    buffwts,
	(select value from sysprofile where name="latchwts")   latchwts,
	(select value from sysprofile where name="deadlks")    deadlks,
	(select value from sysprofile where name="ovlock")     ovlock,
	(select value from sysprofile where name="ovuser")     ovuser,
	(select value from sysprofile where name="ovtrans")    ovtrans
EOF
	if [ $? = 0 ]
	then
		log4s "DB_Profile.Event_Info操作成功"
	else
		log4s "DB_Profile.Event_Info操作失败"
	fi
	#DB_Profile.LRU_Info
	dbaccess sysmaster<<EOF
	unload to ${DIR}/lruinfo.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,fgwrites.value fgwrites,lruwrites.value lruwrites,
	chunkwrites.value chunkwrites,flushes.value flushes
	from
	(select value from sysprofile where name="fgwrites")     fgwrites,
	(select value from sysprofile where name="lruwrites")    lruwrites,
	(select value from sysprofile where name="chunkwrites")  chunkwrites,
	(select value from sysprofile where name="flushes")      flushes
EOF
	if [ $? = 0 ]
	then
		log4s "DB_Profile.LRU_Info操作成功"
	else
		log4s "DB_Profile.LRU_Info操作失败"
	fi
	cat ${DIR}/io.${dS}.temp				>> ${DIR}/io.${dt}.temp
	cat ${DIR}/sql.${dS}.temp				>> ${DIR}/sql.${dt}.temp
	cat ${DIR}/envinfo.${dS}.temp		>> ${DIR}/envinfo.${dt}.temp
	cat ${DIR}/lruinfo.${dS}.temp		>> ${DIR}/lruinfo.${dt}.temp
	rm ${DIR}/io.${dS}.temp
	rm ${DIR}/sql.${dS}.temp
	rm ${DIR}/envinfo.${dS}.temp
	rm ${DIR}/lruinfo.${dS}.temp
}
Memory_Info()
{
	log4s "Memory_Info模块开始"
	#Memory_Info.Memory_Used_OR_Virtual_Memory_Used
	dbaccess sysmaster<<EOF
	unload to ${DIR}/meminfo.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	case when seg_class=1 then 'R'
	when seg_class=2 then 'V'
	when seg_class=4 then 'B'
	end as seg_class,
	seg_blkused+seg_blkfree sum,
	seg_blkused,seg_blkfree
	from syssegments
EOF
	if [ $? = 0 ]
	then
		log4s "Memory_Info.Memory_Used_OR_Virtual_Memory_Used操作成功"
	else
		log4s "Memory_Info.Memory_Used_OR_Virtual_Memory_Used操作失败"
	fi
	cat ${DIR}/meminfo.${dS}.temp >> ${DIR}/meminfo.${dt}.temp
	rm ${DIR}/meminfo.${dS}.temp
}
Process_Info()
{
	log4s "Process_Info模块开始"
	#Process_Info.CPU_VP
	dbaccess sysmaster<<EOF
	unload to ${DIR}/processinfo.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	classname,sum(usecs_user) usecs_user ,sum(usecs_sys) usecs_sys,
	sum(total_semops) total_semops,sum(total_busy_wts) total_busy_wts,
	sum(total_yields) total_yields,sum(total_spins) total_spins,
	sum(steal_attempts) steal_attempts,sum(steal_attempts_suc) steal_attempts_suc,
	sum(idle_search) idle_search,sum(idle_search_suc) idle_search_suc,
	sum(vp_poll_scheds) vp_poll_scheds,sum(vp_mt_naps) vp_mt_naps,
	sum(thread_run) thread_run,sum(thread_idle) thread_idle,
	sum(thread_poll_idle) thread_poll_idle
	from sysvplst
	group by classname
	order by classname;
EOF
	if [ $? = 0 ]
	then
		log4s "Process_Info.CPU_VP操作成功"
	else
		log4s "Process_Info.CPU_VP操作失败"
	fi
	cat ${DIR}/processinfo.${dS}.temp >> ${DIR}/processinfo.${dt}.temp
	rm ${DIR}/processinfo.${dS}.temp
	#有用的是classname,busy_secs是usecs_user的和，YIELDS是total_yields的和；thread_run就是本身的和，其中class=soc的值是N/A
}
Disk_Info()
{
	log4s "Disk_Info模块开始"
	#Disk_Info.CHUNK_IO
	dbaccess sysmaster<<EOF
	unload to ${DIR}/chunkio.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,fname,chknum,
	reads,writes,pagesread,pageswritten,readtime,writetime,readtime+writetime tot_time
	from syschktab
EOF
	if [ $? = 0 ]
	then
		log4s "Disk_Info.CHUNK_IO操作成功"
	else
		log4s "Disk_Info.CHUNK_IO操作失败"
	fi
	#Disk_Info.Dbspaces_Info
	dbaccess sysmaster<<EOF
	unload to ${DIR}/dbspacesinfo1.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	dbsnum,fchunk,nchunks,pagesize,
	case when is_mirrored=1 then "mirrored"
	when is_blobspace=1 then "blobspace"
	when is_sbspace=1 then "sbspace"
	when is_temp=1 then "temp"
	else "Operational" end as dbstype,
	name
	from sysdbspaces
EOF
	if [ $? = 0 ]
	then
		log4s "Disk_Info.Dbspaces_Info1操作成功"
	else
		log4s "Disk_Info.Dbspaces_Info1操作失败"
	fi
	dbaccess sysmaster<<EOF
	unload to ${DIR}/dbspacesinfo2.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	chknum,dbsnum,offset,chksize,nfree,
	case when is_offline=1 then "offline"
	when is_recovering=1 then "recovering"
	when is_blobchunk=1 then "blobchunk"
	when is_sbchunk=1 then "sbchunk"
	when is_inconsistent=1 then "inconsistent"
	else "Operational" end as chkstatus,
	fname
	from syschunks;
EOF
	if [ $? = 0 ]
	then
		log4s "Disk_Info.Dbspaces_Info2操作成功"
	else
		log4s "Disk_Info.Dbspaces_Info2操作失败"
	fi
	cat ${DIR}/chunkio.${dS}.temp					>> ${DIR}/chunkio.${dt}.temp	
	cat ${DIR}/dbspacesinfo1.${dS}.temp		>> ${DIR}/dbspacesinfo1.${dt}.temp
	cat ${DIR}/dbspacesinfo2.${dS}.temp		>> ${DIR}/dbspacesinfo2.${dt}.temp
	rm ${DIR}/chunkio.${dS}.temp
	rm ${DIR}/dbspacesinfo1.${dS}.temp
	rm ${DIR}/dbspacesinfo2.${dS}.temp
}
Table_Info()
{
	log4s "Table_Info模块开始"
	#增删改查操作最多的表和索引
	dbaccess sysmaster<<EOF
	unload to ${DIR}/seqscans.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,dbsname,tabname,partnum,
	seqscans,bufreads,pagreads,lockwts,lktouts,iswrites,isrewrites,isdeletes,deadlks from sysptprof
	order by partnum
EOF
	if [ $? = 0 ]
	then
		log4s "Table_Info详细信息操作成功"
	else
		log4s "Table_Info详细信息操作失败"
	fi
	#统计表和索引基本信息
	while read A
	do
		dbtemp=`echo $A|awk -F'|' '{print $4}'`
		dbaccess $dbtemp<<EOF
		unload to ${DIR}/indexes.$dt.temp.$dbtemp
		select "$dbid" dbid,"$time" time,"$dbtemp" database,
		a.idxname,a.owner,a.leaves,a.nunique,a.idxtype,b.tabname,b.owner,b.tabid
		from sysindexes a,systables b
		where a.tabid>100
		and a.tabid=b.tabid
EOF
	if [ $? = 0 ]
	then
		log4s "Table_Info表信息操作成功"
	else
		log4s "Table_Info表信息操作失败"
	fi
		dbaccess $dbtemp<<EOF
		unload to ${DIR}/tables.$dt.temp.$dbtemp
		select "$dbid" dbid,"$time" time,"$dbtemp" database,
		tabname,owner,partnum,tabid,rowsize,ncols,nrows,tabtype,locklevel,npused,fextsize,nextsize
		from systables
		where tabid>100
EOF
	if [ $? = 0 ]
	then
		log4s "Table_Info索引信息操作成功"
	else
		log4s "Table_Info索引信息操作失败"
	fi
	done < ${DIR}/database.unl
	cat ${DIR}/indexes.$dt.temp.* >> ${DIR}/indexes.$dt.temp
	rm -rf ${DIR}/indexes.$dt.temp.*
	cat ${DIR}/tables.$dt.temp.* >> ${DIR}/tables.$dt.temp
	rm -rf ${DIR}/tables.$dt.temp.*
	cat ${DIR}/seqscans.${dS}.temp >> ${DIR}/seqscans.${dt}.temp
	rm ${DIR}/seqscans.${dS}.temp
}
Session_info()
{
	log4s "Session_info模块开始"
	#由于sid会变化，所以不能用直接环比，需要导入数据库后根据每个sid进行环比
	dbaccess sysmaster<<EOF
	unload to ${DIR}/sessioninfo.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	a.sid sid,b.lockreqs lockreqs,
	b.isreads isreads,b.iswrites iswrites,b.isrewrites isrewrites,b.isdeletes isdeletes,
	b.iscommits iscommits,b.isrollbacks isrollbacks,
	b.bufreads bufreads,b.bufwrites bufwrites,b.seqscans seqscans
	from syssessions a,syssesprof b
	where a.sid = b.sid
EOF
	if [ $? = 0 ]
	then
		log4s "Session_info操作成功"
	else
		log4s "Session_info操作失败"
	fi
	cat ${DIR}/sessioninfo.${dS}.temp >> ${DIR}/sessioninfo.${dt}.temp
	rm ${DIR}/sessioninfo.${dS}.temp
}
Log_info()
{
	log4s "Log_info模块开始"
	dbaccess sysmaster<<EOF
	unload to ${DIR}/loginfo.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	count(*) lognum, trunc(avg(b.chunk),1) chunknum, trunc(avg(a.size)) logsize,sum(is_backed_up) BACKUP_NUM,
	sum(decode(is_current,1,a.uniqid,0)) CURR_UNIQ,sum(decode(is_current,1,a.used,0)) CURR_USED
	from syslogs a, syslogfil b where a.number=b.number;
EOF
	if [ $? = 0 ]
	then
		log4s "Log_info操作成功"
	else
		log4s "Log_info操作失败"
	fi
	cat ${DIR}/loginfo.${dS}.temp >> ${DIR}/loginfo.${dt}.temp
	rm ${DIR}/loginfo.${dS}.temp
}
Config_info()
{
	log4s "Log_info模块开始"
	dbaccess sysmaster<<EOF
	unload to ${DIR}/configinfo.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	cf_name,cf_original cf_oncfg_onboot,cf_effective effective
	from sysconfig
	where cf_name in
	('ROOTNAME','ROOTPATH','ROOTSIZE','PHYSDBS','PHYSFILE','LOGBUFF','LOGFILES','LOGSIZE','DBSPACETEMP',
	'DBSERVERNAME','DBSERVERALIASES','MULTIPROCESSOR','NUMCPUVPS','VPCLASS','AFF_NPROCS','AFF_SPROC',
	'NETTYPE','TAPEBLK','TAPEDEV','TAPESIZE','LTAPEBLK','LTAPESIZE','SHMBASE','SHMVIRTSIZE','SHMADD',
	'BUFFERPOOL','CLEANERS','LOCKS','CKPTINTVL','OPTCOMPIND','DRAUTO','ALARMPROGRAM','MSGPATH','BAR_ACT_LOG')
	order by cf_name
EOF
	if [ $? = 0 ]
	then
		log4s "Config_info操作成功"
	else
		log4s "Config_info操作失败"
	fi
	cat ${DIR}/configinfo.${dS}.temp  >> ${DIR}/configinfo.${dt}.temp
	rm ${DIR}/configinfo.${dS}.temp
}
SQLHOSTS()
{
	log4s "SQLHOSTS模块开始"
	dbaccess sysmaster<<EOF
	unload to ${DIR}/sqlhosts.${dS}.temp
	select "$dbid" dbid,"$time" time,"$timenowUTC" utctime,
	dbsvrnm,nettype,hostname,svcname
	from syssqlhosts
EOF
	if [ $? = 0 ]
	then
		log4s "SQLHOSTS操作成功"
	else
		log4s "SQLHOSTS操作失败"
	fi
	cat ${DIR}/sqlhosts.${dS}.temp >> ${DIR}/sqlhosts.${dt}.temp
	rm ${DIR}/sqlhosts.${dS}.temp
}
#调用性能统计，每次启动脚本都会检查，如果性能统计没有启动则启动起来
if [ $XN = 1 ]
then
	numsarvm=`ps -ef|grep newunload_xn_sar_vm|wc -l|awk '{print $1}'`
	numtop=`ps -ef|grep newunload_xn_top|wc -l|awk '{print $1}'`
	if [ X$numsarvm = X1 ]
	then
		nohup sh $DIR/newunload_xn_sar_vm.sh "$1" "$2" &
	fi
	if [ X$numtop = X1 ]
	then
		nohup sh $DIR/newunload_xn_top.sh "$1" "$2" &
	fi
fi
if [ ! -f $TAGLOG ]
then
	touch $TAGLOG
fi
DAYTAG=TAGDAY-`date +'%Y-%m-%d'`
DAYTAGEXIST=`grep "$DAYTAG" $TAGLOG |wc -l|awk '{print $1}'`
let dMcount=dMonly/5
FIVEMINTAG=TAGDAY-${dH}`printf '%02d' $dMcount`
FIVEMINTAGEXIST=`grep "$FIVEMINTAG" $TAGLOG |wc -l|awk '{print $1}'`
#脚本第一次使用执行

#每天执行一次的
if [ X$DAYTAGEXIST = X0 ]
then
	echo $DAYTAG >> $TAGLOG
	log4s "脚本$dt第一次执行，执行每天任务"
	Global_Info
	Config_info
	SQLHOSTS
	find $DIR -name "*.temp" -atime +7 -exec rm -rf {} \;
fi
#五分钟一次的
if [ X$FIVEMINTAGEXIST = X0 ]
then
	echo $FIVEMINTAG >> $TAGLOG
	log4s "执行5分钟任务"
	Session_info
fi

log4s "执行每次任务"
DB_Profile
Memory_Info
Process_Info
Disk_Info
Table_Info
Log_info


