#!/bin/sh
set -x
DIR=/home/gealarm/genalarm/idsbin
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

#!/bin/sh


#PROGRAM=$DIR/seqscan.sqlite3.sh
#CRONTAB_CMD="22 * * * * . ./.bash_profile;sh $PROGRAM > $DIR/cron.log 2>&1 &"
##PROGRAMnum=`crontab -l|grep "$PROGRAM"|wc -l|awk '{print $1}'`
#if [ X$PROGRAMnum = X0 ]
#then
#	crontab -l>$DIR/cron.temp
#	echo "$CRONTAB_CMD" >> $DIR/cron.temp
#	cat $DIR/cron.temp|crontab
#fi

if [ ! -d /home/gealarm/genalarm/idsbin ]
then
	mkdir /home/gealarm/genalarm/idsbin
fi
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
x=1
while [ $x -le 8 ]
do 	
	echo "$x 开始  `date +"%H%M%S.%N"`"
	cp table.$x.unl table.old
	let x=x+1
	cp table.$x.unl table.new
	gosqlite3 "create table seqfx(timenow text,lockid  integer,partnum integer,tabname1 text,tabname2 text,dbsname text,flags integer,nrows integer,seqscans integer);"
	echo "$x 建表结束  `date +"%H%M%S.%N"`"
	gosqlite3 ".import ${DIR}/table.old seqfx"
	echo "$x 导入旧表结束  `date +"%H%M%S.%N"`"
	gosqlite3 ".import ${DIR}/table.new seqfx"
	echo "$x 导入新表结束  `date +"%H%M%S.%N"`"
	gosqlite3 "create index idx_${x} on seqfx(partnum);"
	echo "$x 索引建立结束  `date +"%H%M%S.%N"`"
	gosqlite3 "select b.timenow,b.lockid,b.partnum,b.tabname1,b.tabname2,b.dbsname,b.flags,b.nrows,b.seqscans-a.seqscans from seqfx a,seqfx b where a.partnum=b.partnum and a.timenow<b.timenow;">${DIR}/table.${x}.temp
	echo "$x 环比结束  `date +"%H%M%S.%N"`"
	mv ${DIR}/fx.temp.db ${DIR}/fx.${x}.db
	rm -rf ${DIR}/fx.temp.db
	cp ${DIR}/table.old ${DIR}/table.${x}.old
	cat ${DIR}/table.${x}.temp|sort -r -t "|" -k 8 > ${DIR}/table.${x}.unl
	echo "$x 排序结束  `date +"%H%M%S.%N"`"

done
}

gohtml()
{
	>$baogao
	xhtml "<html><head><title>顺序扫描记录</title></head><body>" 
	xhtml "<table border="1">"
	xhtml "<tr>"
	xhtml "<th>表名</th><th>partnum</th><th>行数</th><th>顺序扫描次数</th>"
	xhtml "</tr>"
	while read hang
	do
		tabname=`echo $hang|awk -F'|' '{print $4}'`
		partnum=`echo $hang|awk -F'|' '{print $2}'`
		nrows=`echo $hang|awk -F'|' '{print $7}'`
		seq=`echo $hang|awk -F'|' '{print $8}'|awk -F'.' '{print $1}'`
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
				echo "table seq is too large" >> /home/gealarm/genalarm/idsbin/seqscan.log
			fi
		else
			break;
		fi
	done < ${DIR}/table.${x}.unl
	xhtml "</table>"
	xhtml "</body></html>"
}

Table_Info
if [ -f ${DIR}/table.${dS}.unl ]
then
	gohtml
fi
rm -rf $DIR/table.${d7dayago}*.unl
rm -rf $DIR/seqscan.${d7dayago}*.html
rm -rf $DIR/fx.${d7dayago}*.db