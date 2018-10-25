#!/bin/sh
#2018-05-10 正式版
DIR=/home/gealarm/genalarm/idsbin
log=$DIR/unload.log
TAGLOG=$DIR/taglog.log
XITONGTEMP=`uname`
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
dH=`date +"%Y%m%d%H"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dN=`date +"%H%M%S.%N"`
dMonly=`date +"%M"`
if [ $XITONG = LINUX ]
then
	d7dayago=`date -d "7 day ago" +"%Y%m%d"`
fi

baogao=$DIR/seqscan.${dH}.html
XN=1			#如果为0则不启动性能统计
#SendAlarmFlag=0			#设置是否吐告警
AlarmLog=$DIR/alarm.log

export LC_TIME="POSIX"

if [ ! -d $DIR ]
then
	mkdir $DIR
fi


PROGRAM=$DIR/seqscan.sqlite3.sh
if [ $XITONG = LINUX ]
then
CRONTAB_CMD="22 * * * * . ./.bash_profile;sh $PROGRAM >> $DIR/cron.log 2>&1 &"
fi
if [ $XITONG = HP-UX ]
then
CRONTAB_CMD="22 * * * * . ./.profile;sh $PROGRAM >> $DIR/cron.log 2>&1 &"
fi
PROGRAMnum=`crontab -l|grep "$PROGRAM"|wc -l|awk '{print $1}'`
if [ X$PROGRAMnum = X0 ]
then
	crontab -l>$DIR/cron.temp
	echo "$CRONTAB_CMD" >> $DIR/cron.temp
	cat $DIR/cron.temp|crontab
fi


log4s()
{
	echo "$1" >> $log
	echo "$1"
}
sendalarm()
{
	echo "$dS   $1" >> $AlarmLog
}
gosqlite3()
{
	echo "$1"|sqlite3 ${DIR}/fx.temp.db
}
xhtml()
{
	echo $1 >> $baogao
}

Table_Info()
{

	dbaccess sysmaster <<EOF
	unload to $DIR/table.$dS.temp
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
	sed 's/.$//' $DIR/table.$dS.temp > table.$dS.temp.a
	mv table.$dS.temp.a ${DIR}/table.new


	if [ ! -f ${DIR}/table.old ]
	then
		mv ${DIR}/table.new ${DIR}/table.old
	else
		gosqlite3 "create table seqfx(timenow text,lockid  integer,partnum integer,tabname1 text,tabname2 text,dbsname text,flags integer,nrows integer,seqscans integer);"
		gosqlite3 ".import ${DIR}/table.old seqfx"
		gosqlite3 ".import ${DIR}/table.new seqfx"
		gosqlite3 "create index idx_seqfx on seqfx(partnum);"
		gosqlite3 "select b.timenow,b.lockid,b.partnum,b.tabname1,b.tabname2,b.dbsname,b.flags,b.nrows,b.seqscans-a.seqscans from seqfx a,seqfx b where a.partnum=b.partnum and a.timenow<b.timenow;">${DIR}/table.${dS}.temp
		mv ${DIR}/fx.temp.db ${DIR}/fx.${dS}.db
		#rm -rf ${DIR}/fx.temp.db
		mv ${DIR}/table.new ${DIR}/table.old
		cp ${DIR}/table.old ${DIR}/table.${dS}.old
		cat ${DIR}/table.${dS}.temp|sort -r -t "|" -k 9 > ${DIR}/table.${dS}.unl
		#rm ${DIR}/table.${dS}.temp
	fi
}

gohtml()
{
	if [ ! -f $DIR/seqscan.log ]
	then
		touch $DIR/seqscan.log
		chmod 777 $DIR/seqscan.log
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
				echo "$dS $tabname $partnum table seq is too large" >> $DIR/seqscan.log
				sendalarm "$dS $tabname $partnum table seq is too large"
			fi
		else
			break;
		fi
	done < ${DIR}/table.${dS}.unl
	xhtml "</table>"
	xhtml "</body></html>"
}

Table_Info
if [ -f ${DIR}/table.${dS}.unl ]
then
	gohtml
fi
if [ $XITONG = LINUX ]
then
rm -rf $DIR/table.${d7dayago}*.unl
rm -rf $DIR/seqscan.${d7dayago}*.html
rm -rf $DIR/fx.${d7dayago}*.db
fi