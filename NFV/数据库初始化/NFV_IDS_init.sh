#!/bin/sh
set -x
#ssh方式搭建hdr
#参数：$1主机servername，$2备机servername，$3主机ip，$4备机ip，$5模板，$6为hdr方式：hdr是主备；only是单机，$7dbs方式：fs为文件系统；lv为裸设备，$8如果$7为lv则这个参数是disk名称比如/dev/sdb

#############配置区，如需更改请仔细阅读##############
doDIR=/tmp
isinformixid=0								#是否指定informix用户id和组id，暂不支持，觉得没用
informixgroupid=200
informixuserid=200
informixhome=/home/informix		#informix的home目录
idshome=/ids									#软件安装目录
INFORMIXDIR=/ids
log=/ids/rizhi.log
alreadyornolog=/ids/instalready.log
anzhuangbao=Informix_Enterprise_12.10.FC8W1_LIN-x86_64_IFix.tar
jiaobenming=`echo $0|awk -F'/' '{print $NF}'`
tongxinduankou1=36925					#主备机通信的端口，系统默认的36925不被占用，如有特殊情况请手动更改。
tongxinduankou2=36926
tongxinduankou2=36927
vgname=informixvg
secpassword='1qaz@WSX'
shellname=`echo $0|awk -F'./' '{print $2}'`
#测试标志位，1则为测试配置项，0则为正式配置项
testflag=1
#是否安全加固，0否，1是
anquan=1
#自动修复位，用于初始化失败自动重新初始化的
autorepair=1
#是否使用rsh标志位
rshflag=0






################log4s配置区#################
log4spath=$doDIR								#输出日志目录
log4sechoCategory=info				#输出到屏幕日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4swriteCategory=debug			#输出到文件日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4slogname=root.log					#输出日志名称
isecho=1											#输出到日志的同时是否打印到屏幕，0是不打印，1是打印
splittype=none								#日志分割方式，none不分割，day按照日期分割后缀名为YYYY-MM-DD，num为按照行模式分割，如果使用num模式则必须填写splitnum参数，这个没思路暂不支持
splitnum=1000

