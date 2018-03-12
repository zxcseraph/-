#!/bin/sh

#版本1.0正式使用
#测试通过版本：6.8
#############################################
#将本脚本和安装包放到/tmp下
#暂时只支持linux
#############################################


makedisk()
{
	#使用方法，第一个参数是$dbs
	fenqunum=`sfdisk -l $1 |grep Linux|wc -l|awk '{print $1}'`
	if [ $fenqunum != 0 ]
	then
		SendAlarm "不支持已有分区硬盘进行划分，请手动划分硬盘"
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
		SendAlarm "硬盘空间不足，请更换硬盘"
		exit 1;
	fi
	if [ $ifull = 0 ]
	then
		SendAlarm "请执行diskisfull函数后再执行该makedisk"
		exit 1;
	fi
	getdiskname=`fdisk -l|grep "$1"|tail -1|awk '{print $1}'`
	disknamenum=`fdisk -l|grep "$getdiskname"|wc -l|awk '{print $1}'`
	if [ $disknamenum = 1 ]
	then
		SendAlarm "fdisk成功，创建磁盘名为$getdiskname"
	else
		SendAlarm "fdisk失败"
		exit 1;
	fi
}

makepv()
{
	#2017.10.10取消在vg上建立分区
	##使用方法，传入devname作为$1
	#echo "只支持使用该硬盘最后一个分区"
	#getdiskname=`fdisk -l|grep "$1"|tail -1|awk '{print $1}'`
	#pvcreate $getdiskname
	#getpvnum=`pvscan|grep $getdiskname|wc -l|awk '{print $1}'`
	#if [ $getpvnum = 1 ]
	#then
	#	SendAlarm "pv创建成功"
	#else
	#	SendAlarm "pv创建失败"
	#fi
	#echo "该硬盘必须没有分区"
	pvcreate $1
	getpvnum=`pvscan|grep $1|wc -l|awk '{print $1}'`
	if [ $getpvnum = 1 ]
	then
		SendAlarm "pv创建成功"
	else
		SendAlarm "pv创建失败"
	fi
}

makevg()
{
	#使用方法，参数1是vgname，参数2是devname
	#2017.10.10取消建立分区
	#getdiskname=`fdisk -l|grep "$2"|tail -1|awk '{print $1}'`
	#vgcreate $1 $getdiskname
	#getvgnum=`vgdisplay|grep "$vgname"|wc -l|awk '{print $1}'`
	#if [ $getvgnum = 1 ]
	#then
	#	SendAlarm "创建vg成功，vg名称为$vgname"
	#else
	#	SendAlarm "创建vg失败"
	#	exit 1;
	#fi
	vgcreate $1 $2
	getvgnum=`vgdisplay|grep "$vgname"|wc -l|awk '{print $1}'`
	if [ $getvgnum = 1 ]
	then
		SendAlarm "创建vg成功，vg名称为$vgname"
	else
		SendAlarm "创建vg失败"
		exit 1;
	fi
}

