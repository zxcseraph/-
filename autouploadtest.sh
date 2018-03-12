#!/bin/sh
uploadip=10.1.62.38
remotedir=/home/informix/testmulu
localdir=/tmp
uploadfile=webjoin.log
username=informix
password=1#asdZXC
bakdir=/tmp/bak
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
put ${localdir}/$uploadfilefinal $uploadfiletemp
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