#!/bin/sh
pdir=`pwd`
doDIR=/home/informix/frag
tag=`date "+%N"`
log=$doDIR/shlog.log
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
dH=`date +"%Y%m%d%H"`
dHonly=`date +"%H"`
dMonly=`date +"%M"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dSn=`date +"%Y-%m-%d %H:%M:%S"`
dMonly=`date +"%M"`
testflag=0
#��loadsql


log4s()
{
	#��һ���ǵȼ����ڶ���������
	echo "$dS $1 $2" >> $log
}
if [ $dH -ge 8 ] || [ $dH -le 20 ]
then 
	echo "��ǰʱ��Ϊ���죬������ִ�нű�"
	log4s "��ǰʱ��Ϊ���죬������ִ�нű�"
	exit 1;
fi
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
		echo "Ҫ�����ı������ݿⲻ����"
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
intotml_basic() #dbname=$1,table_name=$2,column_fragment=$3,time_granularity=$4,dbs_name=$5,retention_days=$6,oldtable_retention_days=$7
{
	if [ X$7 = X0 ]
	then
	dbaccess $1<<EOF
	insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days) 
	values("$2","$3",$4,"$5",$6);
EOF
	log4s "dbaccess $1"
	log4s "insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days) values('$2','$3',$4,'$5',$6);"
	insertlog "insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days) values('$2','$3',$4,'$5',$6);"
	else
	dbaccess $1<<EOF
	insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days,bak_tabname,bak_retention_days) 
	values("$2","$3",$4,"$5",$6,"${2}_old",$7);
EOF
	log4s "dbaccess $1"
	log4s "insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days,bak_tabname,bak_retention_days) values('$2','$3',$4,'$5',$6,'${2}_old',$7);"
	insertlog "insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,retention_days,bak_tabname,bak_retention_days) values('$2','$3',$4,'$5',$6,'${2}_old',$7);"
	fi
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
	log4s "�����ǵ�������"
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
create table tlm_table 
  (
    table_name varchar(30) not null ,
    column_fragment varchar(30),
    time_granularity integer,
    prefix_fragment varchar(10),
    dbs_name varchar(30) default 'userdbs',
    retention_num integer 
        default -1,
    retention_days integer 
        default -1,
    bak_tabname varchar(30) 
        default 'none',
    last_date datetime year to second,
    failures integer 
        default 0,
	bak_retention_num integer default -1,
	bak_retention_days integer default -1,
    primary key (table_name) 
  );
create table tlm_errlog 
  (
    procname varchar(30),
    tabname varchar(30),
    proc_ext datetime year to second,
    sql_err integer,
    isam_err integer,
    err_txt varchar(200),
    count_exec integer
  );
  

  
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
	time_granularityqueren=N
	retention_daysqueren=N
	oldtable_retention_daysqueren=N
	dbname=''
	table_name=''
	column_fragment=''
	time_granularity=''
	dbs_name=''
	retention_days=''
	oldtable_retention_days=''
	tag=`date "+%N"`
	while [[ X$dbname = X ]]
	do
	read -p "������Ҫ�����Ŀ���                     ��"				dbname
	done
	while [[ X$table_name = X ]]
	do
	read -p "������Ҫ�����ı���                     ��"				table_name
	done
	while [[ X$column_fragment = X ]]
	do
	read -p "�����������                           ��"				column_fragment
	done
	while [[ $time_granularityqueren != [Yy] ]]
	do
		read -p "������ʱ�����ȣ���λСʱ               ��"				time_granularity
		ptime_g=`NuOrSt $time_granularity`
		if [ X$ptime_g = Xstring ]
		then
			echo "ʱ������ֵΪ$time_granularity����Ҫ�������֣�����������"
			time_granularityqueren=N
		else
			if [ $time_granularity -lt 0 ]
			then
				echo "ʱ������ֵ����С��0������������"
				time_granularityqueren=N
			else
				time_granularityqueren=y
			fi
		fi
	done
	while [[ X$dbs_name = X ]]
	do
	read -p "��������ŵ�dbspace                  ��"				dbs_name
	done
	while [[ $retention_daysqueren != [Yy] ]]
	do
		read -p "���������ݱ�������                     ��"				retention_days
		pretention=`NuOrSt $retention_days`
		if [ X$pretention = Xstring ]
		then
			echo "��������ֵΪ$retention_days����Ҫ�������֣�����������"
			retention_daysqueren=N
		else
			if [ $retention_days -lt 0 ]
			then
				echo "��������ֵ����С��0������������"
				retention_daysqueren=N
			else
				retention_daysqueren=Y
			fi
			
		fi
	done
	while [[ $oldtable_retention_daysqueren != [Yy] ]]
	do
		read -p "�����뱸�ݱ���������Ϊ0����Ҫ���ݣ���"			oldtable_retention_days
		poldtable_retention_days=`NuOrSt $oldtable_retention_days`
		if [ X$poldtable_retention_days = Xstring ]
		then
			echo "���ݱ�������ֵΪ$oldtable_retention_days����Ҫ�������֣�����������"
			oldtable_retention_daysqueren=N
		else
			if [ $oldtable_retention_days -lt 0 ]
			then
				echo "���ݱ�������ֵ����Ϊ��������������"
				oldtable_retention_daysqueren=N
			else
				oldtable_retention_daysqueren=Y
			fi
			
		fi
	done
	
	echo -e "Ҫ�����Ŀ���Ϊ��       $dbname"
	echo -e "Ҫ�����ı�����         $table_name"
	echo -e "�����У�               $column_fragment"
	echo -e "ʱ�����ȣ�             $time_granularity"
	echo -e "���ŵ�dbspace��      $dbs_name"
	echo -e "���ݱ���������         $retention_days"
	echo -e "�����뱸�ݱ��������� $oldtable_retention_days"
	
	read -p "�Ƿ�ȷ��������Ϣ����ȷ��������ȷ���������Ը�[Y/y]��" peizhiqueren
	done
	if [ X$dbname = X ] || [ X$table_name = X ] || [ X$column_fragment = X ] || [ X$time_granularity = X ] || [ X$dbs_name = X ] || [ X$retention_days = X ] || [ X$oldtable_retention_days = X ]
	then
		echo "����Ϊ�գ�����������"
		peizhiqueren=n
		exit 1;
	fi

	echo -e "Ҫ�����Ŀ���Ϊ��  $dbname"                        >>$log
	echo -e "Ҫ�����ı�����    $table_name"                    >>$log
	echo -e "�����У�          $column_fragment"               >>$log
	echo -e "ʱ�����ȣ�        $time_granularity"              >>$log
	echo -e "���ŵ�dbspace�� $dbs_name"                      >>$log
	echo -e "���ݱ���������    $retention_days"				         >>$log
	echo -e "�����뱸�ݱ��������� $oldtable_retention_days"  >>$log
	if [ ! -f $doDIR/createmain.sql ]
	then
		trsql
		dbaccess $dbname createmain.sql
	else
		rm $doDIR/createmain.sql
		trsql
		dbaccess $dbname createmain.sql
	fi
	aflag=`grep add_par_for_date_ok $log|wc -l|awk '{print $1}'`
	dflag=`grep del_par_for_date_ok $log|wc -l|awk '{print $1}'`
	if [ X$aflag = X0 ]
	then
		dbaccess $dbname $doDIR/add_par_for_date.sql
		echo "add_par_for_date ok" >> $log
	fi
	if [ X$dflag = X0 ]
	then
		dbaccess $dbname $doDIR/del_par_for_date.sql
		echo "del_par_for_date ok" >> $log
	fi
	panduan $dbname $table_name $column_fragment $time_granularity $dbs_name $retention_days
	intotml_basic $dbname $table_name $column_fragment $time_granularity $dbs_name $retention_days $oldtable_retention_days
	intofrag_basic $dbname $table_name
	if [ $oldtable_retention_days -gt 0 ]
	then
		intofrag_basic $dbname ${table_name}_old
	fi
}

main()
{
	wai=`whoami`
	if [ X$wai != Xinformix ]
	then
		echo  "��ʹ��informix�˻����а�װ"
	exit 1;
	fi
	if [ ! -d $doDIR ]
	then
		mkdir $doDIR
	fi
	if [ ! -f $pdir/add_par_for_date.sh ] || [ ! -f $pdir/del_par_for_date.sh ] || [ ! -f $pdir/add_par_for_date.sql ] || [ ! -f $pdir/del_par_for_date.sql ]
	then
		echo "�ļ�ȱ�٣������ļ��Ƿ���add_par_for_date.sh   add_par_for_date.sql   del_par_for_date.sh    del_par_for_date.sql"
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
		read -p "�Ƿ��½�������[y/n]��" quittag
	done
	echo "ִ����ɣ��뽫add_par_for_date.sh��del_par_for_date.sh�䵽crontab��"
}

main;