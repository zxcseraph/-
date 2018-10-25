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
	log4s "���뵼����ṹģ��" unload
	if [ ! -d $DATADIR ]
	then
		mkdir $DATADIR
	fi
	#���Խ�����Ƿ�ɹ�
	echo "�������ݿ��Ƿ���Խ���" 1>>$DbaccessLog 2>&1
	echo "select distinct(1) from systables"|dbaccess $DBNAME@$SERVERNAME 1>>$DbaccessLog 2>&1
	if [ $? != 0 ]
	then
		log4s "ERROR Ҫ���������ݿⲻ����" unload
		exit 1;
	fi
	cd $DATADIR;
	echo "�������ݿ����нṹ" 1>>$DbaccessLog 2>&1
	dbschema -d $DBNAME -ss allss.sql 1>>$DbaccessLog 2>&1
	if [ $? != 0 ]
	then
		log4s "ERROR ��ṹ�����쳣" unload
		exit 1;
	else
		log4s "��ṹ�����ɹ�" unload
	fi
#	starttablenum=`awk '/create table/{print NR}' allss.sql|head -1`
	#����^M
#	sed "s/\r/\n/g" allss.sql >alltemp.sql
#	mv alltemp.sql allss.sql
#	#�����ǣ���ȡ��һ���洢����Ҳ����create procedure���кţ��ڻ�ȡ����к�֮ǰ�����һ��create table�ţ��ٻ�ȡcreate table��ĵ�һ���ֺţ�������ֺż��Ϻ���ŵ�revoke�������н������
#	#��ȡcreate procedure���к�
#	firstcreateprocedure=`awk '{IGNORECASE=1} /create procedure/{print NR}' allss.sql|head -1`
#	log4s "��ȡ��һ��create procedure���к�Ϊ $firstcreateprocedure"
#	#��һ��create procedureǰ�����һ��create table���к�
#	endcreatenum=`awk -v t="$firstcreateprocedure" '{IGNORECASE=1} /create table/{if(NR<t){print NR}}' allss.sql|tail -1`
#	#��һ����ȡ��create table�Ľ����к�
#	log4s "��ȡ���һ��create table���к�Ϊ $endcreatenum" unload
#	#��ȡ���һ��create table�Ľ����ֺŵ��к�
#	endcreateendnum=`awk -v t="$endcreatenum" '{if(substr($0,length,1)==";" && NR>=t) { print NR}}' allss.sql |head -1`
#	log4s "��ȡcreate table���һ���ֺŵ��к�Ϊ $endcreateendnum" unload
#	#���һ��create table֮����ŵĵ�һ����revoke�к�
#	endtablerevokenum=`awk -v t="$endcreateendnum" '{if($1!="revoke" && NR>t && $0!="") {print NR}}' allss.sql|head -1;`
#	log4s "��ȡ�ĵ�һ����revoke�к�Ϊ $endtablerevokenum " unload 
#	#��ȡ��ṹ������һ���кţ��������������ˣ�ֱ�������һ��revoke��ֵ��һ
#	let endtablerevokenum=endtablerevokenum-1
#	log4s "��ȡ�ı�ṹ������һ���к�Ϊ $endtablerevokenum" unload 
#	#��������ļ�������
#	numsql=`awk '{print NR}' allss.sql|tail -1`
#	log4s "������ṹ������Ϊ $numsql"
#	#��ô���table���������
#	head -$endtablerevokenum allss.sql > ${DBNAME}_table.sql
#	#��ó��˽���������������
#	awk -v t="$endtablerevokenum" '{if(NR>t) { print $0}}' allss.sql >${DBNAME}_other.sql

	#֮ǰ�Ļ��Ʋ��У����û�д洢���̾ͱ��ˣ��������ƣ���ȡ��һ��create��Ȼ���ȡ��������кŵĵ�һ��grant����������
	#��ȡ��һ��create table����Ҫ�����create table�Ǵӵ�һ���ַ���ʼ����ֹ��ĳЩ���ʹ�ø��ַ���
	firstcreatetablenum=`awk '{IGNORECASE=1} /^create table/{print NR}' allss.sql|head -1`
	#��ȡ��һ��create table��ĵ�һ��grant������Ҫ���ǿ�ͷ�����ǿո񣬷�ֹ�����ֶ���Ϊgrant
	firstgrantnum=`awk -v t="$firstcreatetablenum" '{if(NR>t && substr($0,1,5)=="grant"){print NR}}' allss.sql|head -1`
	#������һ�е������õ�
	let endcreatetablenum=firstgrantnum-1
	#��ȡ��ṹ
	head -$endcreatetablenum allss.sql > ${DBNAME}_table.sql
	log4s "������ṹ��¼���ļ� ${DBNAME}_table.sql ��" unload
	#��ȡʣ�����
	awk -v t="$endcreatetablenum" '{if(NR>t) { print $0}}' allss.sql >${DBNAME}_other.sql
	log4s "��ṹ֮�����䱣�����ļ� ${DBNAME}_other.sql ��" unload
	#У���ṹ�ָ�
	cat ${DBNAME}_table.sql > bllss.sql
	cat ${DBNAME}_other.sql >> bllss.sql
	diff allss.sql bllss.sql 1>>/dev/null 2>&1
	if [ $? = 0 ]
	then
		log4s "��ṹ�ָ��У��ɹ�����ʼ���뵼������ģ��" unload
	else
		log4s "ERROR ��ṹ�ָ�У���쳣����˲�" unload
	fi
	unloaddata;
}
loadschema()
{
	#���Խ�����Ƿ�ɹ�
	echo "�������ݿ��Ƿ���Խ���" 1>>$DbaccessLog 2>&1
	echo "select distinct(1) from systables"|dbaccess $DBNAME@$SERVERNAME 1>>$DbaccessLog 2>&1
	if [ $? != 0 ]
	then
		log4s "Ҫ��������ݿⲻ����" load
		exit 1;
	fi
	if [ ! -d $DATADIR ]
	then
		log4s "ERROR $DATADIR�����ڣ�����$DBNAME�Ƿ���ȷ" load
		exit 1;
	fi
	cd $DATADIR;
	if [ ! -f ${DBNAME}_table.sql ] || [ ! -f ${DBNAME}_other.sql ]
	then
		log4s "ERROR Ҫ����ı�ṹ����Ϣ�����ڣ�����${dbname}�Ƿ���ȷ" load
		exit 1;
	fi
	dbaccess $DBNAME@$SERVERNAME ${DBNAME}_table.sql 1>create_table.log 2>&1
	if [ $? = 0 ]
	then
		log4s "������ṹ�ɹ�����ʼ��������" load
		loaddata;
		if [ $? = 0 ]
		then
			log4s "�������ݳɹ�����ʼ������ͼ���洢���̡����������ȹ�����" load
			dbaccess $DBNAME@$SERVERNAME ${DBNAME}_other.sql 1>create_other.log 2>&1
			if [ $? = 0 ]
			then
				log4s "������ͼ���洢���̡����������ȹ��������ɹ�" load
				#У���ṹ
				log4s "��ʼУ���ṹ" load
				echo "�����У���ṹ�ĵ���"  1>>$DbaccessLog 2>&1
				dbschema -d $DBNAME -ss $DATADIR/cllss.sql 1>>$DbaccessLog 2>&1
				diff $DATADIR/allss.sql $DATADIR/cllss.sql > err.sql
				if [ $? = 0 ]
				then
					log4s "��ṹУ��������������" load
				else
					log4s "��ṹУ���쳣���쳣��ο�ԭ��ṹallss.sql���¿�ṹcllss.sql���������� err.sql"
				fi
			else
				log4s "������ͼ���洢���̡����������ȹ���ʧ�ܣ�����create_other.log" load
			fi
		else
			log4s "��������ʧ�ܣ�������־$UNLOADLOGFILE" load
			exit 1;
		fi
	else
		log4s "����ʧ�ܣ�����${DBNAME}_table.sqlִ���Ƿ�����������create_table.log" load
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
		log4s "����config.txt" unload
		while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
		do
			read -p "��ǰΪȫ������ģʽ��������Ҫ�ų��ı�Ҳ��ֻ����ָ�����Ƿ�ȷ�ϡ�y|n��" querencludeflag
		done
		if [ X$querencludeflag = Xn ]
		then
			log4s "��ȡ�����ò������û�Ҫ�󲻷��������нű���getinfo����������ָ�����ų�������á�" unload
			exit 0;
		else
			log4s "��ǰΪȫ������ģʽ��������Ҫ�ų��ı�Ҳ��ֻ����ָ����" unload
			cludeflag=all
		fi
	else
		cludeflag=`tail -1 config.txt|awk -F'=' '{print $2}'`
		if [ X$cludeflag = Xin ]
		then
			if [ -f in.txt ] && [ -s in.txt ]
			then
				log4s "����������in.txt" unload
				while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
				do
					log4s "��ǰΪ����ָ����ģʽ��ָ���ı����£�" unload
					while read hang 
					do
						log4s "$hang" unload
					done < in.txt
					read -p "�Ƿ�ȷ�ϡ�y|n��" querencludeflag
				done
				if [ X$querencludeflag = Xn ]
				then
					log4s "��ȡ�����ò������û�Ҫ�󲻷��������нű���getinfo����������ָ�����ų�������á�" unload
					exit 0;
				else
					log4s "��ǰΪ����ָ����ģʽ��" unload
					cludeflag=in
				fi
			else
				while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
				do
					log4s "��ǰΪ����ָ����ģʽ������ָ������ļ������ڻ���Ϊ�գ�����������getinfo����"
					exit 1;
				done
			fi
		elif [ X$cludeflag = Xex ]
		then
			if [ -f ex.txt ] && [ -s ex.txt ]
			then
				while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
				do
					log4s "��ǰΪ�ų�ָ����ģʽ��ָ���ı����£�" unload
					while read hang 
					do
						log4s "$hang" unload
					done < ex.txt
					read -p "�Ƿ�ȷ�ϡ�y|n��" querencludeflag
				done
				if [ X$querencludeflag = Xn ]
				then
					log4s "��ȡ�����ò������û�Ҫ�󲻷��������нű���getinfo����������ָ�����ų�������á�" unload
					exit 0;
				else
					log4s "��ǰΪ�ų�ָ����ģʽ��" unload
					cludeflag=ex
				fi
			else
				while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
				do
					log4s "��ǰΪ�ų�ָ����ģʽ������ָ������ļ������ڻ���Ϊ�գ�����������getinfo����" unload
					exit 1;
				done
			fi
		elif [ X$cludeflag = Xall ]
		then
			while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
			do
				read -p "��ǰΪȫ������ģʽ��������Ҫ�ų��ı�Ҳ��ֻ����ָ�����Ƿ�ȷ�ϡ�y|n��" querencludeflag
			done
			if [ X$querencludeflag = Xn ]
			then
				log4s "��ȡ�����ò������û�Ҫ�󲻷��������нű���getinfo����������ָ�����ų�������á�" unload
				exit 0;
			else
				log4s "��ǰΪȫ������ģʽ��������Ҫ�ų��ı�Ҳ��ֻ����ָ����" unload
				cludeflag=all
			fi
		else
			while [[ X$querencludeflag != Xy && X$querencludeflag != Xn ]]
			do
				read -p "��ǰΪȫ������ģʽ��������Ҫ�ų��ı�Ҳ��ֻ����ָ�����Ƿ�ȷ�ϡ�y|n��" querencludeflag
			done
			if [ X$querencludeflag = Xn ]
			then
				log4s "��ȡ�����ò������û�Ҫ�󲻷��������нű���getinfo����������ָ�����ų�������á�" unload
				exit 0;
			else
				log4s "��ǰΪȫ������ģʽ��������Ҫ�ų��ı�Ҳ��ֻ����ָ����" unload
				cludeflag=all
			fi
		fi
	fi
	log4s "��ʼ�������б����Ƶ�tab.unl" unload
	echo "�������б�����" 1>>$DbaccessLog 2>&1
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
		log4s "�������ݿ������з�ϵͳ���������" unload
	else
		log4s "�������ݿ������з�ϵͳ�������쳣���������ݿ�״̬�Ƿ�����" unload
	fi
	
	#��ʼ����in����ex�������µ�tab.unl
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
		log4s "�������з�ϵͳ�����ƣ�����ָ��ģʽ��tab.unl" unload
		log4s "ָ��ģʽ��tab.unl�������" unload
	elif [ X$cludeflag = Xex ]
	then
		>tab.unl.temp
		while read hang
		do
			awk -v extab="$hang" '{if(extab!=$1){print $0}}' tab.unl >tab.unl.temp
			mv tab.unl.temp tab.unl
		done < ex.txt
		log4s "�ų�ģʽ��tab.unl�������" unload
	else
		log4s "ȫ��ģʽ���޸�tab.unl" unload
	fi
	log4s "------��ʼ����������------" unload
	while read A B
	do
	echo "������ $A ������" 1>>$DbaccessLog 2>&1
dbaccess $DBNAME@$SERVERNAME <<! 1>>$DbaccessLog 2>&1
unload to $DATADIR/$A.unl
select * from $A;
!
	if (test $? != 0)
	then 
	   log4s "ERROR �� $A ����ʧ�ܣ�����ñ�" unload
	else
	   log4s "�� $A �����ɹ�!" unload
	fi
	done < $DATADIR/tab.unl
	log4s "------ ���������ݽ��� ------" unload
}

