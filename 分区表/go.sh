#!/bin/sh
pdir=`pwd`
doDIR=/home/informix/frag
tag=`date "+%N"`
log=$doDIR/shlog.log
testflag=0
#先loadsql

log4s()
{
	echo "$1" >> $log
}

insertlog()
{
	echo "$1" >> $doDIR/insertlog.log
}
panduan()
{
	touch $doDIR/testtable.${tag};
	dbaccess $1<<EOF
	unload to $doDIR/testtable.${tag}
	select b.partition,b.exprtext,b.dbspace from systables a,sysfragments b
	where b.fragtype='T'
	and b.tabid=a.tabid
	and a.tabname='$2'
EOF
	testflag=`wc -l $doDIR/testtable.${tag}|awk '{print $1}'`
	if [ X$testflag = X0 ]
	then
		echo "要操作的表在数据库不存在"
		exit 1;
	fi
	rm -rf $doDIR/testtable.${tag}
}
NuOrSt()
{
if [ -n "$(echo $1| sed -n "/^[0-9]\+$/p")" ];then 
  echo "number" 
else 
  echo "string" 
fi 
}
intotml_basic() #dbname=$1,table_name=$2,column_fragment=$3,time_granularity=$4,dbs_name=$5,retention_days=$6
{
	
	dbaccess $1<<EOF
	insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days) 
	values('$2','$3',$4,'$5',$6);
EOF
	log4s "dbaccess $1"
	log4s "insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days) values('$2','$3',$4,'$5',$6);"
	insertlog "insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days) values('$2','$3',$4,'$5',$6);"
}
intofrag_basic()	#dbname=$1,table_name=$2
{
	log4s "dbaccess $1"
	log4s "unload to $doDIR/intofrag.${tag}"
	log4s "select b.partition,b.exprtext,b.dbspace from systables a,sysfragments b"
	log4s "where b.fragtype='T'"
	log4s "and b.tabid=a.tabid"
	log4s "and a.tabname='$2'"
	
	dbaccess $1<<EOF
	unload to $doDIR/intofrag.${tag}
	select b.partition,b.exprtext,b.dbspace from systables a,sysfragments b
	where b.fragtype='T'
	and b.tabid=a.tabid
	and a.tabname='$2'
EOF
	sed -i '/^rmd.*/d' $doDIR/intofrag.${tag} 
	log4s "下面是导出数据"
	cat $doDIR/intofrag.${tag} >>$log
	while read hang
	do
	partitionname=`echo $hang|awk -F'|' '{print $1}'`
	time1=`echo $hang|awk -F'|' '{print $2}'|awk -F"'" '{print $2}'`
	time2=`echo $hang|awk -F'|' '{print $2}'|awk -F"'" '{print $4}'`
	log4s "$partitionname"
	log4s "$time1"
	log4s "$time2"
	if [ $time1 -le $time2 ]
	then
		starttime=$time1
		endtime=$time2
	else
		starttime=$time2
		endtime=$time1
	fi
	log4s "starttime=$starttime;endtime=$endtime"
	dbaccess $1<<EOF
	insert into fragtabinfo values(current year to second,'$2','$partitionname','$starttime','$endtime');
EOF
	log4s "dbaccess $1"
	log4s "insert into fragtabinfo values(current year to second,'$2','$partitionname','$starttime','$endtime');"
	insertlog "insert into fragtabinfo values(current year to second,'$2','$partitionname','$starttime','$endtime');"
	done < $doDIR/intofrag.${tag}


}
trsql()
{
cat <<EOF >createmain.sql
create table TLM_table
(
table_name varchar(30) not null,
column_fragment varchar(30),
time_granularity int,
prefix_fragment varchar(10),
dbs_name varchar(30),
retention_num int default -1,
retention_days int default -1,
bak_tabname varchar(30) default 'none',
last_date datetime year to second,
FAILURES int default 0,
primary key (table_name)
);

create table  tlm_errlog
  (
    procname varchar(30),
    tabname varchar(30),
    proc_ext datetime year to second,
    sql_err integer,
    isam_err integer,
    err_txt varchar(200),
    count_exec integer
  ) ;
  
create table fragtabinfo
 (
  optime datetime year to second,
  tabname varchar(50),
  partition varchar(50),
  begintime varchar(20),
  endtime varchar(20)
 );
 create unique index tabpar on fragtabinfo(tabname,partition);
EOF
}

