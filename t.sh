#!/bin/sh

#�汾1.0��ʽʹ��
#����ͨ���汾��6.8
#############################################
#�����ű��Ͱ�װ���ŵ�/tmp��
#��ʱֻ֧��linux
#############################################


makedisk()
{
	#ʹ�÷�������һ��������$dbs
	fenqunum=`sfdisk -l $1 |grep Linux|wc -l|awk '{print $1}'`
	if [ $fenqunum != 0 ]
	then
		SendAlarm "��֧�����з���Ӳ�̽��л��֣����ֶ�����Ӳ��"
		exit 1
	fi
	if [ $ifull = ok ]
	then
		fdisk $1 <<-EOF
		n
		p
		1
		
		
		w
		EOF
	fi
	if [ $ifull = full ]
	then
		SendAlarm "Ӳ�̿ռ䲻�㣬�����Ӳ��"
		exit 1;
	fi
	if [ $ifull = 0 ]
	then
		SendAlarm "��ִ��diskisfull��������ִ�и�makedisk"
		exit 1;
	fi
	getdiskname=`fdisk -l|grep "$1"|tail -1|awk '{print $1}'`
	disknamenum=`fdisk -l|grep "$getdiskname"|wc -l|awk '{print $1}'`
	if [ $disknamenum = 1 ]
	then
		SendAlarm "fdisk�ɹ�������������Ϊ$getdiskname"
	else
		SendAlarm "fdiskʧ��"
		exit 1;
	fi
}

makepv()
{
	#2017.10.10ȡ����vg�Ͻ�������
	##ʹ�÷���������devname��Ϊ$1
	#echo "ֻ֧��ʹ�ø�Ӳ�����һ������"
	#getdiskname=`fdisk -l|grep "$1"|tail -1|awk '{print $1}'`
	#pvcreate $getdiskname
	#getpvnum=`pvscan|grep $getdiskname|wc -l|awk '{print $1}'`
	#if [ $getpvnum = 1 ]
	#then
	#	SendAlarm "pv�����ɹ�"
	#else
	#	SendAlarm "pv����ʧ��"
	#fi
	#echo "��Ӳ�̱���û�з���"
	pvcreate $1
	getpvnum=`pvscan|grep $1|wc -l|awk '{print $1}'`
	if [ $getpvnum = 1 ]
	then
		SendAlarm "pv�����ɹ�"
	else
		SendAlarm "pv����ʧ��"
	fi
}

makevg()
{
	#ʹ�÷���������1��vgname������2��devname
	#2017.10.10ȡ����������
	#getdiskname=`fdisk -l|grep "$2"|tail -1|awk '{print $1}'`
	#vgcreate $1 $getdiskname
	#getvgnum=`vgdisplay|grep "$vgname"|wc -l|awk '{print $1}'`
	#if [ $getvgnum = 1 ]
	#then
	#	SendAlarm "����vg�ɹ���vg����Ϊ$vgname"
	#else
	#	SendAlarm "����vgʧ��"
	#	exit 1;
	#fi
	vgcreate $1 $2
	getvgnum=`vgdisplay|grep "$vgname"|wc -l|awk '{print $1}'`
	if [ $getvgnum = 1 ]
	then
		SendAlarm "����vg�ɹ���vg����Ϊ$vgname"
	else
		SendAlarm "����vgʧ��"
		exit 1;
	fi
}

makelv()
{
	#ʹ�÷����������һ��������lv�����ڶ���������С����ʽΪ1G��������������vg����
	lvcreate -L $2 -n $1 $3
}

getvgname()
{
lvdisplay -v $1 > $idshome/dbs.temp.temp
tempvg=`grep "VG Name" $idshome/dbs.temp.temp|awk '{print $3}'`
echo $tempvg
}


tihuan()
{
	tihuanbasic "$1" "$2" $peizhi
}
xiugai()
{
	tihuanbasic "$1" "$2" /tmp/tempIFX12.sh
}
##############������������################################

#######################�û�����������#####################


#######################�û���������������#################






###################Ӳ����##############################
startfdisk()
{

	#2017.10.10����������disk�Ͻ���������ֱ����disk�Ͻ�vg
	#while [[ $shifouchuangjianfenqu != [YyNn] ]]
	#do
	#	read -p "�Ƿ���Ҫ�����������������������������y/n��" shifouchuangjianfenqu;
	#done
	#if [ $shifouchuangjianfenqu = y ] || [ $shifouchuangjianfenqu = Y ]
	#then
	#	while [[ $shifouqueredevname != [Yy] ]]
	#	do
	#		read -p "������Ӳ��ȫ·��������/dev/sdb��"  devname
	#		read -p "�����ȷ��Ӳ��·���Ƿ�Ϊ$devname���Ҹ�Ӳ��û���κη�����������������ɲ���Ԥ֪������[Y/N]��" shifouqueredevname
	#		fenqugeshu=`fdisk -l $devname|grep Linux|wc -l|awk '{print $1}'`
	#		if [ $fenqugeshu != 0 ] 
	#		then
	#			echo "��Ӳ�����з������޷�ʵ���ٴλ��֡�������ѡ�����"
	#			shifouqueredevname=n
	#		fi
	#	done
	#	if [ $muban = cl ]
	#	then
	#		#�䶯ģ��Ҫ�ĵĵط�
	#		sizesum $sizerootdbs1G $sizetempdbs1G $sizetempdbs2G $sizelogdbs1G $sizephydbs1G $sizeuserdbs1G
	#		diskisfull $devname
	#	fi
	#	if [ $muban = znw ]
	#	then
	#		sizesum $sizerootdbs1G
	#		diskisfull $devname
	#	fi
	#	
	#	makedisk $devname
	#fi
	#����PV

	
	#����vg
	

	
	
	
	#����lv


}

