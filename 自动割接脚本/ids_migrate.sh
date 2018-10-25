#!/bin/sh

if [ $# -ne 3 ]; then
	echo "Usage: $0 dbname servername {load|unload|getinfo}"
	exit 1
fi
DBNAME=$1
SERVERNAME=$2
LOADFLAG=$3
currentdir=`pwd`
UNLOADLOGFILE=$currentdir/unload_data.log
LOADLOGFILE=$currentdir/load_data.log
DbaccessLog=$currentdir/dbaccess.log
RECORDNUM=100
DATADIR=$currentdir/$DBNAME
stty erase ^H;
log4s()
{
	dst=`date +"%Y-%m-%d %H:%M:%S"`
	echo "$1"
	if [ $LOADFLAG = load ]
	then
		echo "$dst $1" >> $LOADLOGFILE
	elif [ $LOADFLAG = unload ]
	then
		echo "$dst $1" >> $UNLOADLOGFILE
	else
		echo "$dst $1" >> $currentdir/root.log
	fi
	
}
unloadschema()
{
	log4s "进入导出表结构模块" unload
	if [ ! -d $DATADIR ]
	then
		mkdir $DATADIR
	fi
	#测试接入库是否成功
	echo "测试数据库是否可以接入" 1>>$DbaccessLog 2>&1
	echo "select distinct(1) from systables"|dbaccess $DBNAME@$SERVERNAME 1>>$DbaccessLog 2>&1
	if [ $? != 0 ]
	then
		log4s "ERROR 要导出的数据库不存在" unload
		exit 1;
	fi
	cd $DATADIR;
	echo "导出数据库所有结构" 1>>$DbaccessLog 2>&1
	dbschema -d $DBNAME -ss allss.sql 1>>$DbaccessLog 2>&1
	if [ $? != 0 ]
	then
		log4s "ERROR 表结构导出异常" unload
		exit 1;
	else
		log4s "表结构导出成功" unload
	fi
#	starttablenum=`awk '/create table/{print NR}' allss.sql|head -1`
	#处理^M
#	sed "s/\r/\n/g" allss.sql >alltemp.sql
#	mv alltemp.sql allss.sql
#	#机制是，获取第一个存储过程也就是create procedure的行号，在获取这个行号之前的最后一个create table号，再获取create table后的第一个分号，而这个分号加上后跟着的revoke就是所有建表语句
#	#获取create procedure的行号
#	firstcreateprocedure=`awk '{IGNORECASE=1} /create procedure/{print NR}' allss.sql|head -1`
#	log4s "获取第一个create procedure的行号为 $firstcreateprocedure"
#	#第一个create procedure前的最后一个create table的行号
#	endcreatenum=`awk -v t="$firstcreateprocedure" '{IGNORECASE=1} /create table/{if(NR<t){print NR}}' allss.sql|tail -1`
#	#上一个获取的create table的结束行号
#	log4s "获取最后一个create table的行号为 $endcreatenum" unload
#	#获取最后一个create table的结束分号的行号
#	endcreateendnum=`awk -v t="$endcreatenum" '{if(substr($0,length,1)==";" && NR>=t) { print NR}}' allss.sql |head -1`
#	log4s "获取create table后第一个分号的行号为 $endcreateendnum" unload
#	#最后一个create table之后跟着的第一个非revoke行号
#	endtablerevokenum=`awk -v t="$endcreateendnum" '{if($1!="revoke" && NR>t && $0!="") {print NR}}' allss.sql|head -1;`
#	log4s "获取的第一个非revoke行号为 $endtablerevokenum " unload 
#	#获取表结构相关最后一个行号，懒得命名变量了，直接用最后一个revoke的值减一
#	let endtablerevokenum=endtablerevokenum-1
#	log4s "获取的表结构相关最后一行行号为 $endtablerevokenum" unload 
#	#获得整个文件的行数
#	numsql=`awk '{print NR}' allss.sql|tail -1`
#	log4s "整个库结构的行数为 $numsql"
#	#获得创建table的所有语句
#	head -$endtablerevokenum allss.sql > ${DBNAME}_table.sql
#	#获得除了建表以外的所有语句
#	awk -v t="$endtablerevokenum" '{if(NR>t) { print $0}}' allss.sql >${DBNAME}_other.sql

	#之前的机制不行，如果没有存储过程就崩了，更换机制，获取第一个create，然后获取大于这个行号的第一个grant。这样区分
	#获取第一个create table，且要求这个create table是从第一个字符开始，防止有某些语句使用该字符串
	firstcreatetablenum=`awk '{IGNORECASE=1} /^create table/{print NR}' allss.sql|head -1`
	#获取第一个create table后的第一个grant，并且要求是开头不能是空格，防止表中字段名为grant
	firstgrantnum=`awk -v t="$firstcreatetablenum" '{if(NR>t && substr($0,1,5)=="grant"){print NR}}' allss.sql|head -1`
	#他的上一行的行数得到
	let endcreatetablenum=firstgrantnum-1
	#获取表结构
	head -$endcreatetablenum allss.sql > ${DBNAME}_table.sql
	log4s "单纯表结构记录在文件 ${DBNAME}_table.sql 中" unload
	#获取剩余语句
	awk -v t="$endcreatetablenum" '{if(NR>t) { print $0}}' allss.sql >${DBNAME}_other.sql
	log4s "表结构之外的语句保存在文件 ${DBNAME}_other.sql 中" unload
	#校验表结构分割
	cat ${DBNAME}_table.sql > bllss.sql
	cat ${DBNAME}_other.sql >> bllss.sql
	diff allss.sql bllss.sql 1>>/dev/null 2>&1
	if [ $? = 0 ]
	then
		log4s "表结构分割后校验成功，开始进入导出数据模块" unload
	else
		log4s "ERROR 表结构分割校验异常，请核查" unload
	fi
	unloaddata;
}
loadschema()
{
	#测试接入库是否成功
	echo "测试数据库是否可以接入" 1>>$DbaccessLog 2>&1
	echo "select distinct(1) from systables"|dbaccess $DBNAME@$SERVERNAME 1>>$DbaccessLog 2>&1
	if [ $? != 0 ]
	then
		log4s "要导入的数据库不存在" load
		exit 1;
	fi
	if [ ! -d $DATADIR ]
	then
		log4s "ERROR $DATADIR不存在，请检查$DBNAME是否正确" load
		exit 1;
	fi
	cd $DATADIR;
	if [ ! -f ${DBNAME}_table.sql ] || [ ! -f ${DBNAME}_other.sql ]
	then
		log4s "ERROR 要导入的表结构等信息不存在，请检查${dbname}是否正确" load
		exit 1;
	fi
	dbaccess $DBNAME@$SERVERNAME ${DBNAME}_table.sql 1>create_table.log 2>&1
	if [ $? = 0 ]
	then
		log4s "创建表结构成功，开始导入数据" load
		loaddata;
		if [ $? = 0 ]
		then
			log4s "导入数据成功，开始导入视图、存储过程、创建索引等工作。" load
			dbaccess $DBNAME@$SERVERNAME ${DBNAME}_other.sql 1>create_other.log 2>&1
			if [ $? = 0 ]
			then
				log4s "导入视图、存储过程、创建索引等工作操作成功" load
				#校验表结构
				log4s "开始校验表结构" load
				echo "导入后校验表结构的导出"  1>>$DbaccessLog 2>&1
				dbschema -d $DBNAME -ss $DATADIR/cllss.sql 1>>$DbaccessLog 2>&1
				diff $DATADIR/allss.sql $DATADIR/cllss.sql > err.sql
				if [ $? = 0 ]
				then
					log4s "表结构校验正常，割接完成" load
				else
					log4s "表结构校验异常，异常请参考原库结构allss.sql，新库结构cllss.sql，差异内容 err.sql"
				fi
			else
				log4s "导入视图、存储过程、创建索引等工作失败，请检查create_other.log" load
			fi
		else
			log4s "导入数据失败，请检查日志$UNLOADLOGFILE" load
			exit 1;
		fi
	else
		log4s "建表失败，请检查${DBNAME}_table.sql执行是否正常，请检查create_table.log" load
		exit 1;
	fi
}
unloaddata()
{
	cludeflag=null
	querencludeflag=null
	cd $DATADIR;
	if [ ! -f  config.txt ]
	then
		log4s "存在config.txt" unload
		while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
		do
			read -p "当前为全量导出模式，不存在要排除的表，也不只导出指定表，是否确认【y|n】" querencludeflag
		done
		if [ X$querencludeflag = Xn ]
		then
			log4s "读取的配置参数与用户要求不符，请运行脚本加getinfo参数，进行指定或排除表的配置。" unload
			exit 0;
		else
			log4s "当前为全量导出模式，不存在要排除的表，也不只导出指定表。" unload
			cludeflag=all
		fi
	else
		cludeflag=`tail -1 config.txt|awk -F'=' '{print $2}'`
		if [ X$cludeflag = Xin ]
		then
			if [ -f in.txt ] && [ -s in.txt ]
			then
				log4s "存在正常的in.txt" unload
				while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
				do
					log4s "当前为导出指定表模式，指定的表如下：" unload
					while read hang 
					do
						log4s "$hang" unload
					done < in.txt
					read -p "是否确认【y|n】" querencludeflag
				done
				if [ X$querencludeflag = Xn ]
				then
					log4s "读取的配置参数与用户要求不符，请运行脚本加getinfo参数，进行指定或排除表的配置。" unload
					exit 0;
				else
					log4s "当前为导出指定表模式。" unload
					cludeflag=in
				fi
			else
				while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
				do
					log4s "当前为导出指定表模式，但是指定表的文件不存在或者为空，请重新运行getinfo参数"
					exit 1;
				done
			fi
		elif [ X$cludeflag = Xex ]
		then
			if [ -f ex.txt ] && [ -s ex.txt ]
			then
				while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
				do
					log4s "当前为排除指定表模式，指定的表如下：" unload
					while read hang 
					do
						log4s "$hang" unload
					done < ex.txt
					read -p "是否确认【y|n】" querencludeflag
				done
				if [ X$querencludeflag = Xn ]
				then
					log4s "读取的配置参数与用户要求不符，请运行脚本加getinfo参数，进行指定或排除表的配置。" unload
					exit 0;
				else
					log4s "当前为排除指定表模式。" unload
					cludeflag=ex
				fi
			else
				while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
				do
					log4s "当前为排除指定表模式，但是指定表的文件不存在或者为空，请重新运行getinfo参数" unload
					exit 1;
				done
			fi
		elif [ X$cludeflag = Xall ]
		then
			while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
			do
				read -p "当前为全量导出模式，不存在要排除的表，也不只导出指定表，是否确认【y|n】" querencludeflag
			done
			if [ X$querencludeflag = Xn ]
			then
				log4s "读取的配置参数与用户要求不符，请运行脚本加getinfo参数，进行指定或排除表的配置。" unload
				exit 0;
			else
				log4s "当前为全量导出模式，不存在要排除的表，也不只导出指定表。" unload
				cludeflag=all
			fi
		else
			while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
			do
				read -p "当前为全量导出模式，不存在要排除的表，也不只导出指定表，是否确认【y|n】" querencludeflag
			done
			if [ X$querencludeflag = Xn ]
			then
				log4s "读取的配置参数与用户要求不符，请运行脚本加getinfo参数，进行指定或排除表的配置。" unload
				exit 0;
			else
				log4s "当前为全量导出模式，不存在要排除的表，也不只导出指定表。" unload
				cludeflag=all
			fi
		fi
	fi
	log4s "开始导出所有表名称到tab.unl" unload
	echo "导出所有表名称" 1>>$DbaccessLog 2>&1
dbaccess $DBNAME@$SERVERNAME <<! 1>>$DbaccessLog 2>&1
unload to $DATADIR/tab.unl delimiter ' ' 
select a.tabname,b.nrows from systables a,sysmaster:sysptnhdr b 
where a.partnum=b.partnum and a.tabid >99
and a.tabtype<>'V'
and b.nrows>0
order by b.nrows 
!
	if [ $? = 0 ]
	then
		log4s "导出数据库中所有非系统表名称完成" unload
	else
		log4s "导出数据库中所有非系统表名称异常，请检查数据库状态是否正常" unload
	fi
	
	#开始根据in或者ex来生成新的tab.unl
	if [ X$cludeflag = Xin ]
	then
		>tab.unl.temp
		while read hang
		do
			unloadall="$hang"
			unloadtabname=`echo "$hang"|awk '{print $1}'`
			while read A
			do
				intabname=`echo "$A"|awk -F'|' '{print $1}'`
				if [ X$intabname = X$unloadtabname ] && [ X$unloadtabname != X ]
				then
					echo "$unloadall" >> tab.unl.temp
				fi
			done < in.txt
		done < tab.unl
		mv tab.unl.temp tab.unl
		log4s "根据所有非系统表名称，生成指定模式的tab.unl" unload
		log4s "指定模式的tab.unl生成完成" unload
	elif [ X$cludeflag = Xex ]
	then
		>tab.unl.temp
		while read hang
		do
			awk -v extab="$hang" '{if(extab!=$1){print $0}}' tab.unl >tab.unl.temp
			mv tab.unl.temp tab.unl
		done < ex.txt
		log4s "排除模式的tab.unl生成完成" unload
	else
		log4s "全量模式不修改tab.unl" unload
	fi
	log4s "------开始导出表数据------" unload
	while read A B
	do
	echo "导出表 $A 的数据" 1>>$DbaccessLog 2>&1
dbaccess $DBNAME@$SERVERNAME <<! 1>>$DbaccessLog 2>&1
unload to $DATADIR/$A.unl
select * from $A;
!
	if (test $? != 0)
	then 
	   log4s "ERROR 表 $A 导出失败，请检查该表" unload
	else
	   log4s "表 $A 导出成功!" unload
	fi
	done < $DATADIR/tab.unl
	log4s "------ 导出表数据结束 ------" unload
}

loaddata()
{
	RECORDNUMqueren=all
	while [[ X$RECORDNUMqueren != Xy && X$RECORDNUMqueren != Xn ]]
	do
		log4s "当前表大于 $RECORDNUM 行的将会使用HPL导入，如果逻辑日志过小或者该分界线值过大，可能导致长事物，另外HPL需要单库"
		read -p "是否确认【y|n】" RECORDNUMqueren
	done
	if [ X$RECORDNUMqueren = Xy ]
	then
		log4s "用户认可 $RECORDNUM 的分界线值" load
	elif [ X$RECORDNUMqueren = Xy ]
	then
		log4s "用户不认可 $RECORDNUM 的分界线值，请退出脚本，并修改RECORDNUM参数，建议设置为10W" load
		exit 1;
	fi
	log4s "------开始导入数据------" load
	while read A B
	do
	if [ $B -le $RECORDNUM ]
	then
	echo "导入表 $A 的数据" 1>>$DbaccessLog 2>&1
dbaccess $DBNAME@$SERVERNAME <<! 1>>$DbaccessLog 2>&1
load from $DATADIR/$A.unl
insert into $A;
!
		if (test $? != 0)
		then 
		   log4s "ERROR 表 $A 导入失败，请检查该表" load
		else
		   log4s "表 $A 导入成功" load
		fi
	else
		onpladm create job job$A -d $DATADIR/$A.unl -D $DBNAME -S $SERVERNAME -t $A -fl >>$LOADLOGFILE
		if [ $? = 0 ]
		then
			log4s "表 $A hpl创建job成功" load
		else
			log4s "表 $A hpl创建job成功" load
		fi
		log4s "表 $A hpl开始执行job" load
		onpladm run job job$A -S $SERVERNAME -fl >>$LOADLOGFILE
		if [ $? = 0 ]
		then
			log4s "表 $A hpl执行job成功" load
		else
			log4s "表 $A hpl执行job成功" load
		fi
		onpladm delete job job$A -S $SERVERNAME -fl -R >>$LOADLOGFILE
		if [ $? = 0 ]
		then
			log4s "表 $A hpl删除job成功" load
		else
			log4s "表 $A hpl删除job成功" load
		fi
	fi
	done < $DATADIR/tab.unl
	log4s "------ 导入数据结束 ------" LOADLOGFILE
	#dbaccess $DBNAME@$SERVERNAME <<!
	#update statistics medium;
	#!
	INFORMIXSERVER=$SERVERNAME
	log4s "导入成功，开始零备" load
	echo ` ` | ontape -t STDIO -s -L 0 > /dev/null 
	if [ $? = 0 ]
	then
		log4s "零备完成，导入操作执行完成" load
	else
		log4s "零备异常，请检查数据库" load
	fi
}
transformByte()
{
	num=$1
	trsnum=0
	trsnumrem=0
	if [ X$num = X ]
	then
		echo "0"
		return 0;
	fi
	if [ $num -gt 1073741824 ]
	then
		trsnum=`awk -v num="$num" 'BEGIN{printf "%.2f\n",num/1073741824}'`
		echo "${trsnum}G"
	elif [ $num -gt 1048576 ]
	then
		trsnum=`awk -v num="$num" 'BEGIN{printf "%.2f\n",num/1048576}'`
		echo "${trsnum}M"
	elif [ $num -gt 1024 ]
	then
		trsnum=`awk -v num="$num" 'BEGIN{printf "%.2f\n",num/1024}'`
		echo "${trsnum}K"
	else
		trsnum=$num
		echo "${trsnum}B"
	fi
}
Ppaichuhang()
{
	str="$1"
	if [ X"$str" = X ]
	then
		log4s "Ppaichuhang函数操作错误，参数为空"
		exit 1;
	fi
	trsstr1=`echo "$str"|sed 's/[0-9]//g'|sed 's/,//g'|awk '{print length($0)}'`
	if [ X$trsstr1 != X0 ]
	then
		log4s "参数存在数字和逗号之外的其他字符"
		echo "PpaichuhangERROR1"
		return 1;
	fi
	echo "OK"
}
getinfo()
{
	if [ -e $DATADIR ]
	then
		mv  $DATADIR ${DATADIR}.bak.`date +"%Y%m%d%H%M%S"`
		mkdir $DATADIR
	else
		mkdir $DATADIR
	fi
	cd $DATADIR;
	>in.txt
	>ex.txt
	>config.txt
	>paichuhang.txt
	cludeflag=XXX;
	log4s "进入预处理阶段，该阶段会选在导出表数据的时候排除或者指定某个表的数据。但是表结构仍会全量导出。"
	while [[ X$cludeflag != Xin && X$cludeflag != Xex && X$cludeflag != Xall ]]
	do
		read -p "请选择导出表的方式，是排除指定表还是只选择指定表【in|ex|all】，in是指定表，ex是排除表，all是导出所有表：" cludeflag
	done
	echo "cludeflag=$cludeflag" > config.txt
	if [ X$cludeflag = Xin ]
	then
		log4s "当前选择的是【导出指定表数据】方式"
		log4s "当前方式会在${DBNAME}下生成一个in.txt，里面是指定的表名，如果需要增加或者删除，可以手动修改，如无需求则不要动。"
		log4s "下面会显示数据量前40的表，可以根据之前选择的模式，选择指定导出的表数据"
		> in.txt
	elif [ X$cludeflag = Xex ]
	then
		log4s "当前选择的是【排除指定表数据】方式"
		log4s "当前方式会在${DBNAME}下生成一个ex.txt，里面是排除的表名，如果需要增加或者删除，可以手动修改，如无需求则不要动。"
		log4s "下面会显示数据量前40的表，可以根据之前选择的模式，选择排除导出的表数据"
		> ex.txt
	else
		log4s "当前选择的是【导出所有表数据】方式"
		log4s "下面会显示数据量前40的表，由于选择的是导出所有表数据，下面显示的表信息只做参考"
	fi
	echo "导出预处理阶段的行数最大的前40行" 1>>$DbaccessLog 2>&1
	echo "unload to gejie.yuchuli.unl select first 40 b.tabname,sum(a.pagesize*a.nptotal)total_byte,sum(a.pagesize*a.npdata)data_byte,sum(a.nrows)nrows from sysmaster:sysptnhdr a, sysmaster:systabnames b where a.partnum=b.partnum and a.nkeys=0 and a.flags not in ('2310','2054','3334','3078','2081') and b.dbsname='$DBNAME' group by b.tabname order by nrows desc"|dbaccess sysmaster@$SERVERNAME 1>>$DbaccessLog 2>&1;
	awk 'BEGIN{FS="|";OFS="|"}  {print NR,$0}' gejie.yuchuli.unl > gejietemp.unl
	mv gejietemp.unl gejie.yuchuli.unl
	while read hang
	do
		hanghao=`echo $hang|awk -F'|' '{print $1}'`
		tabname=`echo $hang|awk -F'|' '{print $2}'`
		total_byte=`echo $hang|awk -F'|' '{print $3}'|awk -F'.' '{print $1}'`
		total_byte=`transformByte $total_byte`
		data_byte=`echo $hang|awk -F'|' '{print $4}'|awk -F'.' '{print $1}'`
		data_byte=`transformByte $data_byte`
		rows=`echo $hang|awk -F'|' '{print $5}'|awk -F'.' '{print $1}'`
		printf "行号：%-10s 表名：%-30s 表总占用空间：%-10s 表实际占用空间：%-10s 行数：%-10s \n" "${hanghao}" "${tabname}" "${total_byte}" "${data_byte}" "${rows}"
#		echo -e "行号：${hanghao} \t 表名：${tabname} \t 表总占用空间：${total_byte} \t 表实际占用空间：${data_byte} \t 行数：${rows}"
	done <gejie.yuchuli.unl

	if [ X$cludeflag = Xin ]
	then
		read -p  "上述是大小最大的40个表，请选择要指定的表的行号，以逗号分隔，举例[1,2,3]：" paichuhang
		paichuhangOK=`Ppaichuhang "$paichuhang"`
		while [[ X$paichuhangOK != XOK ]]
		do
			read -p "刚才输入的有误，请重新输入：" paichuhang
			paichuhangOK=`Ppaichuhang "$paichuhang"`
		done
		echo "$paichuhang" >temp.temp.unl
		sed "s/,/\n/g" temp.temp.unl >paichuhang.txt
		rm -rf temp.temp.unl
		while read paichuhang
		do
			while read tablehang
			do
				tablenum=`echo $tablehang|awk -F'|' '{print $1}'`
				tablename=`echo $tablehang|awk -F'|' '{print $2}'`
				if [ X$tablenum = X$paichuhang ]
				then
					echo $tablehang|awk -F'|' '{print $2}' >> in.txt
				fi
			done < gejie.yuchuli.unl
		done < paichuhang.txt
		rm -rf gejie.yuchuli.unl;
		rm -rf paichuhang.txt;
		log4s "已经生成in.txt，如果有额外需求请手动修改该文件，每行一个表名，无需其他任何符号" uload
	elif [ X$cludeflag = Xex ]
	then
		read -p  "上述是大小最大的40个表，请选择要排除的表的行号，以逗号分隔，举例[1,2,3]：" paichuhang
		paichuhangOK=`Ppaichuhang "$paichuhang"`
		while [[ X$paichuhangOK != XOK ]]
		do
			read -p "刚才输入的有误，请重新输入：" paichuhang
			paichuhangOK=`Ppaichuhang "$paichuhang"`
		done
		echo "$paichuhang" >temp.temp.unl
		sed "s/,/\n/g" temp.temp.unl >paichuhang.txt
		rm -rf temp.temp.unl
		while read paichuhang
		do
		 while read tablehang
		 do
		 	tablenum=`echo $tablehang|awk -F'|' '{print $1}'`
		 	tablename=`echo $tablehang|awk -F'|' '{print $2}'`
		 	if [ X$tablenum = X$paichuhang ]
		 	then
		 		echo $tablehang|awk -F'|' '{print $2}' >> ex.txt
		 	fi
		 done < gejie.yuchuli.unl
		done < paichuhang.txt
		rm -rf gejie.yuchuli.unl;
		rm -rf paichuhang.txt;
		log4s "已经生成ex.txt，如果有额外需求请手动修改该文件，每行一个表名，无需其他任何符号" unload
	else
		log4s "当前为全量导出模式，不排除也不指定表的导出模式"
	fi
}


if [ $LOADFLAG = 'unload' ]
then
	unloadschema
elif [ $LOADFLAG = 'unloaddata' ]
then
	unloaddata
elif [ $LOADFLAG = 'load' ]
then
	loadschema
elif [ $LOADFLAG = 'loaddata' ]
then
	loaddata
elif [ $LOADFLAG = 'getinfo' ]
then
	getinfo
else
	log4s "参数不正确"
fi