#!/bin/sh
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


PROGRAM=$DIR/seqscan.sh
CRONTAB_CMD="22 * * * * . ./.bash_profile;sh $DIR/seqscan.sh > $DIR/cron.log 2>&1 &"
PROGRAMnum=`crontab -l|grep "$PROGRAM"|wc -l|awk '{print $1}'`
if [ X$PROGRAMnum = X0 ]
then
	crontab -l>$DIR/cron.temp
	echo "$CRONTAB_CMD" >> $DIR/cron.temp
	cat $DIR/cron.temp|crontab
fi

if [ ! -d /home/gealarm/genalarm/idsbin ]
then
	mkdir /home/gealarm/genalarm/idsbin
fi
log4s()
{
	echo "$1" >> $log
	echo "$1"
}

xhtml()
{
	echo $1 >> $baogao
}

Table_Info()
{

	dbaccess sysmaster <<EOF
	unload to $DIR/table.$dS.temp
	select a.lockid,a.partnum,b.tabname,c.tabname,b.dbsname,a.flags,a.nrows,d.seqscans
	from sysmaster:sysptnhdr a, sysmaster:systabnames b,sysmaster:systabnames c
	--可以添加sysptprof表等
	,sysmaster:sysptprof d
	where a.partnum=b.partnum
	and a.lockid=c.partnum and d.seqscans>0
	--from中出现两次systabnames，是为了分别提供partnum和lockid的tabname，确定索引和表的关系。
	and a.flags not in ('2310','2054','3334','3078','2081')
	--指定数据库
	--and b.dbsname='min'
	--业务主控：
	and a.partnum=d.partnum
	group by a.lockid,a.partnum,b.tabname,c.tabname,b.dbsname,a.nrows,d.seqscans,a.flags
	order by a.partnum
EOF

	cat ${DIR}/table.$dS.temp > ${DIR}/table.new
	rm ${DIR}/table.$dS.temp

	if [ ! -f ${DIR}/table.old ]
	then
		mv ${DIR}/table.new ${DIR}/table.old
	else

		python ${DIR}/huanbi.py ${DIR}/table.old ${DIR}/table.new ${DIR}/table.part1.unl 7 2

		mv ${DIR}/table.new ${DIR}/table.old

		cat ${DIR}/table.part1.unl | sort -r -t "|" -k 8 > ${DIR}/table.$dS.unl

		rm ${DIR}/table.part1.unl
	fi
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
	done < ${DIR}/table.${dS}.unl
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