###################Ӳ��������###########################

#############��ȡϵͳ�������������ó���Ϊ�˱��ڵ���#########
X86=`uname -m`
XITONGTEMP=`uname`
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`  #ϵͳ����
XTBANBEN=`cat /etc/issue|head -1|awk '{print $7}'`  #��ȡϵͳ�汾
cpunumtemp=`cat /proc/cpuinfo|grep processor|wc -l`
let cpunum=cpunumtemp-1
kernel_shmmax="kernel.shmmax = 4398046511104"
kernel_shmmni="kernel.shmmni = 4096"
kernel_shmall="kernel.shmall = 67108864"
kernel_sem="kernel.sem = 250 32000 32 4096"


let sizerootdbs1=$sizerootdbs1G*1000000
let sizetempdbs1=$sizetempdbs1G*1000000
let sizetempdbs2=$sizetempdbs2G*1000000
let sizelogdbs1=$sizelogdbs1G*1000000
let sizephydbs1=$sizephydbs1G*1000000
let sizeuserdbs1=$sizeuserdbs1G*1000000




#####################������############
huifu()
{
	SendAlarm "ȡ��rsh����������"
	tihuanbasic ".*disable.*" "        disable                 = yes" /etc/xinetd.d/rsh
	/etc/rc.d/init.d/xinetd restart
	tihuanbasic "rsh" "" /etc/securetty

}
beijihuifu()
{	
	echo "beijidengdaihuifu" > /tmp/dengdaihuifu.txt
	beijikaishihuifuflag=`nc -l $tongxinduankou2 </tmp/dengdaihuifu.txt`
	if [ X$beijikaishihuifuflag = Xbeijikaishihuifu ]
	then
	  huifu
	  killall nc
	fi

}
zhujihuifu(){

	SendAlarm "ȡ���ű���������"

	rm -rf /tmp/temp.sh

}
beijijianting1()
{
	echo "secbootok" > /tmp/bootok.txt
	tempflag=`nc -l $tongxinduankou1 </tmp/bootok.txt`
	if [ X$tempflag = Xkaishihdr ]
	then
		SendAlarm "������ʼ�hdr"
		SendAlarm "�Ѿ�������������1"
	  beijihuifu;
	  killall nc
	fi

}

#############��װ��##########################
#�ж��Ƿ��Ѿ��������װ�ɹ���������δ��������������װ���ں˲����������������ͽ�������Ĳ��衣
anzhuang()
{

	startfdisk;

	if [ ! -d $idshome ]
	then
		echo "������װĿ¼"
		mkdir $idshome
	fi

	if [ X$hdrflag = Xpri ]
	then
		hdrflag=pri
		INFORMIXSERVER=$priINFORMIXSERVER
		ONCONFIG=$priONCONFIG
		DBSERVERALIASES=$priDBSERVERALIASES
	fi
	if [ X$hdrflag = Xsec ]
	then
		hdrflag=sec
		INFORMIXSERVER=$secINFORMIXSERVER
		ONCONFIG=$secONCONFIG
		DBSERVERALIASES=$secDBSERVERALIASES
	fi
	if [ X$hdrflag = Xonly ]
	then
		hdrflag=only
		INFORMIXSERVER=$priINFORMIXSERVER
		ONCONFIG=$priONCONFIG
		DBSERVERALIASES=$priDBSERVERALIASES
	fi
	peizhi=$idshome/etc/$ONCONFIG
		wai=`whoami`
	if [ X$wai != Xroot ]
	then
	SendAlarm  "��ʹ��root�˻����а�װ"
	exit 0;
	fi
if [ ! -f $alreadyornolog ]
then
	touch $alreadyornolog
	SendAlarm "�������ݿ�����ʶ�ļ�$alreadyornolog"
	initflag=0
##############�����жϣ��������������޷������ű�#############
	if [ X$X86 != Xx86_64 ]
	then
		SendAlarm "ϵͳΪ32λ�汾����ʱ��֧��"
		exit 0;
	fi
	
	if [ ! -f /tmp/$jiaobenming ]
	then
		SendAlarm "�뽫���ű�����/tmp�ļ�����"
		exit 0;
	fi
	if [ ! -f /tmp/$anzhuangbao ]
	then
		SendAlarm "�뽫$anzhuangbao�ŵ�/tmp��";
		exit 0;
	fi
	
	FILEsize=`stat -c %s /tmp/$anzhuangbao`
	if [ X$FILEsize != X564142080 ]
	then
		SendAlarm "�ļ���С����ȷ����˶Ժ��ٽ��У���СӦΪ554557440�ֽ�";
		exit 0;
	fi


	if [ ! -h $lvrootdbs1 ]
	then
		SendAlarm "$lvrootdbs1 �����ڣ����ȴ�����lv"
		exit 0;
	fi
	if [ ! -h $lvtempdbs1 ]
	then
		SendAlarm "$lvtempdbs1 �����ڣ����ȴ�����lv"
		exit 0;
	fi
	if [ ! -h $lvtempdbs2 ]
	then
		SendAlarm "$lvtempdbs2 �����ڣ����ȴ�����lv"
		exit 0;
	fi
	if [ ! -h $lvlogdbs1 ]
	then
		SendAlarm "$lvlogdbs1 �����ڣ����ȴ�����lv"
		exit 0;
	fi
	if [ ! -h $lvphydbs1 ]
	then
		SendAlarm "$lvphydbs1 �����ڣ����ȴ�����lv"
		exit 0;
	fi
	if [ ! -h $lvuserdbs1 ]
	then
		SendAlarm "$lvuserdbs1 �����ڣ����ȴ�����lv"
		exit 0;
	fi
	
	if [ X$XTBANBEN != X5.9 ] && [ X$XTBANBEN != X6.0 ] && [ X$XTBANBEN != X6.1 ] && [ X$XTBANBEN != X6.2 ] && [ X$XTBANBEN != X6.3 ] && [ X$XTBANBEN != X6.4 ] && [ X$XTBANBEN != X6.5 ] && [ X$XTBANBEN != X6.6 ] && [ X$XTBANBEN != X6.7 ] && [ X$XTBANBEN != X6.8 ]
	then
		SendAlarm "ϵͳ�汾�ݲ�֧�֣�����ϵ�ű�������Ա"
		exit 0;
	fi

else
	initflag=`grep "alreadyinstall informix" $alreadyornolog|wc -l|awk '{print $1}'`
fi
if [ $initflag = 0 ]
then
	#�û��Ƿ���ڣ���������ھͽ���
	userexistflag=`grep informix /etc/passwd|wc -l|awk '{print $1}'`
	if [ X$userexistflag != X1 ]
	then
		#linux��װ����
		if [ X$XITONG = XLINUX ]
		then
			SendAlarm "�����û���"
			groupadd informix;
			SendAlarm "�����û�"
			useradd -g informix -d $informixhome informix;
			chown informix:informix $idshome
			passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
		fi
		#AIX��װ����
		if [ X$XITONG = XAIX ]
		then
			mkgroup informix;
			mkuser pgrp=informix home=$informixhome informix
			passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
	
		fi
	fi
	echo "LANG=$LANG:zh_CN.UTF8:zh_CN.GB18030" >> /home/informix/.bash_profile
	
	if [ ! -d $idshome ]
	then
		SendAlarm "������װĿ¼"
		mkdir $idshome
	fi
	chown informix:informix $idshome
	INFORMIXDIR=$idshome
	export INFORMIXDIR
	
	
	#�޸�ռλ����
	SendAlarm "�޸�ռλ�����Ա��������"

	xiugai "priINFORMIXSERVER=XXXXXX"       "priINFORMIXSERVER=$priINFORMIXSERVER"
	xiugai "secINFORMIXSERVER=XXXXXX"       "secINFORMIXSERVER=$secINFORMIXSERVER"
	xiugai "priDBSERVERALIASES=XXXXXX"      "priDBSERVERALIASES=$priDBSERVERALIASES"
	xiugai "secDBSERVERALIASES=XXXXXX"      "secDBSERVERALIASES=$secDBSERVERALIASES"
	xiugai "priname=XXXXXX"                 "priname=$priname"
	xiugai "secname=XXXXXX"                 "secname=$secname"
	xiugai "priONCONFIG=XXXXXX"							"priONCONFIG=$priONCONFIG"
	xiugai "secONCONFIG=XXXXXX"							"secONCONFIG=$secONCONFIG"
	xiugai "priappname=XXXXXX"              "priappname=$priappname"
	xiugai "secappname=XXXXXX"              "secappname=$secappname"
	xiugai "priip=XXXXXX"                   "priip=$priip"
	xiugai "secip=XXXXXX"                   "secip=$secip"
	xiugai "priappip=XXXXXX"                "priappip=$priappip"
	xiugai "secappip=XXXXXX"                "secappip=$secappip"

	xiugai "vgname=XXXXXX"                  "vgname=$vgname"
	chmod 777 /tmp/tempIFX12.sh
	if [ X$prionly = X1 ] && [ X$hdrflag = Xpri ]
	then
		SendAlarm "���ڽ��ű��Ͱ�װ�����Ƶ����������ֶ��������루��Ҫ��Σ�"
		mkdir /tmp/scptempdir/
		cp /tmp/tempIFX12.sh /tmp/scptempdir/IFX12.sh
		mv /tmp/$anzhuangbao /tmp/scptempdir/
		scp -oPort=19222 -r /tmp/scptempdir/* root@$secip:/tmp/
		mv /tmp/scptempdir/$anzhuangbao /tmp/
		ssh -oPort=19222 root@$secip 'cd /tmp;nohup sh ./IFX12.sh anzhuang >/tmp/anzhuang.log 2>&1 &'
		echo "��Ҫ���������ݽ��������濪ʼȫ�Զ���װ�������������ݿ⣬�HDR�������ڰ�װ���������κβ���"
		sleep 3;
	fi

	
	
	SendAlarm "�ƶ���װ������װĿ¼"
	mv $anzhuangbao $idshome/
	cd $idshome;
	SendAlarm "��ѹ��װ��"
	tar -xvf  $idshome/$anzhuangbao -C $idshome/
	mv $idshome/$anzhuangbao /tmp
	SendAlarm "��ʼ�Զ��������ݿ�"
	$idshome/ids_install <<EOF

1
/ids/
Y

1
2



EOF
	
	SendAlarm "�������"
	SendAlarm "�޸��ں˲���"
	kernel_shmmaxnum=`grep "kernel.shmmax = 4398046511104" /etc/sysctl.conf|wc -l`
	kernel_shmmninum=`grep "kernel.shmmni = 4096" /etc/sysctl.conf|wc -l`
	kernel_shmallnum=`grep "kernel.shmall = 67108864" /etc/sysctl.conf|wc -l`
	kernel_semnum=`grep "kernel.sem = 250 32000 32 4096" /etc/sysctl.conf|wc -l`
	if [ $kernel_shmmaxnum = 0 ]
	then
		echo "kernel.shmmax = 4398046511104" >> /etc/sysctl.conf
	fi
	if [ $kernel_shmmninum = 0 ]
	then
		echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
	fi
	if [ $kernel_shmallnum = 0 ]
	then
		echo "kernel.shmall = 67108864" >> /etc/sysctl.conf
	fi
	if [ $kernel_semnum = 0 ]
	then
		echo "kernel.sem = 250 32000 32 4096" >> /etc/sysctl.conf
	fi


	SendAlarm "����ں˲���д���Ƿ���ȷ"

	kernel_shmmaxok=`grep "kernel.shmmax = 4398046511104" /etc/sysctl.conf|wc -l`
	kernel_shmmniok=`grep "kernel.shmmni = 4096" /etc/sysctl.conf|wc -l`
	kernel_shmallok=`grep "kernel.shmall = 67108864" /etc/sysctl.conf|wc -l`
	kernel_semok=`grep "kernel.sem = 250 32000 32 4096" /etc/sysctl.conf|wc -l`
	if [ X$kernel_shmmaxok != X1 ] || [ X$kernel_shmmniok != X1 ] || [ X$kernel_shmallok != X1 ] || [ X$kernel_semok != X1 ]
	then
	SendAlarm "�ں˲���д���쳣������"
	exit 0;
	fi
	SendAlarm "д���ں����ݸ��±�ʶ"
	echo "alreadyinstall informix" >> $alreadyornolog
	cp /tmp/$jiaobenming $idshome/

	if [ ! -d $idshome/dbfiles ]
	then
		mkdir $idshome/dbfiles
		chown informix:informix $idshome/dbfiles
		chmod 776 $idshome/dbfiles
	fi
	
	chmod 777 $idshome/$jiaobenming
	chmod 777 $alreadyornolog
	chmod 777 $log
	
	SendAlarm "����dbfilesĿ¼"
	mkdir $idshome/dbfiles
	chown informix:informix /$idshome/dbfiles
	chmod 775 /$idshome/dbfiles
	SendAlarm "���������ļ���"
	ln -s $lvrootdbs1 $idshome/dbfiles/rootdbs1
	ln -s $lvtempdbs1 $idshome/dbfiles/tempdbs1
	ln -s $lvtempdbs2 $idshome/dbfiles/tempdbs2
	ln -s $lvlogdbs1 $idshome/dbfiles/logdbs1
	ln -s $lvphydbs1 $idshome/dbfiles/phydbs1
	ln -s $lvuserdbs1 $idshome/dbfiles/userdbs1
	chown informix:informix $idshome/dbfiles/rootdbs1
	chown informix:informix $idshome/dbfiles/tempdbs1
	chown informix:informix $idshome/dbfiles/tempdbs2
	chown informix:informix $idshome/dbfiles/logdbs1
	chown informix:informix $idshome/dbfiles/phydbs1
	chown informix:informix $idshome/dbfiles/userdbs1
	chmod 660 $idshome/dbfiles/rootdbs1
	chmod 660 $idshome/dbfiles/tempdbs1
	chmod 660 $idshome/dbfiles/tempdbs2
	chmod 660 $idshome/dbfiles/logdbs1
	chmod 660 $idshome/dbfiles/phydbs1
	chmod 660 $idshome/dbfiles/userdbs1
	
	SendAlarm "�޸������ļ�Ȩ����"
	chown informix:informix $lvrootdbs1
	chown informix:informix $lvtempdbs1
	chown informix:informix $lvtempdbs2
	chown informix:informix $lvlogdbs1
	chown informix:informix $lvphydbs1
	chown informix:informix $lvuserdbs1
	chmod 660 $lvrootdbs1
	chmod 660 $lvtempdbs1
	chmod 660 $lvtempdbs2
	chmod 660 $lvlogdbs1
	chmod 660 $lvphydbs1
	chmod 660 $lvuserdbs1
	
	if [ X$XTBANBEN = X5.8 ] || [ X$XTBANBEN = X5.7 ] || [ X$XTBANBEN = X5.6 ] || [ X$XTBANBEN = X5.5 ] || [ X$XTBANBEN = X5.4 ] || [ X$XTBANBEN = X5.3 ] || [ X$XTBANBEN = X5.2 ] || [ X$XTBANBEN = X5.1 ] || [ X$XTBANBEN = X5.0 ]
	then
		SendAlarm "���������޸�Ȩ������"
		echo "chown informix:informix $lvrootdbs1" >> /etc/rc.d/rc.local
		echo "chown informix:informix $lvtempdbs1" >> /etc/rc.d/rc.local
		echo "chown informix:informix $lvtempdbs2" >> /etc/rc.d/rc.local
		echo "chown informix:informix $lvlogdbs1" >> /etc/rc.d/rc.local
		echo "chown informix:informix $lvphydbs1" >> /etc/rc.d/rc.local
		echo "chown informix:informix $lvuserdbs1" >> /etc/rc.d/rc.local
		echo "chmod 660 $lvrootdbs1" >> /etc/rc.d/rc.local
		echo "chmod 660 $lvtempdbs1" >> /etc/rc.d/rc.local
		echo "chmod 660 $lvtempdbs2" >> /etc/rc.d/rc.local
		echo "chmod 660 $lvlogdbs1" >> /etc/rc.d/rc.local
		echo "chmod 660 $lvphydbs1" >> /etc/rc.d/rc.local
		echo "chmod 660 $lvuserdbs1" >> /etc/rc.d/rc.local
	fi
	
	SendAlarm "����5.9����6.5���ض�����"
	if [ X$XTBANBEN = X5.9 ] || [ X$XTBANBEN = X6.0 ]|| [ X$XTBANBEN = X6.1 ]|| [ X$XTBANBEN = X6.2 ]|| [ X$XTBANBEN = X6.3 ] || [ X$XTBANBEN = X6.4 ] 
	then
		echo "ENV{DM_NAME}==\"$lvrootdbs1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_NAME}==\"$lvtempdbs1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_NAME}==\"$lvtempdbs2\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_NAME}==\"$lvlogdbs1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_NAME}==\"$lvphydbs1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_NAME}==\"$lvuserdbs1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
	if [ X$XTBANBEN = X6.5 ] || [ X$XTBANBEN = X6.6 ] || [ X$XTBANBEN = X6.7 ] || [ X$XTBANBEN = X6.8 ] || [ X$XTBANBEN = X6.9 ]
	then

		echo "ENV{DM_VG_NAME}==\"$vgname\", ENV{DM_LV_NAME}==\"rootdbs1\", OWNER:=\"informix\", GROUP:=\"informix\"" >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_VG_NAME}==\"$vgname\", ENV{DM_LV_NAME}==\"phydbs1\", OWNER:=\"informix\", GROUP:=\"informix\""  >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_VG_NAME}==\"$vgname\", ENV{DM_LV_NAME}==\"logdbs1\", OWNER:=\"informix\", GROUP:=\"informix\""  >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_VG_NAME}==\"$vgname\", ENV{DM_LV_NAME}==\"userdbs1\", OWNER:=\"informix\", GROUP:=\"informix\"" >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_VG_NAME}==\"$vgname\", ENV{DM_LV_NAME}==\"tempdbs1\", OWNER:=\"informix\", GROUP:=\"informix\"" >> /etc/udev/rules.d/93-application-devices.rules
		echo "ENV{DM_VG_NAME}==\"$vgname\", ENV{DM_LV_NAME}==\"tempdbs2\", OWNER:=\"informix\", GROUP:=\"informix\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
	
	SendAlarm "�޸�informix�Ļ������������ļ�"
	if [ X$XITONG = XLINUX ]
	then
		bashprofile=".bash_profile"
		echo "INFORMIXDIR=$idshome" >> /home/informix/$bashprofile
		echo "PATH=\$PATH:\$INFORMIXDIR/bin:\$INFORMIXDIR/lib/esql" >> /home/informix/$bashprofile
		echo "INFORMIXSERVER=$INFORMIXSERVER" >> /home/informix/$bashprofile
		echo "ONCONFIG=$ONCONFIG" >> /home/informix/$bashprofile
		echo "export INFORMIXDIR PATH INFORMIXSERVER ONCONFIG" >> /home/informix/$bashprofile
		echo "INFORMIXCONTIME=2" >> /home/informix/$bashprofile
		echo "INFORMIXCONRETRY=1" >> /home/informix/$bashprofile
		echo "export INFORMIXCONTIME INFORMIXCONRETRY " >> /home/informix/$bashprofile
	fi
	if [ X$XITONG = XAIX ]
	then
		bashprofile=".profile"
		echo "INFORMIXDIR=$idshome" >> /home/informix/$bashprofile
		echo "PATH=\$PATH:\$INFORMIXDIR/bin:\$INFORMIXDIR/lib/esql" >> /home/informix/$bashprofile
		echo "INFORMIXSERVER=$INFORMIXSERVER" >> /home/informix/$bashprofile
		echo "ONCONFIG=$ONCONFIG" >> /home/informix/$bashprofile
		echo "export INFORMIXDIR PATH INFORMIXSERVER ONCONFIG" >> /home/informix/$bashprofile
		echo "INFORMIXCONTIME=2" >> /home/informix/$bashprofile
		echo "INFORMIXCONRETRY=1" >> /home/informix/$bashprofile
		echo "export INFORMIXCONTIME INFORMIXCONRETRY " >> /home/informix/$bashprofile
	fi
	
	SendAlarm "д��.rhosts�ļ����������Ҫ���Լ��޸�.rhost�ļ���Ĭ��Ϊ+"
	echo '+' > /home/informix/.rhosts
	chown informix:informix /home/informix/.rhosts
	chmod 660 /home/informix/.rhosts
	
	SendAlarm "��ʼ�޸������ļ�"
	cp $idshome/etc/onconfig.std $peizhi
	chown informix:informix $peizhi
	
	tihuan "^ROOTPATH \$INFORMIXDIR/tmp/demo_on.rootdbs" "ROOTPATH $idshome/dbfiles/rootdbs1";
	tihuan "^ROOTSIZE 300000" "ROOTSIZE 2000000";
	tihuan "^MSGPATH \$INFORMIXDIR/tmp/online.log" "MSGPATH /home/informix/online.log";
	tihuan "^DBSPACETEMP" "DBSPACETEMP tempdbs1,tempdbs2";
	tihuan "^ONDBSPACEDOWN 2" "ONDBSPACEDOWN 1";
	tihuan "^DBSERVERNAME" "DBSERVERNAME $INFORMIXSERVER";
	tihuan "^DBSERVERALIASES" "DBSERVERALIASES $DBSERVERALIASES";
	tihuan "^FULL_DISK_INIT.*" "FULL_DISK_INIT  1";
	tihuan "^NETTYPE ipcshm,1,50,CPU" "NETTYPE soctcp,4,150,NET";
	SendAlarm "NETTYPEĬ����дΪsoctcp,4,150,NET������������������޸�"
	tihuan "^MULTIPROCESSOR 0" "MULTIPROCESSOR 1";
	tihuan "^VPCLASS cpu,num=1,noage" "VPCLASS cpu,num=${cpunum},noage";
	tihuan "^LOCKS 20000" "LOCKS 200000";
	tihuan "^SHMVIRTSIZE 32656" "SHMVIRTSIZE 200000";
	tihuan "^SHMADD 8192" "SHMADD 80000";
	tihuan "^CKPTINTVL 300" "CKPTINTVL 30";
	tihuan "^TAPEDEV /dev/tapedev" "TAPEDEV /dev/null";
	tihuan "^TAPEBLK 32" "TAPEBLK 128";
	tihuan "^LTAPEDEV /dev/tapedev" "LTAPEDEV /dev/null";
	tihuan "^BAR_ACT_LOG \$INFORMIXDIR/tmp/bar_act.log" "BAR_ACT_LOG /home/informix/bar_act.log";
	tihuan "^OPTCOMPIND 2" "OPTCOMPIND 0";
	tihuan "^DRAUTO                  0" "DRAUTO                  2";
	tihuan "^DUMPDIR \$INFORMIXDIR/tmp" "DUMPDIR /home/informix/tmp";
	tihuan "^DUMPSHMEM 1" "DUMPSHMEM 0";
	#��ʽ�����������
	tihuan "^BUFFERPOOL default.*" "BUFFERPOOL default,buffers=3000000,lrus=64,lru_min_dirty=0,lru_max_dirty=0.05";
	tihuan "^BUFFERPOOL size.*" " ";
	#����ԭ�����������̫����ʽ��װʱ��ʹ������Ķ�������������
	#tihuan "^BUFFERPOOL default,buffers=10000,lrus=8,lru_min_dirty=50.00,lru_max_dirty=60.50" "BUFFERPOOL default,buffers=3000000,lrus=64,lru_min_dirty=0,lru_max_dirty=0.05";
	#tihuan "^BUFFERPOOL size=2k,buffers=50000,lrus=8,lru_min_dirty=50,lru_max_dirty=60" "";
	chown informix:informix $peizhi
	if [ X$hdrflag = Xonly ]
	then
		echo "$priINFORMIXSERVER     onsoctcp      $priip       7778" >> $idshome/etc/sqlhosts
		echo "$priDBSERVERALIASES     onsoctcp     $priappip    7779" >> $idshome/etc/sqlhosts
	fi
	if [ X$hdrflag = Xpri ] || [ X$hdrflag = Xsec ]
	then
		echo "$priINFORMIXSERVER      onsoctcp     $priip       7778" >> $idshome/etc/sqlhosts
		echo "$secINFORMIXSERVER      onsoctcp     $secip       7778" >> $idshome/etc/sqlhosts
		echo "$priINFORMIXSERVER      onsoctcp     $priappip    7778" >> $idshome/etc/sqlhosts
		echo "$secINFORMIXSERVER      onsoctcp     $secappip    7778" >> $idshome/etc/sqlhosts
		echo "$priDBSERVERALIASES     onsoctcp     $priip       7779" >> $idshome/etc/sqlhosts
		echo "$secDBSERVERALIASES     onsoctcp     $secip       7779" >> $idshome/etc/sqlhosts
		echo "$priDBSERVERALIASES     onsoctcp     $priappip    7779" >> $idshome/etc/sqlhosts
		echo "$secDBSERVERALIASES     onsoctcp     $secappip    7779" >> $idshome/etc/sqlhosts

	fi
	chown informix:informix $idshome/etc/sqlhosts
	chown informix:informix $idshome/etc/*
	if [ -f /etc/hosts.equiv ]
	then
		SendAlarm "����/etc/hosts.equiv"
		eq1=`grep "$priname$" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		if [ X$eq1 != X1 ]
		then
			echo $priname >> /etc/hosts.equiv
		fi
		if [ X$hdrflag != Xonly ]
		then
			eq2=`grep "$secname$" /etc/hosts.equiv|wc -l|awk '{print $1}'`
			if [ X$eq2 != X1 ]
			then
				echo $secname >> /etc/hosts.equiv
			fi
		fi
		eq3=`grep "$priappname$" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		if [ X$eq3 != X1 ]
		then
			echo $priappname >> /etc/hosts.equiv
		fi
		if [ X$hdrflag != Xonly ]
		then
			eq4=`grep "$secappname$" /etc/hosts.equiv|wc -l|awk '{print $1}'`
			if [ X$eq4 != X1 ]
			then
				echo $secappname >> /etc/hosts.equiv
			fi
		fi
		eq5=`grep "+" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		if [ X$eq5 != X1 ]
		then
			echo "+" >> /etc/hosts.equiv
		fi
	else
		echo $priname >> /etc/hosts.equiv
		echo $priappname >> /etc/hosts.equiv
		if [ X$hdrflag != Xonly ]
		then
			echo $secname >> /etc/hosts.equiv
			echo $secappname >> /etc/hosts.equiv
		fi
		echo "+" >> /etc/hosts.equiv
	fi
	SendAlarm "����hosts�ļ�"
	hosts1=`grep -F "$priip $priname" /etc/hosts|wc -l|awk '{print $1}'`
	hosts3=`grep -F "$priappip $priappname" /etc/hosts|wc -l|awk '{print $1}'`
	if [ X$hdrflag != Xonly ]
	then
		hosts2=`grep -F "$secip $secname" /etc/hosts|wc -l|awk '{print $1}'`
		hosts4=`grep -F "$secappip $secappname" /etc/hosts|wc -l|awk '{print $1}'`
	fi
	if [ X$hosts1 != X1 ]
	then
		echo "$priip $priname" >> /etc/hosts
	fi
	if [ X$hosts3 != X1 ]
	then
		echo "$priappip $priappname" >> /etc/hosts
	fi
	if [ X$hdrflag != Xonly ]
	then
		if [ X$hosts4 != X1 ]
		then
			echo "$secappip $secappname" >> /etc/hosts
		fi
			if [ X$hosts2 != X1 ]
		then
			echo "$secip $secname" >> /etc/hosts
		fi
	fi
	SendAlarm "��Ч�ں˲���"
	sysctl -p;
	#�����Զ�������
	if [ X$hdrflag = Xsec ]
	then
		SendAlarm "����������rsh����"
		tihuanbasic ".*disable.*" "        disable                 = no" /etc/xinetd.d/rsh
		echo "rsh" >> /etc/securetty
		/etc/rc.d/init.d/xinetd restart
		#echo "/etc/rc.d/init.d/xinetd start" >> /etc/rc.d/rc.local
		#SendAlarm "���ñ����������������"
		#echo "sh /tmp/IFX12.sh beijijianting1" >> /etc/rc.d/rc.local
		SendAlarm "�ȴ������hdr"
		beijijianting1
	fi
	#��������������
	if [ X$hdrflag = Xpri ] || [ X$hdrflag = Xonly ]
	then
		#SendAlarm "����������������ִ�г�ʼ������"
		#echo '#!/bin/sh' > /tmp/temp.sh
		#echo "su - informix -c '. /home/informix/.bash_profile;sh /tmp/IFX12.sh chushihua'" >>/tmp/temp.sh
		#echo "sh /tmp/temp.sh" >> /etc/rc.d/rc.local
		#chmod 777 /tmp/temp.sh
		SendAlarm "��ʼ��ʼ��"
		echo "su - informix -c '. /home/informix/.bash_profile;sh /tmp/tempIFX12.sh chushihua'" >/tmp/temp.sh
		chmod 777 /tmp/temp.sh
		
		
		vgname=`echo $lvrootdbs1 |awk -F'/' '{print $3}'`
		xiugai "^peizhiflag.*"                  "peizhiflag=0"


		chmod 777 /tmp/tempIFX12.sh
		chmod 777 /tmp/temp.sh
		sh /tmp/temp.sh
		
	fi
	#���£�ֱ����Чϵͳ�ںˣ���������ϵͳ��
	#reboot;
