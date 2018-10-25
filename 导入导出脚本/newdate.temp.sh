#!/bin/sh
#3����������һ���ǿ������ڶ�����ʵ����Ҳ����servername���������ǲ�����־��load��unload
if [ $# -ne 3 ]; then
        echo "Usage: $0 dbname servername {load|unload}"
        exit 1
fi
DBNAME=$1
SERVERNAME=$2
LOADFLAG=$3
currentdir=`pwd`
UNLOADLOGFILE=$currentdir/unload_data.log
LOADLOGFILE=$currentdir/load_data.log
RECORDNUM=100000
DATADIR=$currentdir/$DBNAME

if [ $LOADFLAG = 'unload' ]
then
	#��ղ���Ŀ¼
	if [ -e $DATADIR ]
	then
	        rm -fR $DATADIR
	        mkdir $DATADIR
	else
	        mkdir $DATADIR
	fi
	#��ղ�����־
	cat /dev/null > $UNLOADLOGFILE
	dbaccess $DBNAME@$SERVERNAME <<!
unload to $DATADIR/tab.unl delimiter ' ' 
select a.tabname from systables a,sysmaster:sysptnhdr b 
where a.partnum=b.partnum and a.tabid >99
and b.nrows>0
and tabname not in 
(
"m_modinfo","tmn_cpuconf","tmn_dbconf",
"tmn_diskarrayconf","tmn_diskconf","tmn_externconf","tmn_iipcnconf",
"tmn_iipconf","tmn_iipsrfconf","tmn_ioconf","tmnipdisk",
"tmnipid","tmnipioinfo","tmnipneinfo","tmnipreport","tmnipsubsystem",
"tmnipthreshold","tmn_memoryconf","tmn_neconf","tmn_register",
"tmn_registercldb31","tmn_registercldb32","tmn_registercn31",
"tmn_registercn32","tmn_serviceconf","tmn_softwareconf","tmn_srvstat",
"tmn_srvstatsql","tmn_srvuserdata","tmn_subsystemconf","tmn_userconf"
) 
order by nrows 
!
	date >> $UNLOADLOGFILE
	echo "------start unload data table------" >>$UNLOADLOGFILE
	while read A B
	do
dbaccess $DBNAME@$SERVERNAME <<!
unload to $DATADIR/$A.unl
select * from $A;
!
	if (test $? != 0)
	then 
	   echo "��$A����,please check it!" >> $UNLOADLOGFILE
	else
	   echo "table $A unload success!" >> $UNLOADLOGFILE
	fi
	
	done < $DATADIR/tab.unl
fi
#��־λunload����