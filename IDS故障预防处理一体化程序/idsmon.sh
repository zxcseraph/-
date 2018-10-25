#!/bin/sh
set -x
dodir=/home/informix/zxc          	         #脚本工作目录，所有操作均会在这个目录执行
log=$dodir/root.log                              #操作记录日志
alarmlog=$dodir/alarm.log                        #记录所有告警的日志
alarmcode=123                                    #告警码
remaindernum=1                                   #rmd分区中的数据行数的阀值
fragdaynum=3                                     #分片必须包含从今天起向后数该值的天数
ckptnum=3                                        #数据库处于ckpt状态多少秒后告警
testflag=1                                       #测试标志位，现网使用时该值必须为0
TAGLOG=$dodir/taglog.log                           #标志日志
seq_alarmnum1=5												#顺扫第一级，每个周期产生顺扫条数的阀值
seq_alarmrow1=10000										#顺扫第一级，超过该条数的表才会产生一级告警
seq_alarmnum2=100											#顺扫第二级，每个周期产生顺扫条数的阀值
seq_alarmrow2=500											#顺扫第二级，超过该条数的表才会产生一级告警
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
	echo "创建工作目录"
	cp $jiaobenming $dodir
fi
#获取x天之前的主体函数
DOY () 
{
#取系统时间
CURRENTDAY=`date "+%Y-%m-%d"`
BACKYEAR=`echo $CURRENTDAY|awk -F'-' '{print $1}'`
BACKMONTH=`echo $CURRENTDAY|awk -F'-' '{print $2}'`
BACKDAY=`echo $CURRENTDAY|awk -F'-' '{print $3}'`
YEAR=$BACKYEAR

#判断闰年
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
#MD表示
MD=0
#天数累计
MDTOTAL=0
NUM1=$1
	if [ $DAY -gt $NUM1 ]
	then
#超出保留日日期
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
#说明：
#注释规则：	16个井号的是区分配置和代码区域
#						3个井号的是区分代码里的判断和功能区域
#不严谨的地方：日志最后3行以上为空，会导致按照日期分割方式无法分割，待整理思路
#待优化：日志分割方式待增加按照大小，循环写入。模拟log4j
#优化的地方：大幅提高运行速度，增加配置文件检测
##################################################
################log4s配置区#################
log4spath=$dodir								#输出日志目录
log4sechoCategory=info				#输出到屏幕日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4swriteCategory=debug			#输出到文件日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4slogname=root.log					#输出日志名称
isecho=1											#输出到日志的同时是否打印到屏幕，0是不打印，1是打印

splittype=none								#日志分割方式，none不分割，day按照日期分割后缀名为YYYY-MM-DD，num为按照行模式分割，如果使用num模式则必须填写splitnum参数，这个没思路暂不支持
splitnum=1000


################log4s配置校验并初始化区，单独拿出来是为初始化只需要一次#############
log4scheck()
{
	if [ X$log4spath = X ]
	then
		echo "log4spath参数需要配置"
		exit 1;
	fi
	if [ X$log4sechoCategory = X ]
	then
		echo "log4sechoCategory参数需要配置"
		exit 1;
	fi
	if [ X$log4swriteCategory = X ]
	then
		echo "log4swriteCategory参数需要配置"
		exit 1;
	fi
	if [ X$log4slogname = X ]
	then
		echo "log4slogname参数需要配置"
		exit 1;
	fi
	if [ X$isecho = X ]
	then
		echo "isecho参数需要配置"
		exit 1;
	fi
	if [ X$splittype = X ]
	then
		echo "splittype参数需要配置"
		exit 1;
	fi
	if [ X$splittype = Xnum ]
	then
		if [ X$splitnum = X ]
		then
			echo "splitnum参数需要配置"
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
################log4s代码区#################
log4slog=${log4spath}/${log4slogname}
log4scheck;
#log4s()                       #$1是级别，$2是内容
#{
#	nowdate=`date +"%Y-%m-%d %H:%M:%S"`
#	######判断区域，保证参数严谨性
#	#判断目录及日志文件，不自动创建目录，但是会自动创建文件
#	if [ ! -d $log4spath ]
#	then
#		echo "$nowdate log4s配置的目录不存在，请确认配置是否正确"
#		exit 1;
#	fi
#	if [ ! -f $log4slog ]
#	then
#		echo "$nowdate log4s日志不存在，创建log4s日志文件"
#		echo "$nowdate log4s日志不存在，创建log4s日志文件" >> $log4slog
#	fi
#	
#	#判断参数个数
#	if [ $# -ne 2 ]
#	then
#		echo "参数个数为2个"
##		exit 1;
#	fi
#	log4sindex=0
#	
#	###分割日志区
#	#按日分割
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
#	#按行数分割
#	if [ $splittype = num ]
#	then
#		if [ ! -f $log4slog ]
#		then
#			echo "日志文件不存在，请检查配置是否正确"
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
#	######功能区域
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
	tabinfoworkdir=`pwd`
	dSt=`date +"%Y%m%d%H%M%S"`
	dbaccess sysmaster <<EOF
	unload to $tabinfoworkdir/table.$dS.temp
	select "$dSt",a.lockid,a.partnum,b.tabname,c.tabname,b.dbsname,a.flags,a.nrows,d.seqscans
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
		log4s "不存在$tableunl，无法生成顺扫报告"
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
		log4s info "报告无记录，生成报告头部"
		xhtml "<html><head><title>顺序扫描记录</title></head><body>" 
		xhtml "<table border="1">"
		xhtml "<tr>"
		xhtml "<th>时间</th><th>表名</th><th>partnum</th><th>行数</th><th>顺序扫描次数</th>"
		xhtml "</tr>"
	else
		log4s info "报告已经存在记录，取消报告尾部"
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
				echo "$dSt 表名：$tabname ,partnum：$partnum ,行数：$nrows ,alarm1 table seq is too large" >> $dodir/seqscan.log
				sendalarm "$dSt 表名：$tabname ,partnum：$partnum ,行数：$nrows ,alarm1 table seq is too large"
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
	log4s "开始删除中间文件"
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
	log4s "调试模式，不删除中间文件"
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
			log4s info "当前循环 $dH 已经运行一小时，运行结束"
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
			log4s info "当前循环，为手动循环 $dH 已经运行 $startint 分钟，运行结束，后续交给定时cron执行"
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