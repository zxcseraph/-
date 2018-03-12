#!/bin/sh
uploadip=218.200.160.67
remotedir=/share/jz_ftp/rbtdata/tianjing/backuplogs
localdir=/webjoin/ebupt/logs/soap_prbt_tj3
uploadfile=webjoin.log
username=tianjing
password=Huawei_123
bakdir=/webjoin/ebupt/logs/soap_prbt_tj3
HOSTNAME=`hostname|tr '[a-z]' '[A-Z]'`
lastday=`date +"%Y-%m-%d" -d "-1day"`
uploadfiletemp=${uploadfile}.${lastday}
uploadfilefinal=${uploadfile}.${lastday}.${HOSTNAME}

bakfile=${uploadfiletemp}.gz


upload()
{
if [ -f ${localdir}/$uploadfiletemp ]
then
mv ${localdir}/$uploadfiletemp ${localdir}/$uploadfilefinal
lftp -u $username,$password sftp://$uploadip <<EOF
cd $remotedir
put ${localdir}/$uploadfilefinal
bye
EOF
mv ${localdir}/$uploadfilefinal ${localdir}/$uploadfiletemp
else
echo "文件不存在"
fi
}


bakfile()
{
#压缩后将文件放入指定目录
if [ -f ${localdir}/$uploadfiletemp ]
then
	if [ ! -d $bakdir ]
	then
		mkdir $bakdir
	fi
	gzip $localdir/$uploadfiletemp
	mv $localdir/$bakfile ${bakdir}/
fi
}

upload;
bakfile;