loaddata()
{
	RECORDNUMqueren=all
	while [[ X$RECORDNUMqueren != Xy && X$RECORDNUMqueren != Xn ]]
	do
		log4s "��ǰ����� $RECORDNUM �еĽ���ʹ��HPL���룬����߼���־��С���߸÷ֽ���ֵ���󣬿��ܵ��³��������HPL��Ҫ����"
		read -p "�Ƿ�ȷ�ϡ�y|n��" RECORDNUMqueren
	done
	if [ X$RECORDNUMqueren = Xy ]
	then
		log4s "�û��Ͽ� $RECORDNUM �ķֽ���ֵ" load
	elif [ X$RECORDNUMqueren = Xy ]
	then
		log4s "�û����Ͽ� $RECORDNUM �ķֽ���ֵ�����˳��ű������޸�RECORDNUM��������������Ϊ10W" load
		exit 1;
	fi
	log4s "------��ʼ��������------" load
	while read A B
	do
	if [ $B -le $RECORDNUM ]
	then
	echo "����� $A ������" 1>>$DbaccessLog 2>&1
dbaccess $DBNAME@$SERVERNAME <<! 1>>$DbaccessLog 2>&1
load from $DATADIR/$A.unl
insert into $A;
!
		if (test $? != 0)
		then 
		   log4s "ERROR �� $A ����ʧ�ܣ�����ñ�" load
		else
		   log4s "�� $A ����ɹ�" load
		fi
	else
		onpladm create job job$A -d $DATADIR/$A.unl -D $DBNAME -S $SERVERNAME -t $A -fl >>$LOADLOGFILE
		if [ $? = 0 ]
		then
			log4s "�� $A hpl����job�ɹ�" load
		else
			log4s "�� $A hpl����job�ɹ�" load
		fi
		log4s "�� $A hpl��ʼִ��job" load
		onpladm run job job$A -S $SERVERNAME -fl >>$LOADLOGFILE
		if [ $? = 0 ]
		then
			log4s "�� $A hplִ��job�ɹ�" load
		else
			log4s "�� $A hplִ��job�ɹ�" load
		fi
		onpladm delete job job$A -S $SERVERNAME -fl -R >>$LOADLOGFILE
		if [ $? = 0 ]
		then
			log4s "�� $A hplɾ��job�ɹ�" load
		else
			log4s "�� $A hplɾ��job�ɹ�" load
		fi
	fi
	done < $DATADIR/tab.unl
	log4s "------ �������ݽ��� ------" LOADLOGFILE
	#dbaccess $DBNAME@$SERVERNAME <<!
	#update statistics medium;
	#!
	INFORMIXSERVER=$SERVERNAME
	log4s "����ɹ�����ʼ�㱸" load
	echo ` ` | ontape -t STDIO -s -L 0 > /dev/null 
	if [ $? = 0 ]
	then
		log4s "�㱸��ɣ��������ִ�����" load
	else
		log4s "�㱸�쳣���������ݿ�" load
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
		log4s "Ppaichuhang�����������󣬲���Ϊ��"
		exit 1;
	fi
	trsstr1=`echo "$str"|sed 's/[0-9]//g'|sed 's/,//g'|awk '{print length($0)}'`
	if [ X$trsstr1 != X0 ]
	then
		log4s "�����������ֺͶ���֮��������ַ�"
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
	log4s "����Ԥ����׶Σ��ý׶λ�ѡ�ڵ��������ݵ�ʱ���ų�����ָ��ĳ��������ݡ����Ǳ�ṹ�Ի�ȫ��������"
	while [[ X$cludeflag != Xin && X$cludeflag != Xex && X$cludeflag != Xall ]]
	do
		read -p "��ѡ�񵼳���ķ�ʽ�����ų�ָ������ֻѡ��ָ����in|ex|all����in��ָ����ex���ų���all�ǵ������б�" cludeflag
	done
	echo "cludeflag=$cludeflag" > config.txt
	if [ X$cludeflag = Xin ]
	then
		log4s "��ǰѡ����ǡ�����ָ�������ݡ���ʽ"
		log4s "��ǰ��ʽ����${DBNAME}������һ��in.txt��������ָ���ı����������Ҫ���ӻ���ɾ���������ֶ��޸ģ�����������Ҫ����"
		log4s "�������ʾ������ǰ40�ı����Ը���֮ǰѡ���ģʽ��ѡ��ָ�������ı�����"
		> in.txt
	elif [ X$cludeflag = Xex ]
	then
		log4s "��ǰѡ����ǡ��ų�ָ�������ݡ���ʽ"
		log4s "��ǰ��ʽ����${DBNAME}������һ��ex.txt���������ų��ı����������Ҫ���ӻ���ɾ���������ֶ��޸ģ�����������Ҫ����"
		log4s "�������ʾ������ǰ40�ı����Ը���֮ǰѡ���ģʽ��ѡ���ų������ı�����"
		> ex.txt
	else
		log4s "��ǰѡ����ǡ��������б����ݡ���ʽ"
		log4s "�������ʾ������ǰ40�ı�����ѡ����ǵ������б����ݣ�������ʾ�ı���Ϣֻ���ο�"
	fi
	echo "����Ԥ����׶ε���������ǰ40��" 1>>$DbaccessLog 2>&1
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
		printf "�кţ�%-10s ������%-30s ����ռ�ÿռ䣺%-10s ��ʵ��ռ�ÿռ䣺%-10s ������%-10s \n" "${hanghao}" "${tabname}" "${total_byte}" "${data_byte}" "${rows}"
#		echo -e "�кţ�${hanghao} \t ������${tabname} \t ����ռ�ÿռ䣺${total_byte} \t ��ʵ��ռ�ÿռ䣺${data_byte} \t ������${rows}"
	done <gejie.yuchuli.unl

	if [ X$cludeflag = Xin ]
	then
		read -p  "�����Ǵ�С����40������ѡ��Ҫָ���ı���кţ��Զ��ŷָ�������[1,2,3]��" paichuhang
		paichuhangOK=`Ppaichuhang "$paichuhang"`
		while [[ X$paichuhangOK != XOK ]]
		do
			read -p "�ղ�������������������룺" paichuhang
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
		log4s "�Ѿ�����in.txt������ж����������ֶ��޸ĸ��ļ���ÿ��һ�����������������κη���" uload
	elif [ X$cludeflag = Xex ]
	then
		read -p  "�����Ǵ�С����40������ѡ��Ҫ�ų��ı���кţ��Զ��ŷָ�������[1,2,3]��" paichuhang
		paichuhangOK=`Ppaichuhang "$paichuhang"`
		while [[ X$paichuhangOK != XOK ]]
		do
			read -p "�ղ�������������������룺" paichuhang
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
		log4s "�Ѿ�����ex.txt������ж����������ֶ��޸ĸ��ļ���ÿ��һ�����������������κη���" unload
	else
		log4s "��ǰΪȫ������ģʽ�����ų�Ҳ��ָ����ĵ���ģʽ"
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
	log4s "��������ȷ"
fi