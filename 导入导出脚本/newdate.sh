#!/bin/sh

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

if [ -e $DATADIR ]
then
        rm -fR $DATADIR
        mkdir $DATADIR
else
        mkdir $DATADIR
fi

cat /dev/null > $UNLOADLOGFILE


#dbschema -d $DBNAME -ss $currentdir/$DBNAME.sql
#awk '$0~/create table/ && $0!~/numtabta|numtabmob/ {print $0}' $currentdir/$DBNAME.sql | awk -F"." '{print $2}' > $currentdir/tab.tmp

#update statistics medium;
dbaccess $DBNAME@$SERVERNAME <<!
unload to $DATADIR/tab.unl delimiter ' ' 
select a.tabname,b.nrows from systables a,sysmaster:sysptnhdr b 
where a.partnum=b.partnum and a.tabid >99
and a.tabtype<>'V'
and b.nrows>0
and a.tabname not in 
(
"zxc1_m_modinfo_20180507231800_123",
"zxc2_m_modinfo_20180507231800_123",
"zxc3_m_modinfo_20180507231800_123"
) 
order by b.nrows 
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
   echo "!!!table $A unload fail,please check it!" >> $UNLOADLOGFILE
else
   echo "table $A unload success!" >> $UNLOADLOGFILE
fi

done < $DATADIR/tab.unl
echo "------ end unload data table ------" >>$UNLOADLOGFILE
fi
if [ $LOADFLAG = 'load' ]
then

cat /dev/null > $LOADLOGFILE

date >> $LOADLOGFILE
echo "------start load data table------" >>$LOADLOGFILE
while read A B
do
if [ $B -le $RECORDNUM ]
then
dbaccess $DBNAME@$SERVERNAME <<!
load from $DATADIR/$A.unl
insert into $A;
!
if (test $? != 0)
then 
   echo "!!!table $A load fail,please check it!" >> $LOADLOGFILE
else
   echo "table $A load success!" >> $LOADLOGFILE
fi

else
onpladm create job job$A -d $DATADIR/$A.unl -D $DBNAME -S $SERVERNAME -t $A -fl >>$LOADLOGFILE
onpladm run job job$A -S $SERVERNAME -fl >>$LOADLOGFILE
onpladm delete job job$A -S $SERVERNAME -fl -R >>$LOADLOGFILE
fi
done < $DATADIR/tab.unl
echo "------ end load data table ------" >>$LOADLOGFILE
#dbaccess $DBNAME@$SERVERNAME <<!
#update statistics medium;
#!
INFORMIXSERVER=$SERVERNAME
echo ` ` | ontape -s -L 0 > /dev/null 
fi