X86=`uname -m`
XITONGTEMP=`uname`
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`  #系统类型
xtong=`echo $XITONG|tr '[A-Z]' '[a-z]'`
XTBANBEN=`lsb_release -a|grep Release|awk '{print $2}'`  #获取系统版本
tXTBB=$(echo $XTBANBEN |awk '{print $1*100}')
cpunumtemp=`cat /proc/cpuinfo|grep processor|wc -l`
let cpunum=cpunumtemp-1
mubanpara=("cl" "vpn" "ctx" "other" "test")
hdrtypepara=("hdr" "only")
dbstypepara=("fs" "lv")


################log4s配置校验并初始化区，单独拿出来是为初始化只需要一次#############
log4scheck()
{
	if [ X$log4spath = X ]
	then
		echo "log4spath参数需要配置"
		exit 1;
	fi
	if [ X$log4sechoCategory = X ]
	then
		echo "log4sechoCategory参数需要配置"
		exit 1;
	fi
	if [ X$log4swriteCategory = X ]
	then
		echo "log4swriteCategory参数需要配置"
		exit 1;
	fi
	if [ X$log4slogname = X ]
	then
		echo "log4slogname参数需要配置"
		exit 1;
	fi
	if [ X$isecho = X ]
	then
		echo "isecho参数需要配置"
		exit 1;
	fi
	if [ X$splittype = X ]
	then
		echo "splittype参数需要配置"
		exit 1;
	fi
	if [ X$splittype = Xnum ]
	then
		if [ X$splitnum = X ]
		then
			echo "splitnum参数需要配置"
			exit 1;
		fi
	fi
	log4sechoCategoryToU=`echo $log4sechoCategory|tr '[a-z]' '[A-Z]'`
	log4swriteCategoryToU=`echo $log4swriteCategory|tr '[a-z]' '[A-Z]'`

	case $log4sechoCategoryToU in
		DEBUG)
			log4sechoCategorylevel=0
			;;
		WARN)
			log4sechoCategorylevel=1
			;;
		INFO)
			log4sechoCategorylevel=2
			;;
		ERROR)
			log4sechoCategorylevel=3
			;;
		*)
			log4sechoCategorylevel=3
			;;
	esac
	case $log4swriteCategoryToU in
		DEBUG)
			log4swriteCategorylevel=0
			;;
		WARN)
			log4swriteCategorylevel=1
			;;
		INFO)
			log4swriteCategorylevel=2
			;;
		ERROR)
			log4swriteCategorylevel=3
			;;
		*)
			log4swriteCategorylevel=3
			;;
	esac
}
################log4s代码区#################
log4slog=${log4spath}/${log4slogname}
log4scheck;
log4s()                       #$1是级别，$2是内容
{
	nowdate=`date +"%Y-%m-%d %H:%M:%S"`
	######判断区域，保证参数严谨性
	#判断目录及日志文件，不自动创建目录，但是会自动创建文件
	if [ ! -d $log4spath ]
	then
		echo "$nowdate log4s配置的目录不存在，请确认配置是否正确"
		exit 1;
	fi
	if [ ! -f $log4slog ]
	then
		echo "log4s日志不存在，创建log4s日志文件"
		echo "$nowdate log4s日志不存在，创建log4s日志文件" >> $log4slog
		chmod 777 $log4slog
	fi
	
	#判断参数个数
	if [ $# -ne 2 ]
	then
		echo "参数个数为2个"
		exit 1;
	fi
	log4sindex=0
	
	###分割日志区
	#按日分割
	if [ $splittype = day ]
	then
		lastlineday=`tail -1 $log|awk  '{print $1}'`
		if [ X$lastlineday = X ]
		then
			lastlineday=`tail -2 $log|head -1|awk  '{print $1}'`
			if [ X$lastlineday = X ]
			then
				lastlineday=`tail -3 $log|head -1|awk  '{print $1}'`
			fi
		fi
		nowday=`echo $nowdate|awk '{print $1}'`
		if [ X$lastlineday != X$nowday ] && [ X$lastlineday != X ]
		then
			mv ${log4slog} ${log4slog}.$lastlineday
			touch $log4slog
		fi
	fi
	#按行数分割
	if [ $splittype = num ]
	then
		if [ ! -f $log4slog ]
		then
			echo "日志文件不存在，请检查配置是否正确"
			exit 1;
		fi
		lognum=`wc -l $log4slog|awk '{print $1}'`
		if [ $lognum -ge $splitnum ]
		then
			temptag=`date +"%Y%m%d%H%M%S"`
			mv ${log4slog} ${log4slog}.${temptag}
			touch $log4slog
		fi
	fi

	######功能区域
	log4sinlevel=`echo $1|tr '[a-z]' '[A-Z]'`
	case $log4sinlevel in
		DEBUG)
			log4snowlevel=0
			;;
		WARN)
			log4snowlevel=1
			;;
		INFO)
			log4snowlevel=2
			;;
		ERROR)
			log4snowlevel=3
			;;
		*)
			log4snowlevel=3
			;;
	esac
	if [ $log4snowlevel -ge $log4sechoCategorylevel ] && [ $isecho = 1 ]
	then
		echo "$2"
	fi
	if [ $log4snowlevel -ge $log4swriteCategorylevel ]
	then
		echo "$nowdate log4s.${log4sinlevel}   $2" >> $log4slog
	fi
}

#########################占位配置区，请勿修改#########
#该区域是为了使用informix账户启动脚本时能获得之前输入的配置信息
s_priservername=XXXXXX
s_secservername=XXXXXX
s_priip=XXXXXX
s_secip=XXXXXX
s_devname=XXXXXX
s_sizerootdbs1G=XXXXXX
s_sizetempdbs1G=XXXXXX
s_sizetempdbs2G=XXXXXX
s_sizelogdbs1G=XXXXXX
s_sizephydbs1G=XXXXXX
s_sizeuserdbs1G=XXXXXX
s_sizeuserdbs2G=XXXXXX
s_sizeuserdbs3G=XXXXXX
s_sizeuserdbs4G=XXXXXX
s_sizeuserdbs5G=XXXXXX
s_sizechargedbs1G=XXXXXX
s_sizechargedbs2G=XXXXXX
s_sizeminfodbs1G=XXXXXX
s_sizeminfodbs2G=XXXXXX
s_sizeservdbs1G=XXXXXX
s_sizeservdbs2G=XXXXXX
s_hdrtype=XXXXXX
s_dbstype=XXXXXX
s_muban=XXXXXX
s_priorsec=XXXXXX

if [ $s_priorsec = XXXXXX ]
then
	if [ $# != 7 ] && [ $# != 8 ] && [ $# != 1 ]
	then
		echo "启动参数个数不对"
		exit 2;
	fi
fi
#############基础函数，不要动###############################
SendAlarm()
{
	echo "$1";
	if [ ! -d $INFORMIXDIR ]
	then
		mkdir $INFORMIXDIR;
	fi
	if [ ! -f $log ]
	then
		touch $log;
	fi
	echo "$1" >> $log
}


#缩减后的模板，每个可以缩减两次，一个参数$1为缩减等级，ratio1或者ratio2
setmubanratio()
{
	
	if [ $1 = ratio1 ]
	then
		if [ $muban = cl ]
		then
			sizeuserdbs1G=20
			sizeuserdbs2G=20
			sizeuserdbs3G=0
			sizeuserdbs4G=0
			sizeuserdbs5G=0
			sizechargedbs1G=0
			sizechargedbs2G=0
			sizeminfodbs1G=0
			sizeminfodbs2G=0
			sizeservdbs1G=0
			sizeservdbs2G=0
		elif [ $muban = vpn ]
		then
			sizeuserdbs1G=20
			sizeuserdbs2G=20
			sizeuserdbs3G=0
			sizeuserdbs4G=0
			sizeuserdbs5G=0
			sizechargedbs1G=0
			sizechargedbs2G=0
			sizeminfodbs1G=0
			sizeminfodbs2G=0
			sizeservdbs1G=0
			sizeservdbs2G=0
		fi
	elif [ $1 = ratio2 ]
	then
		if [ $muban = cl ]
		then
			sizeuserdbs1G=10
			sizeuserdbs2G=0
			sizeuserdbs3G=0
			sizeuserdbs4G=0
			sizeuserdbs5G=0
			sizechargedbs1G=0
			sizechargedbs2G=0
			sizeminfodbs1G=0
			sizeminfodbs2G=0
			sizeservdbs1G=0
			sizeservdbs2G=0
		elif [ $muban = vpn ]
		then
			sizeuserdbs1G=10
			sizeuserdbs2G=0
			sizeuserdbs3G=0
			sizeuserdbs4G=0
			sizeuserdbs5G=0
			sizechargedbs1G=0
			sizechargedbs2G=0
			sizeminfodbs1G=0
			sizeminfodbs2G=0
			sizeservdbs1G=0
			sizeservdbs2G=0
		fi
	fi
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
checkinput()
{
	#检查输入参数是否正确
	CheckIPAddr $priip
	if [ $? = 1 ]
	then
		log4s error "主机ip $priip 非法"
		exit 2;
	fi
	CheckIPAddr $secip
	if [ $? = 1 ]
	then
		log4s error "备机ip $secip 非法"
		exit 2;
	fi
	mubanpipei=0
	for i in ${mubanpara[*]}; do
		if [ $i = $muban ]
		then
			let mubanpipei=mubanpipei+1
		fi
	done
	if [ $mubanpipei = 0 ]
	then
		log4s error "模板参数 ${muban} 错误"
		exit 2;
	fi
	if [ X$hdrtype != Xhdr ] && [ X$hdrtype != Xonly ]
	then
		log4s error "hdr方式 ${hdrtype} 错误"
		exit 2;
	fi
	if [ X$dbstype != Xfs ] && [ X$dbstype != Xonly ]
	then
		log4s error "dbs方式 ${dbstype} 错误"
		exit 2;
	fi
}
###############远程登录其他主机并执行命令，需要1个参数，1：执行的命令
fun_srcgo()
{
/usr/local/bin/expect <<-EOF
set timeout 5
spawn ssh -p 19222 root@$secip
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*password:" { send "$secpassword\r" }
}
expect {
"*>" {}
"*]" {}
}
send "$1\r"
expect {
"*>" {}
"*]" {}
}
send "sleep 2\r"
expect {
"*>" {}
"*]" {}
}
send "exit\r"
expect eof
EOF
}
fun_ftphost()#####需要参数账户名，IP地址IPADDR，账户密码passwd
{
log4s info "开始上传$1代码以及本脚本至$2"
srcFile=`ls $1/*`
for file in $srcFile
do
file=${file//\[/\\\[}
file=${file//\]/\\\]}
/usr/local/bin/expect <<-EOF
set timeout 60
spawn scp -oPort=19222 -r $file $1@$2:./
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*password:" { send "$3\r" }
}
expect eof
EOF
done
/usr/local/bin/expect <<-EOF
set timeout 60
spawn scp -oPort=19222 -r $0 $1@$2:./
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*password:" { send "$3\r" }
}
expect eof
EOF
log4s info "完成上传$1代码以及本脚本至$2"
}

tihuanbasic()
{
	sed "s#$1#$2#g" $3> $3.temp
	mv $3.temp $3
}
gai59()
{
	#两个参数，$1位lv目录比如$lvrootdbs1，$2位lv的大小
	if [ $2 != 0 ]
	then
		log4s debug "ENV{DM_NAME}==\"$1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\""
		echo "ENV{DM_NAME}==\"$1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
}
gai65()
{
	#3个参数，$1位$vgname，$2是lv名称比如rootdbs1，,3是lv的大小
	if [ $3 != 0 ]
	then
		log4s debug "ENV{DM_VG_NAME}==\"$1\", ENV{DM_LV_NAME}==\"$2\", OWNER:=\"informix\", GROUP:=\"informix\""
		echo "ENV{DM_VG_NAME}==\"$1\", ENV{DM_LV_NAME}==\"$2\", OWNER:=\"informix\", GROUP:=\"informix\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
}
makeonspace()
{
	#onspaces -c -d logdbs -p /ids/dbfiles/logdbs1 -o 0 -s $sizelogdbs1;
	#$1是logdbs，$2是/ids/dbfiles/logdbs1，$3是$sizelogdbs1，$4是决定是-c -d 还是-a
	if [ $3 != 0 ]
	then
		let onspacetempsize=$3*1000000
		if [ X$4 = Xc ]
		then
			log4s debug "开始创建dbspace  $1"
			onsapcetempflag=`echo $1|grep temp|wc -l|awk '{print $1}'`
			if [ X$onsapcetempflag = X0 ]
			then
				onspaces -c -d $1 -p $2 -o 0 -s $onspacetempsize;
				onresult=$?
			else
				onspaces -c -d $1 -t -p $2 -o 0 -s $onspacetempsize;
				onresult=$?
			fi
			sleep 3;
			if [ $onresult = 0 ]
			then
				log4s info "$1创建成功"
			else
				log4s error "$1创建失败"
				exit 12;
			fi
		fi
		if [ X$4 = Xa ]
		then
			log4s debug "增加dbspace  $1"
			onspaces -a $1 -p $2 -o 0 -s $onspacetempsize;
			onresult=$?
			sleep 3;
			if [ $onresult = 0 ]
			then
				log4s info "$1增加成功"
			else
				log4s error "$1增加失败"
				exit 12;
			fi
		fi
	fi
}
sizesum()
{
	list=$@
	sizesumnum=0
	for i in `echo $list`
	do
	sizesumnum=$((sizesumnum+i))
	done
}
getdisksize()
{
	#使用文件系统的时候判断磁盘空间是否足够
	if [ $dbstype = fs ]
	then
		#查看dbfiles是挂载过来的目录还是就是直接根目录
		if [ -d /ids/dbfiles ]
		then
			sizek=`df -Pk /ids/dbfiles|tail -1|awk '{print $4}'`
		elif [ -d /ids ]
		then
			sizek=`df -Pk /ids|tail -1|awk '{print $4}'`
		else
			sizek=`df -Pk /|tail -1|awk '{print $4}'`
		fi
		let sizeG=sizek/1024
	fi
	if [ $dbstype = lv ]
	then
		sizeG=`fdisk -l $devname|head -2|tail -1|awk -F',' '{print $1}'|awk -F':' '{print $2}'|awk '{print $1}'|awk -F'.' '{print $1}'`
	fi
	let mubiao=sizerootdbs1G+sizetempdbs1G+sizetempdbs2G+sizelogdbs1G+sizephydbs1G+sizeuserdbs1G+sizeuserdbs2G+sizeuserdbs3G+sizeuserdbs4G+sizeuserdbs5G+sizechargedbs1G+sizechargedbs2G+sizeminfodbs1G+sizeminfodbs2G+sizeservdbs1G+sizeservdbs2G
	if [ $mubiao -ge $sizeG ] && [ $priorsec != secondary ]
	then
		setmubanratio ratio1
		let mubiao=sizerootdbs1G+sizetempdbs1G+sizetempdbs2G+sizelogdbs1G+sizephydbs1G+sizeuserdbs1G+sizeuserdbs2G+sizeuserdbs3G+sizeuserdbs4G+sizeuserdbs5G+sizechargedbs1G+sizechargedbs2G+sizeminfodbs1G+sizeminfodbs2G+sizeservdbs1G+sizeservdbs2G
		if [ $mubiao -ge $sizeG ]
		then
			setmubanratio ratio2
			let mubiao=sizerootdbs1G+sizetempdbs1G+sizetempdbs2G+sizelogdbs1G+sizephydbs1G+sizeuserdbs1G+sizeuserdbs2G+sizeuserdbs3G+sizeuserdbs4G+sizeuserdbs5G+sizechargedbs1G+sizechargedbs2G+sizeminfodbs1G+sizeminfodbs2G+sizeservdbs1G+sizeservdbs2G
			if [ $mubiao -ge $sizeG ]
			then
				log4s error "磁盘空间不足"
				exit 3;
			else
				log4s info "当前模板为${muban}，缩减等级为2"
				return 0;
			fi
		else
			log4s info "当前模板为${muban}，缩减等级为1"
			return 0;
		fi
	elif [ $mubiao -gt $sizeG ] && [ $priorsec != secondary ]
	then
		log4s info "当前模板为${muban}，空间足够未缩减"
		return 0;
	elif [ $mubiao -ge $sizeG ] && [ $priorsec = secondary ]
	then
		log4s error "当前为备机，无法使用和主机相同大小dbs"
		exit 3;
	elif [ $mubiao -gt $sizeG ] && [ $priorsec = secondary ]
	then
		log4s info "当前为备机，可以使用和主机相同模板"
		return 0;
	fi
}
ZhanWeiflag()
{
	if [ $priorsec = primary ]
	then
		s_priservername=$priservername
		s_secservername=$secservername
		s_priip=$priip
		s_secip=$secip
		s_muban=$muban
		s_hdrtype=$hdrtype
		s_dbstype=$dbstype
		s_devname=$devname
		s_priorsec=secondary
		s_sizerootdbs1G=$sizerootdbs1G
		s_sizetempdbs1G=$sizetempdbs1G
		s_sizetempdbs2G=$sizetempdbs2G
		s_sizelogdbs1G=$sizelogdbs1G
		s_sizephydbs1G=$sizephydbs1G
		s_sizeuserdbs1G=$sizeuserdbs1G
		s_sizeuserdbs2G=$sizeuserdbs2G
		s_sizeuserdbs3G=$sizeuserdbs3G
		s_sizeuserdbs4G=$sizeuserdbs4G
		s_sizeuserdbs5G=$sizeuserdbs5G
		s_sizechargedbs1G=$sizechargedbs1G
		s_sizechargedbs2G=$sizechargedbs2G
		s_sizeminfodbs1G=$sizeminfodbs1G
		s_sizeminfodbs2G=$sizeminfodbs2G
		s_sizeservdbs1G=$sizeservdbs1G
		s_sizeservdbs2G=$sizeservdbs2G
	else
		log4s info "这里是备机，不需要修改占位符"
	fi
}
checklv()
{
	#检查划分的lv大小是否符合设置的值，或者是否划分成功
	#$1为lv目录，$2为设置的大小
	if [ X$1 = X ] || [ X$2 = X ]
	then
		log4s debug "checklv运行错误，第一个参数为：$1，第二个参数为：$2"
	fi
	if [ X$2 != X0 ]
	then
		lvexist=`lvdisplay $1|grep 'LV Size'|wc -l|awk '{print $1}'`
		if [ X$lvexist != X1 ]
		then
			log4s error "$1不存在"
			exit 1;
		fi
		huafensize=`lvdisplay $1|grep 'LV Size'|awk '{print $3}'|awk -F'.' '{print $1}'`
		yaoqiusize=$2
		if [ $huafensize -ge $yaoqiusize ]
		then
			log4s debug "${1}大小符合要求"
		else
			log4s error "输入的dbs大小为$2，但是lv大小为$1，不符合要求"
			exit 1;
		fi
	else
		log4s debug "${1}的大小为0，不需要创建该dbs，所以不检查"
	fi
}
makeln()
{
	#$1是源文件也就是lv，$2是要创建的大小，$3是连接文件也就是dbsfile下的
	if [ X$2 != X0 ]
	then
		ln -s $1 $3
		log4s info "创建$3"
		if [ -L $3 ]
		then
			log4s info "创建连接文件 $3 成功"
		else
			log4s error "创建连接文件 $3 失败"
			exit 8;
		fi
	fi
}
tihuan()
{
	log4s debug "将$peizhi中的\"$1\" 修改为 \"$2\""
	tihuanbasic "$1" "$2" $peizhi
}
tihuanaao()
{
	log4s debug "将/ids/aaodir/adtcfg中的\"$1\" 修改为 \"$2\""
	tihuanbasic "$1" "$2" /ids/aaodir/adtcfg
}
xiugai()
{
	log4s debug "将/tmp/tempIFX12.sh中的\"$1\" 修改为 \"$2\""
	tihuanbasic "$1" "$2" /tmp/tempIFX12.sh
}
Pstr()
{
	Pstrtmp1=`echo $1|sed s#[[:space:]]##g`
	Pstrtmp2=`echo $Pstrtmp1|wc -L|awk '{print $1}'`
	WPstrtmp1=`echo $1|wc -L|awk '{print $1}'`
	if [ X$Pstrtmp2 = X$WPstrtmp1 ]
	then
		echo "ok"
	else
		echo "no"
	fi
}

Pip()
{
	tPiptmp1=`echo $1|sed s#[[:digit:]]##g`
	Piptmp1=`echo $tPiptmp1|sed s#[[:space:]]##g`
	Piptmp2=`echo $Piptmp1|wc -L|awk '{print $1}'`
	if [ X$Piptmp2 = X3 ]
	then
		echo "ok"
	else
		echo "no"
	fi
}

Pnum()
{
	Pnumtmp1=`echo $1|sed s#[[:space:]]##g`
	Pnumtmp2=`echo $Pnumtmp1|sed s#[[:digit:]]##g`
	Pnumold1=`echo $1|wc -L|awk '{print $1}'`
	Pnumold2=`echo $Pnumtmp1|wc -L|awk '{print $1}'`
	Pnumnew=`echo $Pnumtmp2|wc -L|awk '{print $1}'`
	if [ X$Pnumold1 = X$Pnumold2 ] && [ X0 = X$Pnumnew ] && [ XPnumold1 != X0 ]
	then
		echo "ok"
	else
		echo "no"
	fi
}

Plvsize()
{
	#$1为lv目录，$2为lv大小，$3为lv名称
	if [ X$1 = X0 ] || [ X$2 = X0 ] || [ X$3 = X0 ]
	then
		log4s info "当前dbs不建立，所以不需要判断"
	else
		Plvsizegetsize=`lvdisplay $1|grep 'LV Size'|awk '{print $3}'|awk -F'.' '{print $1}'`
		if [ $Plvsizegetsize -lt $2 ]
		then
			log4s error "$3,设置的lv的大小为$Plvsizegetsize，小于要求的大小$2"
			exit 1;
		else
			log4s debug "$3,设置的lv的大小为$Plvsizegetsize，大于要求的大小$2，符合要求"
		fi
	fi
}
Rset0()
{
	if [ X$1 = X ] || [ X$1 = XN ] || [ X$1 = Xn ] || [ X$1 = X0 ]
	then
		$2=0
	fi
}
makepv()
{
	#$1为要创建pv的目录
	pvisexist=`pvscan|grep "$1"|wc -l|awk '{print $1}'`
	if [ X$pvisexist = X0 ]
	then
		pvcreate $1 > $doDIR/makepv.temp
		getpvnum=`pvscan|grep $1|wc -l|awk '{print $1}'`
		getmakeresult=`grep -i successfully $doDIR/makepv.temp|wc -l|awk '{print $1}'`
		if [ X$getpvnum = X1 ] && [ X$getmakeresult = X1 ]
		then
			log4s info "pv创建成功"
		else
			log4s error "pv创建失败"
			exit 5;
		fi
	else
		log4s error "pv已经存在，请注意输入是否正常"
		exit 5;
	fi
}

makevg()
{
	vgcreate $1 $2 > $doDIR/makevg.temp
	getvgnum=`vgdisplay|grep "$vgname"|wc -l|awk '{print $1}'`
	getmakevgresult=`grep -i successfully $doDIR/makevg.temp|wc -l|awk '{print $1}'`
	if [ X$getvgnum = X1 ] && [ X$getmakevgresult = X1 ]
	then
		log4s info "创建vg成功，vg名称为$vgname"
	else
		log4s error "创建vg失败"
		exit 6;
	fi
}
xiugaiscp()
{
	log4s debug "将$doDIR/scptemp/NFV_IDS_init.sh中的\"$1\" 修改为 \"$2\""
	tihuanbasic "$1" "$2" $doDIR/scptemp/NFV_IDS_init.sh
}
xiugaipri()
{
	log4s debug "将$doDIR/tempNFV_IDS_init.sh中的\"$1\" 修改为 \"$2\""
	tihuanbasic "$1" "$2" $doDIR/tempNFV_IDS_init.sh
}
makelv()
{
	#使用方法，传入第一个参数是lv名，第二个参数大小（格式为1G），第三个参数vg名称
	if [ $2 != 0 ]
	then
		lvcreate -L ${2}G -n $1 $3 > $doDIR/makelv.temp
		getmakelvresult=`grep $1 $doDIR/makelv.temp|grep -i created|wc -l|awk '{print $1}'`
		if [ X$getmakelvresult = X1 ]
		then
			log4s info "$1创建成功"
		else
			log4s error "$1创建失败"
			exit 7;
		fi
	fi

}
makefsdbs()
{
	if [ $1 != 0 ]
	then
		touch $2
		if [ $? = 0 ]
		then
			log4s info "${2} 创建成功"
		else
			log4s error "${2} 创建失败"
			exit 4;
		fi
	else
		log4s info "$2 预设大小为 $1 ，所以无需创建"
	fi
}
makedbfiles()
{
	if [ $dbstype = fs ]
	then
		makefsdbs  $sizetempdbs1G     $idshome/dbfiles/tempdbs1      
		makefsdbs  $sizetempdbs2G     $idshome/dbfiles/tempdbs2      
		makefsdbs  $sizelogdbs1G      $idshome/dbfiles/logdbs1       
		makefsdbs  $sizephydbs1G      $idshome/dbfiles/phydbs1       
		makefsdbs  $sizeuserdbs1G     $idshome/dbfiles/userdbs1      
		makefsdbs  $sizeuserdbs2G     $idshome/dbfiles/userdbs2      
		makefsdbs  $sizeuserdbs3G     $idshome/dbfiles/userdbs3      
		makefsdbs  $sizeuserdbs4G     $idshome/dbfiles/userdbs4      
		makefsdbs  $sizeuserdbs5G     $idshome/dbfiles/userdbs5      
		makefsdbs  $sizechargedbs1G   $idshome/dbfiles/chargedbs1    
		makefsdbs  $sizechargedbs2G   $idshome/dbfiles/chargedbs2    
		makefsdbs  $sizeminfodbs1G    $idshome/dbfiles/minfodbs1     
		makefsdbs  $sizeminfodbs2G    $idshome/dbfiles/minfodbs2     
		makefsdbs  $sizeservdbs1G     $idshome/dbfiles/servdbs1      
		makefsdbs  $sizeservdbs2G     $idshome/dbfiles/servdbs2      
	elif [ $dbstype = lv ]
	then
		log4s info "开始创建pv"
		makepv $devname
		makepvresult="$?"
		if [ "$makepvresult" = 0 ]
		then
			log4s info "创建pv成功"
		else
			log4s error "创建pv失败，失败代码为$makepvresult"
		fi
		log4s info "开始创建vg"
		makevg $vgname $devname
		makevgresult="$?"
		if [ "$makevgresult" = 0 ]
		then
			log4s info "创建vg成功"
		else
			log4s error "创建vg失败，失败代码为$makevgresult"
		fi
		log4s info "开始创建lv"
		lvrootdbs1=/dev/$vgname/rootdbs1
		lvtempdbs1=/dev/$vgname/tempdbs1
		lvtempdbs2=/dev/$vgname/tempdbs2
		lvlogdbs1=/dev/$vgname/logdbs1
		lvphydbs1=/dev/$vgname/phydbs1
		lvuserdbs1=/dev/$vgname/userdbs1
		lvuserdbs2=/dev/$vgname/userdbs2
		lvuserdbs3=/dev/$vgname/userdbs3
		lvuserdbs4=/dev/$vgname/userdbs4
		lvuserdbs5=/dev/$vgname/userdbs5
		lvchargedbs1=/dev/$vgname/chargedbs1
		lvchargedbs2=/dev/$vgname/chargedbs2
		lvminfodbs1=/dev/$vgname/minfodbs1
		lvminfodbs2=/dev/$vgname/minfodbs2
		lvservdbs1=/dev/$vgname/servdbs1
		lvservdbs2=/dev/$vgname/servdbs2
		makelv rootdbs1			$sizerootdbs1G		$vgname
		makelv tempdbs1			$sizetempdbs1G		$vgname
		makelv tempdbs2			$sizetempdbs2G		$vgname
		makelv logdbs1			$sizelogdbs1G		$vgname
		makelv phydbs1			$sizephydbs1G		$vgname
		makelv userdbs1			$sizeuserdbs1G		$vgname
		makelv userdbs2			$sizeuserdbs2G		$vgname
		makelv userdbs3			$sizeuserdbs3G		$vgname
		makelv userdbs4			$sizeuserdbs4G		$vgname
		makelv userdbs5			$sizeuserdbs5G		$vgname
		makelv chargedbs1		$sizechargedbs1G	$vgname
		makelv chargedbs2		$sizechargedbs2G	$vgname
		makelv minfodbs1		$sizeminfodbs1G		$vgname
		makelv minfodbs2		$sizeminfodbs2G		$vgname
		makelv servdbs1			$sizeservdbs1G		$vgname
		makelv servdbs2			$sizeservdbs2G		$vgname
		log4s info "开始创建lv到dbfiles下的连接文件"
		makeln $lvrootdbs1      $sizerootdbs1G      $idshome/dbfiles/rootdbs1   
		makeln $lvtempdbs1      $sizetempdbs1G      $idshome/dbfiles/tempdbs1   
		makeln $lvtempdbs2      $sizetempdbs2G      $idshome/dbfiles/tempdbs2   
		makeln $lvlogdbs1       $sizelogdbs1G       $idshome/dbfiles/logdbs1    
		makeln $lvphydbs1       $sizephydbs1G       $idshome/dbfiles/phydbs1    
		makeln $lvuserdbs1      $sizeuserdbs1G      $idshome/dbfiles/userdbs1   
		makeln $lvuserdbs2      $sizeuserdbs2G      $idshome/dbfiles/userdbs2   
		makeln $lvuserdbs3      $sizeuserdbs3G      $idshome/dbfiles/userdbs3   
		makeln $lvuserdbs4      $sizeuserdbs4G      $idshome/dbfiles/userdbs4   
		makeln $lvuserdbs5      $sizeuserdbs5G      $idshome/dbfiles/userdbs5   
		makeln $lvchargedbs1    $sizechargedbs1G    $idshome/dbfiles/chargedbs1 
		makeln $lvchargedbs2    $sizechargedbs2G    $idshome/dbfiles/chargedbs2 
		makeln $lvminfodbs1     $sizeminfodbs1G     $idshome/dbfiles/minfodbs1  
		makeln $lvminfodbs2     $sizeminfodbs2G     $idshome/dbfiles/minfodbs2  
		makeln $lvservdbs1      $sizeservdbs1G      $idshome/dbfiles/servdbs1   
		makeln $lvservdbs2      $sizeservdbs2G      $idshome/dbfiles/servdbs2   
	
		log4s info "增加5.9或者6.5的特定配置"
		log4s info "系统版本为$XTBANBEN"
		if [ $tXTBB -ge 590 ] && [ $tXTBB -le 650 ]
		then
			gai59   $lvrootdbs1       $sizerootdbs1G
			gai59   $lvtempdbs1       $sizetempdbs1G
			gai59   $lvtempdbs2       $sizetempdbs2G
			gai59   $lvlogdbs1        $sizelogdbs1G
			gai59   $lvphydbs1        $sizephydbs1G
			gai59   $lvuserdbs1       $sizeuserdbs1G
			gai59   $lvuserdbs2       $sizeuserdbs2G
			gai59   $lvuserdbs3       $sizeuserdbs3G
			gai59   $lvuserdbs4       $sizeuserdbs4G
			gai59   $lvuserdbs5       $sizeuserdbs5G
			gai59   $lvchargedbs1     $sizechargedbs1G
			gai59   $lvchargedbs2     $sizechargedbs2G
			gai59   $lvminfodbs1      $sizeminfodbs1G
			gai59   $lvminfodbs2      $sizeminfodbs2G
			gai59   $lvservdbs1       $sizeservdbs1G
			gai59   $lvservdbs2       $sizeservdbs2G
		fi
		if [ $tXTBB -gt 650 ] && [ $tXTBB -le 720 ]
		then
			gai65  $vgname  rootdbs1       $sizerootdbs1G
			gai65  $vgname  tempdbs1       $sizetempdbs1G
			gai65  $vgname  tempdbs2       $sizetempdbs2G
			gai65  $vgname  logdbs1        $sizelogdbs1G
			gai65  $vgname  phydbs1        $sizephydbs1G
			gai65  $vgname  userdbs1       $sizeuserdbs1G
			gai65  $vgname  userdbs2       $sizeuserdbs2G
			gai65  $vgname  userdbs3       $sizeuserdbs3G
			gai65  $vgname  userdbs4       $sizeuserdbs4G
			gai65  $vgname  userdbs5       $sizeuserdbs5G
			gai65  $vgname  chargedbs1     $sizechargedbs1G
			gai65  $vgname  chargedbs2     $sizechargedbs2G
			gai65  $vgname  minfodbs1      $sizeminfodbs1G
			gai65  $vgname  minfodbs2      $sizeminfodbs2G
			gai65  $vgname  servdbs1       $sizeservdbs1G
			gai65  $vgname  servdbs2       $sizeservdbs2G
		fi
	fi
	log4s info "修改连接文件权限"
	chown informix:informix $idshome/dbfiles/*
	chmod 660 $idshome/dbfiles/*
}
initshell()
{
	#参数转换为变量
	chown informix:informix $idshome
	if [ $s_priorsec = XXXXXX ]
	then
		priservername=`echo "$1"|tr '[A-Z]' '[a-z]'`
		secservername=`echo "$2"|tr '[A-Z]' '[a-z]'`
		priip=$3
		secip=$4
		muban=`echo "$5"|tr '[A-Z]' '[a-z]'`
		hdrtype=`echo "$6"|tr '[A-Z]' '[a-z]'`
		dbstype=`echo "$7"|tr '[A-Z]' '[a-z]'`
		devname=$8
		priorsec=primary
	fi
	if [ $s_priorsec = secondary ]
	then
		priservername=$s_priservername
		secservername=$s_secservername
		priip=$s_priip
		secip=$s_secip
		muban=$s_muban
		hdrtype=$s_hdrtype
		dbstype=$s_dbstype
		devname=$s_devname
		priorsec=secondary
	fi

	if [ testflag = 1 ]
	then
		muban=test
	fi
	
	if [ $priorsec = primary ]
	then
		if [ X$muban = Xcl ]
		then
			#彩铃模板
			sizerootdbs1G=4
			sizetempdbs1G=4
			sizetempdbs2G=4
			sizelogdbs1G=4
			sizephydbs1G=4
			sizeuserdbs1G=50
			sizeuserdbs2G=50
			sizeuserdbs3G=0
			sizeuserdbs4G=0
			sizeuserdbs5G=0
			sizechargedbs1G=0
			sizechargedbs2G=0
			sizeminfodbs1G=0
			sizeminfodbs2G=0
			sizeservdbs1G=0
			sizeservdbs2G=0
		elif [ X$muban = Xvpn ]
		then
			#vpn模板
			sizerootdbs1G=4
			sizetempdbs1G=4
			sizetempdbs2G=4
			sizelogdbs1G=4
			sizephydbs1G=4
			sizeuserdbs1G=50
			sizeuserdbs2G=50
			sizeuserdbs3G=0
			sizeuserdbs4G=0
			sizeuserdbs5G=0
			sizechargedbs1G=0
			sizechargedbs2G=0
			sizeminfodbs1G=0
			sizeminfodbs2G=0
			sizeservdbs1G=0
			sizeservdbs2G=0
		elif [ X$muban = Xtest ]
		then
			#test模板
			sizerootdbs1G=2
			sizetempdbs1G=2
			sizetempdbs2G=2
			sizelogdbs1G=2
			sizephydbs1G=2
			sizeuserdbs1G=4
			sizeuserdbs2G=4
			sizeuserdbs3G=0
			sizeuserdbs4G=0
			sizeuserdbs5G=0
			sizechargedbs1G=0
			sizechargedbs2G=0
			sizeminfodbs1G=0
			sizeminfodbs2G=0
			sizeservdbs1G=0
			sizeservdbs2G=0
		else
			setmubanratio
		fi
	elif [ $priorsec = secondary ]
	then
		sizerootdbs1G=$s_sizerootdbs1G
		sizetempdbs1G=$s_sizetempdbs1G
		sizetempdbs2G=$s_sizetempdbs2G
		sizelogdbs1G=$s_sizelogdbs1G
		sizephydbs1G=$s_sizephydbs1G
		sizeuserdbs1G=$s_sizeuserdbs1G
		sizeuserdbs2G=$s_sizeuserdbs2G
		sizeuserdbs3G=$s_sizeuserdbs3G
		sizeuserdbs4G=$s_sizeuserdbs4G
		sizeuserdbs5G=$s_sizeuserdbs5G
		sizechargedbs1G=$s_sizechargedbs1G
		sizechargedbs2G=$s_sizechargedbs2G
		sizeminfodbs1G=$s_sizeminfodbs1G
		sizeminfodbs2G=$s_sizeminfodbs2G
		sizeservdbs1G=$s_sizeservdbs1G
		sizeservdbs2G=$s_sizeservdbs2G
	fi
}
anzhuang()
{
	#安装部分为初始化之前所有操作，，操作完成后修改占位符，并将脚本传给备机
	getdisksize
	if [ ! -d $idshome/dbfiles ]
	then
		mkdir $idshome/dbfiles
	else
		dbfnum=`ls $idshome/dbfiles|wc -l|awk '{print $1}'`
		if [ $dbfnum != 0 ] 
		then
			log4s error "$idshome/dbfiles目录下有文件，请确认是否有用"
			exit 13;
		fi
	fi
	chown informix:informix $idshome/dbfiles
	chmod 660 $idshome/dbfiles
	makedbfiles
	if [ $priorsec = primary ]
	then
		ONCONFIG=onconfig.${priservername}
		INFORMIXSERVER=${priservername}
		#释出拷贝给备机的脚本
		mkdir $doDIR/scptemp 1>/dev/null 2>&1

		cp $doDIR/NFV_IDS_init.sh $doDIR/scptemp/
		xiugaiscp  "^s_priservername=XXXXXX" 	 "s_priservername=$priservername"
		xiugaiscp  "^s_secservername=XXXXXX" 	 "s_secservername=$secservername"
		xiugaiscp  "^s_priip=XXXXXX" 					 "s_priip=$priip"
		xiugaiscp  "^s_secip=XXXXXX" 					 "s_secip=$secip"
		xiugaiscp  "^s_muban=XXXXXX" 					 "s_muban=$muban"
		xiugaiscp  "^s_hdrtype=XXXXXX" 				 "s_hdrtype=$hdrtype"
		xiugaiscp  "^s_dbstype=XXXXXX" 				 "s_dbstype=$dbstype"
		xiugaiscp  "^s_devname=XXXXXX" 				 "s_devname=$devname"
		xiugaiscp  "^s_priorsec=XXXXXX" 			 "s_priorsec=secondary"
		xiugaiscp "^s_sizerootdbs1G=XXXXXX"     "s_sizerootdbs1G=$sizerootdbs1G"
		xiugaiscp "^s_sizetempdbs1G=XXXXXX"     "s_sizetempdbs1G=$sizetempdbs1G"
		xiugaiscp "^s_sizetempdbs2G=XXXXXX"     "s_sizetempdbs2G=$sizetempdbs2G"
		xiugaiscp "^s_sizelogdbs1G=XXXXXX"      "s_sizelogdbs1G=$sizelogdbs1G"
		xiugaiscp "^s_sizephydbs1G=XXXXXX"      "s_sizephydbs1G=$sizephydbs1G"
		xiugaiscp "^s_sizeuserdbs1G=XXXXXX"     "s_sizeuserdbs1G=$sizeuserdbs1G"
		xiugaiscp "^s_sizeuserdbs2G=XXXXXX"     "s_sizeuserdbs2G=$sizeuserdbs2G"
		xiugaiscp "^s_sizeuserdbs3G=XXXXXX"     "s_sizeuserdbs3G=$sizeuserdbs3G"
		xiugaiscp "^s_sizeuserdbs4G=XXXXXX"     "s_sizeuserdbs4G=$sizeuserdbs4G"
		xiugaiscp "^s_sizeuserdbs5G=XXXXXX"     "s_sizeuserdbs5G=$sizeuserdbs5G"
		xiugaiscp "^s_sizechargedbs1G=XXXXXX"   "s_sizechargedbs1G=$sizechargedbs1G"
		xiugaiscp "^s_sizechargedbs2G=XXXXXX"   "s_sizechargedbs2G=$sizechargedbs2G"
		xiugaiscp "^s_sizeminfodbs1G=XXXXXX"    "s_sizeminfodbs1G=$sizeminfodbs1G"
		xiugaiscp "^s_sizeminfodbs2G=XXXXXX"    "s_sizeminfodbs2G=$sizeminfodbs2G"
		xiugaiscp "^s_sizeservdbs1G=XXXXXX"     "s_sizeservdbs1G=$sizeservdbs1G"
		xiugaiscp "^s_sizeservdbs2G=XXXXXX"     "s_sizeservdbs2G=$sizeservdbs2G"
		chmod 777 $doDIR/scptemp
		chmod 777 $doDIR/scptemp/*
		chown informix:informix $doDIR/scptemp/*
		
		#释出初始化脚本
		cp $doDIR/NFV_IDS_init.sh $doDIR/tempNFV_IDS_init.sh
		xiugaipri  "^s_priservername=XXXXXX" 		"s_priservername=$priservername"
		xiugaipri  "^s_secservername=XXXXXX" 		"s_secservername=$secservername"
		xiugaipri  "^s_priip=XXXXXX" 						"s_priip=$priip"
		xiugaipri  "^s_secip=XXXXXX" 						"s_secip=$secip"
		xiugaipri  "^s_muban=XXXXXX" 						"s_muban=$muban"
		xiugaipri  "^s_hdrtype=XXXXXX" 					"s_hdrtype=$hdrtype"
		xiugaipri  "^s_dbstype=XXXXXX" 					"s_dbstype=$dbstype"
		xiugaipri  "^s_devname=XXXXXX" 					"s_devname=$devname"
		xiugaipri  "^s_priorsec=XXXXXX" 				"s_priorsec=primary"
		xiugaipri "^s_sizerootdbs1G=XXXXXX"     "s_sizerootdbs1G=$sizerootdbs1G"
		xiugaipri "^s_sizetempdbs1G=XXXXXX"     "s_sizetempdbs1G=$sizetempdbs1G"
		xiugaipri "^s_sizetempdbs2G=XXXXXX"     "s_sizetempdbs2G=$sizetempdbs2G"
		xiugaipri "^s_sizelogdbs1G=XXXXXX"      "s_sizelogdbs1G=$sizelogdbs1G"
		xiugaipri "^s_sizephydbs1G=XXXXXX"      "s_sizephydbs1G=$sizephydbs1G"
		xiugaipri "^s_sizeuserdbs1G=XXXXXX"     "s_sizeuserdbs1G=$sizeuserdbs1G"
		xiugaipri "^s_sizeuserdbs2G=XXXXXX"     "s_sizeuserdbs2G=$sizeuserdbs2G"
		xiugaipri "^s_sizeuserdbs3G=XXXXXX"     "s_sizeuserdbs3G=$sizeuserdbs3G"
		xiugaipri "^s_sizeuserdbs4G=XXXXXX"     "s_sizeuserdbs4G=$sizeuserdbs4G"
		xiugaipri "^s_sizeuserdbs5G=XXXXXX"     "s_sizeuserdbs5G=$sizeuserdbs5G"
		xiugaipri "^s_sizechargedbs1G=XXXXXX"   "s_sizechargedbs1G=$sizechargedbs1G"
		xiugaipri "^s_sizechargedbs2G=XXXXXX"   "s_sizechargedbs2G=$sizechargedbs2G"
		xiugaipri "^s_sizeminfodbs1G=XXXXXX"    "s_sizeminfodbs1G=$sizeminfodbs1G"
		xiugaipri "^s_sizeminfodbs2G=XXXXXX"    "s_sizeminfodbs2G=$sizeminfodbs2G"
		xiugaipri "^s_sizeservdbs1G=XXXXXX"     "s_sizeservdbs1G=$sizeservdbs1G"
		xiugaipri "^s_sizeservdbs2G=XXXXXX"     "s_sizeservdbs2G=$sizeservdbs2G"
		chmod 777 $doDIR/tempNFV_IDS_init.sh
		
	fi
	if [ $priorsec = secondary ]
	then
		ONCONFIG=onconfig.${secservername}
		INFORMIXSERVER=${secservername}
	fi
	
	#修改配置文件
	log4s info "修改informix的环境变量配置文件"
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
		. /home/informix/$bashprofile
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
		. /home/informix/$bashprofile
	fi
	
	#修改rhosts
	log4s info "写入.rhosts文件，如果有需要请自己修改.rhost文件，默认为+"
	echo '+' > /home/informix/.rhosts
	chown informix:informix /home/informix/.rhosts
	chmod 660 /home/informix/.rhosts
	
	#修改配置文件
	log4s info "开始修改配置文件"
	peizhi=$idshome/etc/$ONCONFIG
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
	tihuan "^MULTIPROCESSOR 0" "MULTIPROCESSOR 1";
	tihuan "^VPCLASS cpu,num=1,noage" "VPCLASS cpu,num=${cpunum},noage";
	tihuan "^LOCKS 20000" "LOCKS 200000";
	tihuan "^SHMVIRTSIZE 32656" "SHMVIRTSIZE 500000";
	tihuan "^SHMADD 8192" "SHMADD 80000";
	tihuan "^CKPTINTVL 300" "CKPTINTVL 30";
	tihuan "^TAPEDEV /dev/tapedev" "TAPEDEV /dev/null";
	tihuan "^TAPEBLK 32" "TAPEBLK 128";
	tihuan "^ALARMPROGRAM.*" "ALARMPROGRAM $idshome/etc/alarmprogram.sh"
	tihuan "^LTAPEDEV.*" "LTAPEDEV /dev/null"
	tihuan "^BAR_ACT_LOG \$INFORMIXDIR/tmp/bar_act.log" "BAR_ACT_LOG /home/informix/bar_act.log";
	tihuan "^OPTCOMPIND 2" "OPTCOMPIND 0";
	tihuan "^DRAUTO                  0" "DRAUTO                  2";
	tihuan "^DUMPDIR \$INFORMIXDIR/tmp" "DUMPDIR /home/informix/tmp";
	tihuan "^DUMPSHMEM 1" "DUMPSHMEM 0";
	tihuan "^CLEANERS.*" "CLEANERS 16";
	tihuan "^LOGBUFF.*"  "LOGBUFF 128"
	if [ $anquan = 1 ]
	then
		tihuan "^LISTEN_TIMEOUT.*" "LISTEN_TIMEOUT 10";
		#tihuanaao "^ADTMODE.*" "ADTMODE 7"
	fi
	if [ $testflag = 1 ]
	then
		tihuan "^BUFFERPOOL default.*" "BUFFERPOOL default,buffers=300000,lrus=64,lru_min_dirty=0,lru_max_dirty=0.05";
		tihuan "^BUFFERPOOL size.*" "";
	else
		tihuan "^BUFFERPOOL default.*" "BUFFERPOOL default,buffers=3000000,lrus=64,lru_min_dirty=0,lru_max_dirty=0.05";
		tihuan "^BUFFERPOOL size.*" "";
	fi
	chown informix:informix $peizhi
	echo "$priservername     onsoctcp     $priip       7778" >> $idshome/etc/sqlhosts
	echo "$secservername     onsoctcp     $secip      7778" >> $idshome/etc/sqlhosts
	chown informix:informix $idshome/etc/sqlhosts
	chown informix:informix $idshome/etc/*
	chmod a+r $idshome/etc/sqlhosts
	
	if [ -f /etc/hosts.equiv ]
	then
		eq1=`grep "$priservername" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		if [ X$eq1 != X1 ]
		then
			echo "priservername" >> /etc/hosts.equiv
		fi
		eq2=`grep "$secservername" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		if [ X$eq2 != X1 ]
		then
			echo "secservername" >> /etc/hosts.equiv
		fi
		eq3=`grep "+" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		if [ X$eq3 != X1 ]
		then
			echo "+" >> /etc/hosts.equiv
		fi
	else
		echo "$priservername" >> /etc/hosts.equiv
		echo "$secservername" >> /etc/hosts.equiv
	fi
	chown informix:informix /ids
	chown informix:informix /ids/dbfiles
	chown informix:informix $peizhi
	chown informix:informix /ids/etc/*
	
	chmod 775 /ids
	chmod 775 /ids/dbfiles
	chmod 660 /ids/dbfiles/*
	chmod 660 $peizhi
	chmod 660 /ids/etc/sqlhosts
	
	if [ $priorsec = primary ]
	then
		lftp -u root,${secpassword} sftp://$secip:19222 <<-EOF
		mkdir $doDIR
		cd $doDIR
		put scptemp/NFV_IDS_init.sh
		EOF
		fun_srcgo "cd $doDIR;nohup sh ./NFV_IDS_init.sh $priservername $secservername $priip $secip $muban $hdrtype $dbstype $devname &"
		su - informix -c ". ./.bash_profile;cd /tmp;sh ./tempNFV_IDS_init.sh chushihua"
	fi
	if [ $priorsec = secondary ]
	then
		log4s info "备机init完成，开始通知主机"
		if [ $rshflag = 1 ]
		then
			openrsh;
		fi
		
		datarecive $tongxinduankou1 "bei_ji_init_ok"
		log4s info "备机等待hdr完成同步"
		while true
		do
			sechdrokflag1='Read-Only'
			sechdrokflag2='(Sec)'
			sechdrokflag3='on'
			sechdrokcommand1=`onstat -g dri|grep "IBM Informix Dynamic Server Version"|awk  '{print $8}'`
			sechdrokcommand2=`onstat -g dri|grep "IBM Informix Dynamic Server Version"|awk  '{print $9}'`
			sechdrokcommand3=`onstat -g dri|sed -n ':n;/Type/{n;p;}'|awk '{print $3}'`
			if [ X$sechdrokflag1 = X$sechdrokcommand1 ] && [ X$sechdrokflag2 = X$sechdrokcommand2 ] && [ X$sechdrokflag3 = X$sechdrokcommand3 ]
			then
				datarecive $tongxinduankou2 "bei_ji_hdr_ok"
				
				if [ $rshflag = 1 ]
				then
					log4s info "备机hdr状态完成，开始恢复rsh状态"
					closersh;
				fi
				break;
			fi
			sleep 1;
		done
	fi
	
}
openrsh()
{
	log4s info "开始打开rsh配置"
	echo "rsh" >> /etc/securetty
	if [ ! -f /etc/xinetd.d/rsh ]
	then
		cat <<EOF >/etc/xinetd.d/rsh
service shell
{
        socket_type             = stream
        wait                    = no
        user                    = root
        log_on_success          += USERID
        log_on_failure          += USERID
        server                  = /usr/sbin/in.rshd
        disable                 = no
}
EOF
	else
		tihuanbasic ".*disable.*" "        disable                 = no" /etc/xinetd.d/rsh
	fi
	/etc/rc.d/init.d/xinetd restart
}
closersh()
{
	tihuanbasic "rsh" "" /etc/securetty
	tihuanbasic ".*disable.*" "        disable                 = yes" /etc/xinetd.d/rsh
	/etc/rc.d/init.d/xinetd restart
}
delonparams()
{
	#一个参数，删除逻辑日志的号
	onparams -d -l $1 <<EOF
y
EOF
		if [ $? = 0 ]
		then
			log4s info "删除逻辑日志 $1 成功"
			onstat -l;
		else
			log4s error "删除逻辑日志 $1 失败"
			exit 14;
		fi
	if [ $testflag = 1 ]
	then
		onstat -l;
	fi
}

chushihua()
{
	wai1=`whoami`
	if [ $wai1 != informix ]
	then
		echo "请用informix账户启动"
		exit 11;
	fi
	priservername=$s_priservername
	secservername=$s_secservername
	priip=$s_priip
	secip=$s_secip
	muban=$s_muban
	hdrtype=$s_hdrtype
	dbstype=$s_dbstype
	devname=$s_devname
	sizerootdbs1G=$s_sizerootdbs1G
	sizetempdbs1G=$s_sizetempdbs1G
	sizetempdbs2G=$s_sizetempdbs2G
	sizelogdbs1G=$s_sizelogdbs1G
	sizephydbs1G=$s_sizephydbs1G
	sizeuserdbs1G=$s_sizeuserdbs1G
	sizeuserdbs2G=$s_sizeuserdbs2G
	sizeuserdbs3G=$s_sizeuserdbs3G
	sizeuserdbs4G=$s_sizeuserdbs4G
	sizeuserdbs5G=$s_sizeuserdbs5G
	sizechargedbs1G=$s_sizechargedbs1G
	sizechargedbs2G=$s_sizechargedbs2G
	sizeminfodbs1G=$s_sizeminfodbs1G
	sizeminfodbs2G=$s_sizeminfodbs2G
	sizeservdbs1G=$s_sizeservdbs1G
	sizeservdbs2G=$s_sizeservdbs2G
	chmod 775 $idshome;
	chmod 775 $idshome/dbfiles;
	
	oninit -ivy;
	bulidsysmasterok=`grep "'sysmaster' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysadminok=`grep "'sysadmin' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysuserok=`grep "'sysuser' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysutilsok=`grep "'sysutils' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	let buildoknum=bulidsysmasterok+bulidsysadminok+bulidsysuserok+bulidsysutilsok
	dengdainum=0
	while [ $buildoknum -lt 4 ]
	do
		log4s info "等待系统库创建完成"
		sleep 10;
		bulidsysmasterok=`grep "'sysmaster' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysadminok=`grep "'sysadmin' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysuserok=`grep "'sysuser' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysutilsok=`grep "'sysutils' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		let buildoknum=bulidsysmasterok+bulidsysadminok+bulidsysuserok+bulidsysutilsok
		let dengdainum=dengdainum+1
		if [ $dengdainum -gt 10 ]
		then
			log4s info "等待时间过长，可能是由于数据库在虚拟机上安装有可能初始化异常，请观察online.log日志"
			log4s info "如果确定sysmaster，sysadmin，sysuser，sysutils，四个库初始化异常，或者有某个库没有初始化"
			if [ $autorepair = 1 ]
			then
				tihuan "^FULL_DISK_INIT.*" "FULL_DISK_INIT  1"
				onmode -ky;
				log4s info "清空online.log"
				>/home/informix/online.log
				log4s info "重新初始化数据库"
				oninit -ivy 
				dengdainum=0
			else
				log4s error "初始化失败，请人工干预"
				exit 10;
			fi
		fi
	done
	chmod a+r $idshome/etc/sqlhosts
	log4s info "数据库初始化完成，开始增加dbs";
	makeonspace   tempdbs1      $idshome/dbfiles/tempdbs1       $sizetempdbs1G     c
	makeonspace   tempdbs2      $idshome/dbfiles/tempdbs2       $sizetempdbs2G     c
	makeonspace   logdbs        $idshome/dbfiles/logdbs1        $sizelogdbs1G      c
	makeonspace   phydbs        $idshome/dbfiles/phydbs1        $sizephydbs1G      c
	makeonspace   userdbs       $idshome/dbfiles/userdbs1       $sizeuserdbs1G     c
	makeonspace   userdbs       $idshome/dbfiles/userdbs2       $sizeuserdbs2G     a
	makeonspace   userdbs       $idshome/dbfiles/userdbs3       $sizeuserdbs3G     a
	makeonspace   userdbs       $idshome/dbfiles/userdbs4       $sizeuserdbs4G     a
	makeonspace   userdbs       $idshome/dbfiles/userdbs5       $sizeuserdbs5G     a
	makeonspace   chargedbs     $idshome/dbfiles/chargedbs1     $sizechargedbs1G   c
	makeonspace   chargedbs     $idshome/dbfiles/chargedbs2     $sizechargedbs2G   a
	makeonspace   minfodbs      $idshome/dbfiles/minfodbs1      $sizeminfodbs1G    c
	makeonspace   minfodbs      $idshome/dbfiles/minfodbs2      $sizeminfodbs2G    a
	makeonspace   servdbs       $idshome/dbfiles/servdbs1       $sizeservdbs1G     c
	makeonspace   servdbs       $idshome/dbfiles/servdbs2       $sizeservdbs2G     a
	ontape -s -L 0;
	sleep 10;
	onmode -sy;
	ontape -s -L 0;
	if [ $testflag = 1 ]
	then
		onstat -l;
	fi
	onmode -l;
	onmode -c;
	
	onmode -l;
	onmode -c;
	
	onmode -l;
	onmode -c;
	#此处是将逻辑日志移动到第三个

	if [ $testflag = 1 ]
	then
		onstat -l;
	fi
	log4s debug "开始删除逻辑日志"
	delonparams 1;
	delonparams 2;
	delonparams 3;
	ontape -s -L 0
	let Msizelogdbs1=sizelogdbs1G*1000
	let numofllog=Msizelogdbs1/200
	let beginnumofllog=numofllog-2
	tempi=1
	pnumofllog=`Pnum "$Msizelogdbs1"`
	pbeginnumofllog=`Pnum "$beginnumofllog"`
	if [ $pnumofllog = ok ] && [ $pbeginnumofllog = ok ]
	then
		while [ $tempi -le $beginnumofllog ]
		do
			onparams -a -d logdbs -s 200000;
			let tempi=tempi+1
			ontape -s -L 0;
		done
		log4s debug "增加逻辑日志结束"

		onmode -l;
		onmode -c;
		
		onmode -l;
		onmode -c;
		
		onmode -l;
		onmode -c;
		
		onmode -l;
		onmode -c;
		#此处应该切换到7
		delonparams 4;
		delonparams 5;
		delonparams 6;
		
	else
	for i in {1..36}
	do
		onparams -a -d logdbs -s 200000;
		let i+=1

	done
	onmode -l;
	onmode -c;
	onparams -d -l 3 <<EOF
y
EOF
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
	onmode -l;
	onmode -c;
	onmode -l;
	onmode -c;
	onmode -l;
	onmode -c;
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
	fi

	let physize=sizephydbs1*95/100
	onparams -p -s $physize -d phydbs -y;
	ontape -s -L 0;
	
	log4s info "主机安装完成：等待备机安装完成信号。"	
	zhujiwancheng=$(datasend $tongxinduankou1 "zhu_ji_init_ok" $secip "bei_ji_init_ok")
	log4s info "备机安装完成，准备开始搭建hdr"
	
	makehdr;
}

datarecive()
{
	jiantingduankou=$1
	recsend=$2
	recivesendfile=$doDIR/rec.send.temp
	reciverecfile=$doDIR/rec.rec.temp
	echo $2 > $recivesendfile
	>$reciverecfile
	nc -l $jiantingduankou <${recivesendfile} >${reciverecfile}
	returntemp=`tail -1 $reciverecfile`
	echo "$returntemp"
}
datasend()
{
	fasongduankou=$1
	sendsend=$2
	ncip=$3
	yuqi=$4
	sendsendfile=$doDIR/send.send.temp
	sendrecfile=$doDIR/send.rec.temp
	echo $2 > $sendsendfile
	>$sendrecfile
	while true
	do
		tail -1 $sendsendfile |nc $ncip $fasongduankou >$sendrecfile
		returntemp=`tail -1 $sendrecfile`
		if [ X$returntemp = X$yuqi ]
		then
			echo "$returntemp"
			log4s info "符合返回预期"
			break;
		fi
		sleep 1;
	done	
}
makehdr()
{
	onmode -ky;
	oninit;
	log4s info "开始零备并恢复备库"
	if [ $rshflag = 1 ]
	then
		ontape -t STDIO -s -L 0 -F|rsh $secip "cd /home/informix;. ./.bash_profile ; ontape -t STDIO -p";
		sleep 5;
	else
		touch $idshome/priarchive
		ontape -t STDIO -s -L 0 -F >$idshome/priarchive
		lftp -u root,${secpassword} sftp://$secip:19222 <<-EOF
cd $idshome
put $idshome/priarchive
EOF
		fun_srcgo "su - informix -c 'ontape -t STDIO -p<$idshome/priarchive'"
		secrestorokflag=0
		sleep 20;
		while [ $secrestorokflag != 1 ]
		do
			sleep 5;
			fun_srcgo "su - informix -c 'onstat -g dri'" >$doDIR/seconstat.log
			fun_srcgo "cat /home/informix/online.log" >$doDIR/seconline.log
			secrestorokflagt1=`grep "IBM Informix" $doDIR/seconstat.log|grep "Fast Recovery"|wc -l|awk '{print $1}'`
			secrestorokflagt2=`grep "Physical Restore" $doDIR/seconline.log|grep Completed|wc -l|awk '{print $1}'`
			if [ $secrestorokflagt1 = 1 ] && [ $secrestorokflagt2 -ge 1 ]
			then
				secrestorokflag=1
				log4s info "备机恢复完成"
				break;
			else
				log4s info "等待备机恢复完成"
			fi
		done	
	fi


	
	log4s info "开始设置主备库状态"
	onmode -d primary $secservername;
	if [ $rshflag = 1 ]
	then
		rsh $secip "cd /home/informix;. ./.bash_profile ; onmode -d secondary $priservername";
	else
		fun_srcgo "su - informix -c 'onmode -d secondary $priservername'"
	fi
	
	sleep 1;

	while true
	do
		prihdrokflag1='on'
		prihdrokcommand=`onstat -g dri|sed -n ':n;/Type/{n;p;}'|awk '{print $2}'`
		if [ X$prihdrokflag1 = X$prihdrokcommand ]
		then
			beijihdrok=$(datasend $tongxinduankou2 "zhu_ji_hdr_ok" $secip "bei_ji_hdr_ok")
			log4s info "主机hdr状态正常"
			break
		fi
		sleep 1;
	done
	exit 66;
}
qingli()
{
	wai1=`whoami`
	if [ $wai1 != root ]
	then
		echo "请用informix账户启动"
		exit 11;
	fi

	su - informix -c ". ./.bash_profile;onmode -ky"
	vgremove informixvg <<-EOF
	y
	y
	y
	y
	y
	y
	y
	y
	y
	y
	y
	y
	y
	y
	y
	y
	y
	EOF
	
	if [ -f /tmp/tempNFV_IDS_init.sh ]
	then
		rmpvname=`grep "^s_devname" tempNFV_IDS_init.sh|awk -F'=' '{print $2}'`
		pvremove $rmpvname
	else
		rmpvname=`grep "^s_devname" NFV_IDS_init.sh|awk -F'=' '{print $2}'`
		pvremove $rmpvname
		if [ $rshflag = 1 ]
		then
			closersh
		fi
		
	fi


	rm -rf /ids/dbfiles
	>/ids/etc/sqlhosts
	if [ X$XITONG = XLINUX ]
	then
		bashprofile="/home/informix/.bash_profile"
		sed -i "/^INFORMIXDIR/d" $bashprofile
		sed -i "/^PATH=\$PATH:\$INFORMIXDIR/d" $bashprofile
		sed -i "/^INFORMIXSERVER=/d" $bashprofile
		sed -i "/^ONCONFIG=/d" $bashprofile
		sed -i "/^export.INFORMIXDIR/d" $bashprofile
		sed -i "/^INFORMIXCONTIME=2/d" $bashprofile
		sed -i "/^INFORMIXCONRETRY=1/d" $bashprofile
		sed -i "/^export.INFORMIXCONTIME/d" $bashprofile
	fi
	
	rm -rf /etc/udev/rules.d/93-application-devices.rules
}
if [ $# = 7 ] || [ $# = 8 ]
then
	initshell $1 $2 $3 $4 $5 $6 $7 $8;
	anzhuang;
fi
if [ $# = 1 ] && [ $1 = qingli ]
then
	qingli
fi
if [ $# = 1 ] && [ $1 = chushihua ]
then
	chushihua
fi