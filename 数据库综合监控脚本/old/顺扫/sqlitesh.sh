#!/bin/sh
DIR=/home/informix
log=$DIR/unload.log
TAGLOG=$DIR/taglog.log
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
dH=`date +"%Y%m%d%H"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dN=`date +"%H%M%S.%N"`
dMonly=`date +"%M"`
d7dayago=`date -d "7 day ago" +"%Y%m%d"`
baogao=$DIR/seqscan.${dH}.html
XN=1			#如果为0则不启动性能统计

export LC_TIME="POSIX"

if [ ! -d $DIR ]
then
	mkdir $DIR
fi


#PROGRAM=$DIR/seqscan.sqlite3.sh
#CRONTAB_CMD="22 * * * * . ./.bash_profile;sh $PROGRAM > $DIR/cron.log 2>&1 &"
##PROGRAMnum=`crontab -l|grep "$PROGRAM"|wc -l|awk '{print $1}'`
#if [ X$PROGRAMnum = X0 ]
#then
#	crontab -l>$DIR/cron.temp
#	echo "$CRONTAB_CMD" >> $DIR/cron.temp
#	cat $DIR/cron.temp|crontab
#fi


log4s()
{
	echo "$1" >> $log
	echo "$1"
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
	and a.partnum=d.partnum
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
		rm -rf ${DIR}/fx.temp.db
		cp ${DIR}/table.old ${DIR}/table.${dS}.old
		cat ${DIR}/table.${dS}.temp|sort -r -t "|" -k 8 > ${DIR}/table.${dS}.unl
		rm ${DIR}/table.${dS}.temp
	fi
}


Table_Info
