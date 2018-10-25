#!/bin/sh
secip=$1
secINFORMIXSERVER=$2
priINFORMIXSERVER=$3
log4s()
{
	echo "$1"
	echo "$1" >> log-HDRgo.log
}
hdr()
{
	wai1=`whoami`
	hdfflag=pri
	if [ $wai1 != informix ]
	then
		echo "请用informix账户启动"
		exit 0;
	fi
	onmode -ky;
	oninit;
	log4s "开始零备并恢复备库"
	ontape -t STDIO -s -L 0 -F|rsh $secip "cd /home/informix;. ./.bash_profile ; ontape -t STDIO -p";
	if [ $? != 0 ]
	then
		log4s "零备恢复异常，请检查备机online.log日志"
		exit 1;
	fi
	sleep 5;
	log4s "开始设置主备库状态"
	onmode -d primary $secINFORMIXSERVER;
	rsh $secip "cd /home/informix;. ./.bash_profile ; onmode -d secondary $priINFORMIXSERVER";
	sleep 1;
	log4s "HDR搭建完成，请观察主备机状态"
}
CheckIPAddr()
{
echo $1|grep "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$" > /dev/null; 

        if [ $? -ne 0 ] 
        then 
                return 1 
        fi 
        ipaddr=$1 
        a=`echo $ipaddr|awk -F . '{print $1}'`
        b=`echo $ipaddr|awk -F . '{print $2}'` 
        c=`echo $ipaddr|awk -F . '{print $3}'` 
        d=`echo $ipaddr|awk -F . '{print $4}'` 
        for num in $a $b $c $d 
        do 
                if [ $num -gt 255 ] || [ $num -lt 0 ]
                then 
                        return 1 
                fi 
        done 
                return 0 
}
if [ $# != 3 ]
then
	log4s "参数个数不正确，请使用：第一个参数为备机ip，第二个参数为备机servername，第三个参数为主机servername"
	exit 2;
fi
CheckIPAddr $secip
if [ $? = 1 ]
then
	log4s "备机ip $secip 非法"
	exit 2;
fi

hdr
hdrresult=$?
if [ $? = 0 ]
then
	log4s "hdr搭建成功，请等待几分钟的recovery后，查看hdr状态"
else
	log4s "hdr搭建失败，错误为 $hdrresult"
fi
