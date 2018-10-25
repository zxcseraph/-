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
		echo "����informix�˻�����"
		exit 0;
	fi
	onmode -ky;
	oninit;
	log4s "��ʼ�㱸���ָ�����"
	ontape -t STDIO -s -L 0 -F|rsh $secip "cd /home/informix;. ./.bash_profile ; ontape -t STDIO -p";
	if [ $? != 0 ]
	then
		log4s "�㱸�ָ��쳣�����鱸��online.log��־"
		exit 1;
	fi
	sleep 5;
	log4s "��ʼ����������״̬"
	onmode -d primary $secINFORMIXSERVER;
	rsh $secip "cd /home/informix;. ./.bash_profile ; onmode -d secondary $priINFORMIXSERVER";
	sleep 1;
	log4s "HDR���ɣ���۲�������״̬"
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
	log4s "������������ȷ����ʹ�ã���һ������Ϊ����ip���ڶ�������Ϊ����servername������������Ϊ����servername"
	exit 2;
fi
CheckIPAddr $secip
if [ $? = 1 ]
then
	log4s "����ip $secip �Ƿ�"
	exit 2;
fi

hdr
hdrresult=$?
if [ $? = 0 ]
then
	log4s "hdr��ɹ�����ȴ������ӵ�recovery�󣬲鿴hdr״̬"
else
	log4s "hdr�ʧ�ܣ�����Ϊ $hdrresult"
fi