makelv()
{
	#使用方法，传入第一个参数是lv名，第二个参数大小（格式为1G），第三个参数vg名称
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
##############基础函数结束################################

#######################用户输入配置区#####################


#######################用户输入配置区结束#################






###################硬盘区##############################
startfdisk()
{

	#2017.10.10调整，不在disk上建立分区，直接在disk上建vg
	#while [[ $shifouchuangjianfenqu != [YyNn] ]]
	#do
	#	read -p "是否需要创建分区，如果创建分区，请输入y/n：" shifouchuangjianfenqu;
	#done
	#if [ $shifouchuangjianfenqu = y ] || [ $shifouchuangjianfenqu = Y ]
	#then
	#	while [[ $shifouqueredevname != [Yy] ]]
	#	do
	#		read -p "请输入硬盘全路径，比如/dev/sdb："  devname
	#		read -p "请务必确认硬盘路径是否为$devname，且该硬盘没有任何分区，如果输入错误将造成不可预知的问题[Y/N]：" shifouqueredevname
	#		fenqugeshu=`fdisk -l $devname|grep Linux|wc -l|awk '{print $1}'`
	#		if [ $fenqugeshu != 0 ] 
	#		then
	#			echo "该硬盘已有分区，无法实现再次划分。请重新选择分区"
	#			shifouqueredevname=n
	#		fi
	#	done
	#	if [ $muban = cl ]
	#	then
	#		#变动模板要改的地方
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
	#创建PV

	
	#创建vg
	

	
	
	
	#创建lv


}

###################硬盘区结束###########################

#############获取系统配置区，单独拿出来为了便于调试#########
X86=`uname -m`
XITONGTEMP=`uname`
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`  #系统类型
XTBANBEN=`cat /etc/issue|head -1|awk '{print $7}'`  #获取系统版本
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




#####################备机区############
huifu()
{
	SendAlarm "取消rsh的允许启动"
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

	SendAlarm "取消脚本的自启动"

	rm -rf /tmp/temp.sh

}
beijijianting1()
{
	echo "secbootok" > /tmp/bootok.txt
	tempflag=`nc -l $tongxinduankou1 </tmp/bootok.txt`
	if [ X$tempflag = Xkaishihdr ]
	then
		SendAlarm "主机开始搭建hdr"
		SendAlarm "已经启动备机监听1"
	  beijihuifu;
	  killall nc
	fi

}

#############安装区##########################
#判断是否已经将软件安装成功并重启，未重启过就正常安装改内核参数重启，重启过就进行下面的步骤。
anzhuang()
{

	startfdisk;

	if [ ! -d $idshome ]
	then
		echo "创建安装目录"
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
	SendAlarm  "请使用root账户进行安装"
	exit 0;
	fi
if [ ! -f $alreadyornolog ]
then
	touch $alreadyornolog
	SendAlarm "创建数据库编译标识文件$alreadyornolog"
	initflag=0
##############基础判断，不符合条件则无法启动脚本#############
	if [ X$X86 != Xx86_64 ]
	then
		SendAlarm "系统为32位版本，暂时不支持"
		exit 0;
	fi
	
	if [ ! -f /tmp/$jiaobenming ]
	then
		SendAlarm "请将本脚本放在/tmp文件夹下"
		exit 0;
	fi
	if [ ! -f /tmp/$anzhuangbao ]
	then
		SendAlarm "请将$anzhuangbao放到/tmp下";
		exit 0;
	fi
	
	FILEsize=`stat -c %s /tmp/$anzhuangbao`
	if [ X$FILEsize != X564142080 ]
	then
		SendAlarm "文件大小不正确，请核对后再进行，大小应为554557440字节";
		exit 0;
	fi


	if [ ! -h $lvrootdbs1 ]
	then
		SendAlarm "$lvrootdbs1 不存在，请先创建该lv"
		exit 0;
	fi
	if [ ! -h $lvtempdbs1 ]
	then
		SendAlarm "$lvtempdbs1 不存在，请先创建该lv"
		exit 0;
	fi
	if [ ! -h $lvtempdbs2 ]
	then
		SendAlarm "$lvtempdbs2 不存在，请先创建该lv"
		exit 0;
	fi
	if [ ! -h $lvlogdbs1 ]
	then
		SendAlarm "$lvlogdbs1 不存在，请先创建该lv"
		exit 0;
	fi
	if [ ! -h $lvphydbs1 ]
	then
		SendAlarm "$lvphydbs1 不存在，请先创建该lv"
		exit 0;
	fi
	if [ ! -h $lvuserdbs1 ]
	then
		SendAlarm "$lvuserdbs1 不存在，请先创建该lv"
		exit 0;
	fi
	
	if [ X$XTBANBEN != X5.9 ] && [ X$XTBANBEN != X6.0 ] && [ X$XTBANBEN != X6.1 ] && [ X$XTBANBEN != X6.2 ] && [ X$XTBANBEN != X6.3 ] && [ X$XTBANBEN != X6.4 ] && [ X$XTBANBEN != X6.5 ] && [ X$XTBANBEN != X6.6 ] && [ X$XTBANBEN != X6.7 ] && [ X$XTBANBEN != X6.8 ]
	then
		SendAlarm "系统版本暂不支持，请联系脚本开发人员"
		exit 0;
	fi

else
	initflag=`grep "alreadyinstall informix" $alreadyornolog|wc -l|awk '{print $1}'`
fi
if [ $initflag = 0 ]
then
	#用户是否存在，如果不存在就建立
	userexistflag=`grep informix /etc/passwd|wc -l|awk '{print $1}'`
	if [ X$userexistflag != X1 ]
	then
		#linux安装步骤
		if [ X$XITONG = XLINUX ]
		then
			SendAlarm "建立用户组"
			groupadd informix;
			SendAlarm "建立用户"
			useradd -g informix -d $informixhome informix;
			chown informix:informix $idshome
			passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
		fi
		#AIX安装步骤
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
		SendAlarm "创建安装目录"
		mkdir $idshome
	fi
	chown informix:informix $idshome
	INFORMIXDIR=$idshome
	export INFORMIXDIR
	
	
	#修改占位配置
	SendAlarm "修改占位符，以便后续步骤"

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
		SendAlarm "正在将脚本和安装包复制到备机，请手动输入密码（需要多次）"
		mkdir /tmp/scptempdir/
		cp /tmp/tempIFX12.sh /tmp/scptempdir/IFX12.sh
		mv /tmp/$anzhuangbao /tmp/scptempdir/
		scp -oPort=19222 -r /tmp/scptempdir/* root@$secip:/tmp/
		mv /tmp/scptempdir/$anzhuangbao /tmp/
		ssh -oPort=19222 root@$secip 'cd /tmp;nohup sh ./IFX12.sh anzhuang >/tmp/anzhuang.log 2>&1 &'
		echo "需要交互的内容结束，后面开始全自动安装，包括编译数据库，搭建HDR，请勿在安装过程中做任何操作"
		sleep 3;
	fi

	
	
	SendAlarm "移动安装包到安装目录"
	mv $anzhuangbao $idshome/
	cd $idshome;
	SendAlarm "解压安装包"
	tar -xvf  $idshome/$anzhuangbao -C $idshome/
	mv $idshome/$anzhuangbao /tmp
	SendAlarm "开始自动编译数据库"
	$idshome/ids_install <<EOF

1
/ids/
Y

1
2



EOF
	
	SendAlarm "编译完成"
	SendAlarm "修改内核参数"
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


	SendAlarm "检查内核参数写入是否正确"

	kernel_shmmaxok=`grep "kernel.shmmax = 4398046511104" /etc/sysctl.conf|wc -l`
	kernel_shmmniok=`grep "kernel.shmmni = 4096" /etc/sysctl.conf|wc -l`
	kernel_shmallok=`grep "kernel.shmall = 67108864" /etc/sysctl.conf|wc -l`
	kernel_semok=`grep "kernel.sem = 250 32000 32 4096" /etc/sysctl.conf|wc -l`
	if [ X$kernel_shmmaxok != X1 ] || [ X$kernel_shmmniok != X1 ] || [ X$kernel_shmallok != X1 ] || [ X$kernel_semok != X1 ]
	then
	SendAlarm "内核参数写入异常，请检查"
	exit 0;
	fi
	SendAlarm "写入内核数据更新标识"
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
	
	SendAlarm "创建dbfiles目录"
	mkdir $idshome/dbfiles
	chown informix:informix /$idshome/dbfiles
	chmod 775 /$idshome/dbfiles
	SendAlarm "创建连接文件中"
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
	
	SendAlarm "修改连接文件权限中"
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
		SendAlarm "增加启动修改权限配置"
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
	
	SendAlarm "增加5.9或者6.5的特定配置"
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
	
	SendAlarm "修改informix的环境变量配置文件"
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
	
	SendAlarm "写入.rhosts文件，如果有需要请自己修改.rhost文件，默认为+"
	echo '+' > /home/informix/.rhosts
	chown informix:informix /home/informix/.rhosts
	chmod 660 /home/informix/.rhosts
	
	SendAlarm "开始修改配置文件"
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
	SendAlarm "NETTYPE默认填写为soctcp,4,150,NET，如果有需求请自行修改"
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
	#正式版的数据配置
	tihuan "^BUFFERPOOL default.*" "BUFFERPOOL default,buffers=3000000,lrus=64,lru_min_dirty=0,lru_max_dirty=0.05";
	tihuan "^BUFFERPOOL size.*" " ";
	#测试原因，下面的配置太大，正式安装时再使用下面的而不是上面这条
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
		SendAlarm "更新/etc/hosts.equiv"
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
	SendAlarm "更新hosts文件"
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
	SendAlarm "生效内核参数"
	sysctl -p;
	#备机自动启配置
	if [ X$hdrflag = Xsec ]
	then
		SendAlarm "启动备机的rsh服务"
		tihuanbasic ".*disable.*" "        disable                 = no" /etc/xinetd.d/rsh
		echo "rsh" >> /etc/securetty
		/etc/rc.d/init.d/xinetd restart
		#echo "/etc/rc.d/init.d/xinetd start" >> /etc/rc.d/rc.local
		#SendAlarm "配置备机启动后监听服务"
		#echo "sh /tmp/IFX12.sh beijijianting1" >> /etc/rc.d/rc.local
		SendAlarm "等待主机搭建hdr"
		beijijianting1
	fi
	#主机自启动配置
	if [ X$hdrflag = Xpri ] || [ X$hdrflag = Xonly ]
	then
		#SendAlarm "主机加入自启动后执行初始化命令"
		#echo '#!/bin/sh' > /tmp/temp.sh
		#echo "su - informix -c '. /home/informix/.bash_profile;sh /tmp/IFX12.sh chushihua'" >>/tmp/temp.sh
		#echo "sh /tmp/temp.sh" >> /etc/rc.d/rc.local
		#chmod 777 /tmp/temp.sh
		SendAlarm "开始初始化"
		echo "su - informix -c '. /home/informix/.bash_profile;sh /tmp/tempIFX12.sh chushihua'" >/tmp/temp.sh
		chmod 777 /tmp/temp.sh
		
		
		vgname=`echo $lvrootdbs1 |awk -F'/' '{print $3}'`
		xiugai "^peizhiflag.*"                  "peizhiflag=0"


		chmod 777 /tmp/tempIFX12.sh
		chmod 777 /tmp/temp.sh
		sh /tmp/temp.sh
		
	fi
	#更新，直接生效系统内核，不在重启系统。
	#reboot;
fi


}
###################搭建hdr区###############333
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
	SendAlarm "开始零备并恢复备库"
	ontape -t STDIO -s -L 0 -F|rsh $secip "cd /home/informix;. ./.bash_profile ; ontape -t STDIO -p";
	sleep 5;
	SendAlarm "开始设置主备库状态"
	onmode -d primary $secINFORMIXSERVER;
	rsh $secip "cd /home/informix;. ./.bash_profile ; onmode -d secondary $priINFORMIXSERVER";
	sleep 1;
	SendAlarm "HDR搭建完成"
	while true
	do
	zhubeihdrokle=`echo "beijikaishihuifu"|nc $secip $tongxinduankou2`
		if [ X$zhubeihdrokle = Xbeijidengdaihuifu ]
		then
			SendAlarm "备机恢复rsh等设置"
			break;
		fi
	sleep 1;
	done;

}
#########################初始化区##############
#使用的前提是已经修改好sqlhosts文件和/etc/hosts.*文件
if [ $# = 1 ] && [ $1 = chushihua ]
then
	wai1=`whoami`
	if [ $wai1 != informix ]
	then
		echo "请用informix账户启动"
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
	SendAlarm "主备通信：等待备机安装完成。"
	if [ X$hdrflag != Xonly ]
	then
		while true
		do
			beijiqidongflag=`echo "kaishihdr"|nc $secip $tongxinduankou1`
				if [ X$beijiqidongflag = Xsecbootok ]
				then
					SendAlarm "主备通信：备机安装完成。开始搭建HDR"
					break;
				fi
			sleep 1;
		done;
		hdr
	fi
	if [ X$hdrflag = Xonly ]
	then
		onmode -m;
		SendAlarm "单机安装完成"
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
		echo "需要用root账户"
	fi
fi


if [ $# = 1 ] && [ $1 = anzhuang ]
then
	anzhuang
fi