biao()
{
peizhiqueren=0
while [[ $peizhiqueren != [Yy] ]]
do
	tag=`date "+%N"`
	read -p "请输入要操作的库名："				dbname
	read -p "请输入要操作的表名："				table_name
	read -p "请输入分区列："							column_fragment
	read -p "请输入时间粒度，单位小时："	time_granularity
	read -p "请输入表存放的dbspace："			dbs_name
	read -p "请输入数据保留天数："				retention_days
	
	
	echo -e "要操作的库名为：  $dbname"
	echo -e "要操作的表名：    $table_name"
	echo -e "分区列：          $column_fragment"
	echo -e "时间粒度：        $time_granularity"
	echo -e "表存放的dbspace： $dbs_name"
	echo -e "数据保留天数：    $retention_days"
	
	read -p "是否确认上述信息，请确保输入正确，否则后果自负[Y/y]：" peizhiqueren
	
	if [ X$dbname = X ] || [ X$table_name = X ] || [ X$column_fragment = X ] || [ X$time_granularity = X ] || [ X$dbs_name = X ] || [ X$retention_days = X ]
	then
		echo "参数为空，请重新输入"
		peizhiqueren=n
		exit 1;
	fi
	ptime_g=`NuOrSt $time_granularity`
	pretention=`NuOrSt $retention_days`
	if [ X$ptime_g = Xstring ]
	then
		echo "时间粒度值为$time_granularity，需要输入数字"
		exit 1;
	fi
	if [ X$pretention = Xstring ]
	then
		echo "保留天数值为$retention_days，需要输入数字"
		exit 1;
	fi
	echo -e "要操作的库名为：  $dbname"               >>$log
	echo -e "要操作的表名：    $table_name"           >>$log
	echo -e "分区列：          $column_fragment"      >>$log
	echo -e "时间粒度：        $time_granularity"     >>$log
	echo -e "表存放的dbspace： $dbs_name"             >>$log
	echo -e "数据保留天数：    $retention_days"				>>$log
	
	if [ ! -f $doDIR/createmain.sql ]
	then
		trsql
		dbaccess $dbname createmain.sql
	fi
	aflag=`grep add_par_for_date_ok $log|wc -l|awk '{print $1}'`
	dflag=`grep del_par_for_date_ok $log|wc -l|awk '{print $1}'`
	if [ X$aflag = X0 ]
	then
		dbaccess $dbname add_par_for_date.sql
		echo "add_par_for_date_ok" >> $log
	fi
	if [ X$dflag = X0 ]
	then
		dbaccess $dbname del_par_for_date.sql
		echo "del_par_for_date_ok" >> $log
	fi
	panduan $dbname $table_name $column_fragment $time_granularity $dbs_name $retention_days
	intotml_basic $dbname $table_name $column_fragment $time_granularity $dbs_name $retention_days
	intofrag_basic $dbname $table_name
done
}

main()
{
	wai=`whoami`
	if [ X$wai != Xinformix ]
	then
		echo  "请使用informix账户进行安装"
	exit 1;
	fi
	if [ ! -d $doDIR ]
	then
		mkdir $doDIR
	fi
	if [ ! -f $pdir/add_par_for_date.sh ] || [ ! -f $pdir/del_par_for_date.sh ] || [ ! -f $pdir/add_par_for_date.sql ] || [ ! -f $pdir/del_par_for_date.sql ]
	then
		echo "文件缺少，请检查文件是否有add_par_for_date.sh   add_par_for_date.sql   del_par_for_date.sh    del_par_for_date.sql"
		exit 1;
	fi
	if [ $pdir != $doDIR ]
	then
		cp go.sh                $doDIR/
		cp add_par_for_date.sh  $doDIR/
		cp add_par_for_date.sql $doDIR/
		cp del_par_for_date.sh  $doDIR/
		cp del_par_for_date.sql $doDIR/
	fi
	chmod o+rwx $doDIR/*
	
	
	quittag=y
	while [[ $quittag = [Yy] ]]
	do
		biao;
		read -p "是否还新建分区表[y/n]：" quittag
	done
	echo "执行完成，请将add_par_for_date.sh和del_par_for_date.sh配到crontab中"
}

main;