fi


}
###################�hdr��###############333
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
	SendAlarm "��ʼ�㱸���ָ�����"
	ontape -t STDIO -s -L 0 -F|rsh $secip "cd /home/informix;. ./.bash_profile ; ontape -t STDIO -p";
	sleep 5;
	SendAlarm "��ʼ����������״̬"
	onmode -d primary $secINFORMIXSERVER;
	rsh $secip "cd /home/informix;. ./.bash_profile ; onmode -d secondary $priINFORMIXSERVER";
	sleep 1;
	SendAlarm "HDR����"
	while true
	do
	zhubeihdrokle=`echo "beijikaishihuifu"|nc $secip $tongxinduankou2`
		if [ X$zhubeihdrokle = Xbeijidengdaihuifu ]
		then
			SendAlarm "�����ָ�rsh������"
			break;
		fi
	sleep 1;
	done;

}
#########################��ʼ����##############
#ʹ�õ�ǰ�����Ѿ��޸ĺ�sqlhosts�ļ���/etc/hosts.*�ļ�
if [ $# = 1 ] && [ $1 = chushihua ]
then
	wai1=`whoami`
	if [ $wai1 != informix ]
	then
		echo "����informix�˻�����"
		exit 0;
	fi
	chmod 776 /ids/dbfiles;
	
	oninit -ivy;
	onspaces -c -d tempdbs1 -t -p /ids/dbfiles/tempdbs1 -o 0 -s $sizetempdbs1;
	sleep 3;
	onspaces -c -d tempdbs2 -t -p /ids/dbfiles/tempdbs2 -o 0 -s $sizetempdbs2;
	sleep 3;
	onspaces -c -d logdbs -p /ids/dbfiles/logdbs1 -o 0 -s $sizelogdbs1;
	sleep 3;
	onspaces -c -d phydbs -p /ids/dbfiles/phydbs1 -o 0 -s $sizephydbs1;
	sleep 3;
	onspaces -c -d userdbs -p /ids/dbfiles/userdbs1 -o 0 -s $sizeuserdbs1;
	sleep 3;
	ontape -s -L 0;
	sleep 10;
	onmode -sy;
	for i in {1..36}
	do
		onparams -a -d logdbs -s 200000;
		let i+=1

	done
	ontape -s -L 0;
	onparams -d -l 2 <<EOF
y
EOF

	onparams -d -l 3 <<EOF
y
EOF
	onparams -d -l 4 <<EOF
y
EOF
	onparams -d -l 5 <<EOF
y
EOF
	onparams -d -l 6 <<EOF
y
EOF
	onmode -l;
	onmode -c;
	onparams -d -l 1 <<EOF
y
EOF

	ontape -s -L 0;

	for i in {1..6}
	do
		onparams -a -d logdbs -s 200000;
		let i+=1

	done
	let physize=sizephydbs1*95/100
	onparams -p -s $physize -d phydbs -y;
	ontape -s -L 0;
	onparams -d -l 2 <<EOF
y
EOF

	onparams -d -l 3 <<EOF
y
EOF
	onparams -d -l 4 <<EOF
y
EOF
	onparams -d -l 5 <<EOF
y
EOF
	onparams -d -l 6 <<EOF
y
EOF
	for i in {1..6}
	do
		onparams -a -d logdbs -s 200000;
		let i+=1

	done
	ontape -s -L 0;
	SendAlarm "����ͨ�ţ��ȴ�������װ��ɡ�"
	if [ X$hdrflag != Xonly ]
	then
		while true
		do
			beijiqidongflag=`echo "kaishihdr"|nc $secip $tongxinduankou1`
				if [ X$beijiqidongflag = Xsecbootok ]
				then
					SendAlarm "����ͨ�ţ�������װ��ɡ���ʼ�HDR"
					break;
				fi
			sleep 1;
		done;
		hdr
	fi
	if [ X$hdrflag = Xonly ]
	then
		onmode -m;
		SendAlarm "������װ���"
		killall nc;
		killall nc;
		exit 0;
	fi 
fi






if [ $# = 1 ] && [ $1 = qingli ]
then
	wai2=`whoami`
	if [ X$wai2 = Xroot ]
	then
		su - informix -c '. /home/informix/.bash_profile;onmode -ky'
		rm -rf /home/informix
		rm -rf /ids
		rm -rf /etc/hosts.equiv
		rm -rf /etc/udev/rules.d/93-application-devices.rules
		tihuanbasic "$priip $priname" ""  /etc/hosts
		tihuanbasic "$secip $secname" ""  /etc/hosts
		tihuanbasic "$priappip $priappname" "" /etc/hosts
		tihuanbasic "$secappip $secappname" "" /etc/hosts
		tihuanbasic "chown informix:informix $lvrootdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvtempdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvtempdbs2" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvlogdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvphydbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvuserdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvrootdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvtempdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvtempdbs2" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvlogdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvphydbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvuserdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "kernel.shmmax = 4398046511104" "" /etc/sysctl.conf
		tihuanbasic "kernel.shmmni = 4096" "" /etc/sysctl.conf
		tihuanbasic "kernel.shmall = 67108864" "" /etc/sysctl.conf
		tihuanbasic "kernel.sem = 250 32000 32 4096" "" /etc/sysctl.conf

		#tihuanbasic "/etc/rc.d/init.d/xinetd start" "" /etc/rc.d/rc.local
		#tihuanbasic "sh /tmp/IFX12.sh beijijianting1" "" /etc/rc.d/rc.local
		#tihuanbasic "sh /tmp/temp.sh" "" /etc/rc.d/rc.local
		tihuanbasic "rsh" "" /etc/securetty
		tihuanbasic ".*disable.*" "        disable                 = yes" /etc/xinetd.d/rsh
		ps -u informix|sed 1d|awk '{print $1}'|xargs kill -9
		userdel informix
		rm -rf /var/spool/mail/informix
		rm -rf /tmp/scptempdir
		rm -rf /tmp/temp.sh
		rm -rf /tmp/tempIFX12.sh
		killall nc
		sleep 1
		killall nc
	else
		echo "��Ҫ��root�˻�"
	fi
fi


if [ $# = 1 ] && [ $1 = anzhuang ]
then
	anzhuang
fi