#!/bin/sh
dodir=/home/informix/jiankong          	         #脚本工作目录，所有操作均会在这个目录执行
log=$dodir/root.log                              #操作记录日志
alarmlog=$dodir/alarm.log                        #记录所有告警的日志
alarmcode=123                                    #告警码
remaindernum=1                                   #rmd分区中的数据行数的阀值
fragdaynum=3                                     #分片必须包含从今天起向后数该值的天数
ckptnum=3                                        #数据库处于ckpt状态多少秒后告警
testflag=1                                       #测试标志位，现网使用时该值必须为0
TAGLOG=$dodir/taglog.log                           #标志日志

###以下均不可更改####
XITONGTEMP=`uname`                               
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`     #系统名称
#通用时间配置                                    
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
	log4s info "创建工作目录"
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
	#调试时先用这个，后期整合进来log4s
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


#remainder片数据量核查
getrmd()
{
	#$1是库名
	#先导出指定库的所有分片
	unload1unl="$dodir/$1.fragment.unl.$dS"
	unload2unl="$dodir/$1.fragment.unl.temp.$dS"
	alarmunl="${unload1unl}.$dS"
	echo "unload to $unload1unl select c.tabname,a.partn,b.nrows,a.exprtext[1,9] from sysfragments a,sysmaster:sysptnhdr b,systables c where a.partn=b.partnum and a.tabid=c.tabid" | dbaccess $1 1>/dev/null 2>&1
	if [ $? != 0 ]
	then
		sendalarm "数据库 $1 中，导出sysfragments表数据失败"
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
			sendalarm "数据库 $1 中，表 ${tabname} 的remainder存在 ${rows} 行数据，超过阀值 ${remaindernum} ，该remainder分片的partnum值为 ${partnum} "
		done < ${alarmunl}
	else
		log4s info "数据库 $1 中，表 ${tabname} 的rmd分区中的数据量正常"
	fi

}
#判断在tlm_table存在但是fragtabinfo不存在的表或者相反
notintable()
{
	#$1是库名
	notin1unl="$dodir/notin1.unl.$dS"
	echo "unload to ${notin1unl} select distinct(table_name) from tlm_table where table_name not in(select tabname from fragtabinfo)"|dbaccess $1 1>/dev/null 2>&1;
	if [ $? != 0 ]
	then
		sendalarm "数据库 $1 中，判断表存在于tlm_table但是不存在于fragtabinfo时，从数据库导出数据失败"
	fi
	notin1num=`wc -l $notin1unl|awk '{print $1}'`
	if [ $notin1num != 0 ]
	then
		while read hang
		do
			tabname=`echo $hang|awk -F'|' '{print $1}'`
			sendalarm "数据库 $1 中，表 $tabname 存在于tlm_table，但是不存在于fragtabinfo表。"
		done < $notin1unl
	else
		log4s info "数据库 $1 中，tlm_table表中记录的表都存在于fragtabinfo中，正常"
	fi
	notin2unl="$dodir/notin2.unl.$dS"
	echo "unload to ${notin2unl} select distinct(tabname) from fragtabinfo where tabname not in(select table_name from tlm_table)"|dbaccess $1 1>/dev/null 2>&1;
	if [ $? != 0 ]
	then
		sendalarm "数据库 $1 中，判断表存在于fragtabinfo但是不存在于tlm_table时，从数据库导出数据失败"
	fi
	notin2num=`wc -l $notin2unl|awk '{print $1}'`
	if [ $notin2num != 0 ]
	then
		while read hang
		do
			tabname=`echo $hang|awk -F'|' '{print $1}'`
			sendalarm "数据库 $1 中，表 $tabname 存在于fragtabinfo，但是不存在于表tlm_table。"
		done < $notin2unl
	else
		log4s info "数据库 $1 中，表fragtabinfo中记录的表都存在于tlm_table中，正常"
	fi

}

#判断分片最新日期（当前只能从fragtabinfo获取)
getmaxfrag()
{
	allfragtabinfounl="$dodir/allfragtabinfo.unl.$dS"
	echo "unload to $allfragtabinfounl select tabname,max(endtime[1,8]) from fragtabinfo group by tabname"|dbaccess $1 1>/dev/null 2>&1;
	if [ $? != 0 ]
	then
		sendalarm "数据库 $1 中，判断分片最后日期时，从数据库导出数据失败"
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
				sendalarm "数据库 $1 中，表 $tabname 分片的最后一片的最后一天时间为 $tablastday ,小于预设的 $fragdaynum 天的阀值"
			else
				log4s "数据库 $1 中，表 $tabname 分片时间正常"
			fi
		done < $allfragtabinfounl
	else
		log4s info "数据库 $1 中，所有表在fragtabinfo中的最新日期都包括3天后的日期，可以正常使用"
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
			sendalarm "判断ckpt状态时，从数据库导出数据失败"
		fi
		ckptstatus=`tail  $ckptunl|awk -F'|' '{print $1}'`
		if [ $testflag = 0 ]
		then
			rm -rf $ckptunl
		fi
		if [ $ckptstatus = 1 ]
		then
			let tempckptnum=tempckptnum+1
			log4s "第 $i 次检查，当前为ckpt状态，等待 $ckptnumjiange 秒后继续检查"
			if [ $tempckptnum = $ckptnum ]
			then
				sendalarm "ckpt状态已经连续 $ckptnum 次，每次间隔 $ckptnumjiange 秒处于ckpt状态，请检查数据库"
				break;
			fi
			sleep $ckptnumjiange;
		else
			log4s info "ckpt状态正常"
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
	--可以添加sysptprof表等
	,sysmaster:sysptprof d
	where a.partnum=b.partnum
	and a.lockid=c.partnum
	--from中出现两次systabnames，是为了分别提供partnum和lockid的tabname，确定索引和表的关系。
	and a.flags not in ('2310','2054','3334','3078','2081')
	--指定数据库
	--and b.dbsname='min'
	--业务主控：
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
		log4s "不存在table.${dS}.unl，无法生成顺扫报告"
		return 1;
	fi
	if [ ! -f $dodir/seqscan.log ]
	then
		touch $dodir/seqscan.log
		chmod 777 $dodir/seqscan.log
	fi
	>$baogao
	xhtml "<html><head><title>顺序扫描记录</title></head><body>" 
	xhtml "<table border="1">"
	xhtml "<tr>"
	xhtml "<th>表名</th><th>partnum</th><th>行数</th><th>顺序扫描次数</th>"
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
	log4s "开始删除中间文件"
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
	log4s "调试模式，不删除中间文件"
fi
