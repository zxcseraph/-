#!/bin/sh
dodir=/home/informix/frag          	#脚本工作目录，所有操作均会在这个目录执行
log=$dodir/root.log                     #操作记录日志
alarmlog=$dodir/alarm.log               #记录所有告警的日志
alarmcode=123                           #告警码
remaindernum=100                          #rmd分区中的数据行数的阀值
fragdaynum=3                            #分片必须包含从今天起向后数该值的天数
testflag=1                              #测试标志位，现网使用时该值必须为0

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
dMonly=`date +"%M"`
hostname=`hostname`
wai=`whoami`
okday=`date -d "+$fragdaynum days" +"%Y%m%d"`

errornum=0
log4s()
{
	#调试时先用这个，后期整合进来log4s
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
	log4s info "创建工作目录"
fi
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

	if [ $testflag = 0 ]
	then
		rm -rf $unload1unl
		rm -rf $unload2unl
		rm -rf $alarmunl
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
	if [ $testflag = 0 ]
	then
		rm -rf $notin1unl
		rm -rf $notin2unl
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
		log4s error "数据库 sysmaster 中，获取database信息数据失败"
		exit 1;
	fi
	databasesnum=`wc -l $databasesunl|awk '{print $1}'`
	if [ $databasesnum = 0 ]
	then
		log4s error "系统中没有该库，请核查后再重新执行"
		exit 1
	else
		log4s info "该database存在，开始进行初步核查"
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
	log4s error "请输入正确的参数"
	exit 1;
fi

pdatabases $1;
getrmd $1;
notintable $1;
getmaxfrag $1;
if [ X$2 = X ]
then
	log4s info "当前为定时模式"
	if [ $errornum != 0 ]
	then
		log4s error "数据库 $1 中，存 $errornum 个在错误，所以不进行删除分片操作，具体错误请查看alarm.log"
	else
		log4s info "数据库 $1 中，一切正常，开始删除分片"
		delfrag $1
	fi
fi
if [ X$2 = Xmanual ]
then
	log4s info "当前为手动模式"
	if [ $errornum != 0 ]
	then
		log4s error "数据库 $1 中，存 $errornum 个在错误，具体错误请查看alarm.log，但由于是手动模式，将继续进行操作"
		delfrag $1
	else
		log4s info "数据库 $1 中，一切正常，开始删除分片"
		delfrag $1
	fi
fi