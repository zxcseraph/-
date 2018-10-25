#!/bin/sh
set -x
#ssh��ʽ�hdr
#������$1����servername��$2����servername��$3����ip��$4����ip��$5ģ�壬$6Ϊhdr��ʽ��hdr��������only�ǵ�����$7dbs��ʽ��fsΪ�ļ�ϵͳ��lvΪ���豸��$8���$7Ϊlv�����������disk���Ʊ���/dev/sdb

#############�������������������ϸ�Ķ�##############
doDIR=/tmp
isinformixid=0								#�Ƿ�ָ��informix�û�id����id���ݲ�֧�֣�����û��
informixgroupid=200
informixuserid=200
informixhome=/home/informix		#informix��homeĿ¼
idshome=/ids									#�����װĿ¼
INFORMIXDIR=/ids
log=/ids/rizhi.log
alreadyornolog=/ids/instalready.log
anzhuangbao=Informix_Enterprise_12.10.FC8W1_LIN-x86_64_IFix.tar
jiaobenming=`echo $0|awk -F'/' '{print $NF}'`
tongxinduankou1=36925					#������ͨ�ŵĶ˿ڣ�ϵͳĬ�ϵ�36925����ռ�ã���������������ֶ����ġ�
tongxinduankou2=36926
tongxinduankou2=36927
vgname=informixvg
secpassword='1qaz@WSX'
shellname=`echo $0|awk -F'./' '{print $2}'`
#���Ա�־λ��1��Ϊ���������0��Ϊ��ʽ������
testflag=1
#�Ƿ�ȫ�ӹ̣�0��1��
anquan=1
#�Զ��޸�λ�����ڳ�ʼ��ʧ���Զ����³�ʼ����
autorepair=1
#�Ƿ�ʹ��rsh��־λ
rshflag=0






################log4s������#################
log4spath=$doDIR								#�����־Ŀ¼
log4sechoCategory=info				#�������Ļ��־�������ƣ�������debug=0��warn=1��info=2��error=3
log4swriteCategory=debug			#������ļ���־�������ƣ�������debug=0��warn=1��info=2��error=3
log4slogname=root.log					#�����־����
isecho=1											#�������־��ͬʱ�Ƿ��ӡ����Ļ��0�ǲ���ӡ��1�Ǵ�ӡ
splittype=none								#��־�ָʽ��none���ָday�������ڷָ��׺��ΪYYYY-MM-DD��numΪ������ģʽ�ָ���ʹ��numģʽ�������дsplitnum���������û˼·�ݲ�֧��
splitnum=1000

X86=`uname -m`
XITONGTEMP=`uname`
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`  #ϵͳ����
xtong=`echo $XITONG|tr '[A-Z]' '[a-z]'`
XTBANBEN=`lsb_release -a|grep Release|awk '{print $2}'`  #��ȡϵͳ�汾
tXTBB=$(echo $XTBANBEN |awk '{print $1*100}')
cpunumtemp=`cat /proc/cpuinfo|grep processor|wc -l`
let cpunum=cpunumtemp-1
mubanpara=("cl" "vpn" "ctx" "other" "test")
hdrtypepara=("hdr" "only")
dbstypepara=("fs" "lv")


################log4s����У�鲢��ʼ�����������ó�����Ϊ��ʼ��ֻ��Ҫһ��#############
log4scheck()
{
	if [ X$log4spath = X ]
	then
		echo "log4spath������Ҫ����"
		exit 1;
	fi
	if [ X$log4sechoCategory = X ]
	then
		echo "log4sechoCategory������Ҫ����"
		exit 1;
	fi
	if [ X$log4swriteCategory = X ]
	then
		echo "log4swriteCategory������Ҫ����"
		exit 1;
	fi
	if [ X$log4slogname = X ]
	then
		echo "log4slogname������Ҫ����"
		exit 1;
	fi
	if [ X$isecho = X ]
	then
		echo "isecho������Ҫ����"
		exit 1;
	fi
	if [ X$splittype = X ]
	then
		echo "splittype������Ҫ����"
		exit 1;
	fi
	if [ X$splittype = Xnum ]
	then
		if [ X$splitnum = X ]
		then
			echo "splitnum������Ҫ����"
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
################log4s������#################
log4slog=${log4spath}/${log4slogname}
log4scheck;
log4s()                       #$1�Ǽ���$2������
{
	nowdate=`date +"%Y-%m-%d %H:%M:%S"`
	######�ж����򣬱�֤�����Ͻ���
	#�ж�Ŀ¼����־�ļ������Զ�����Ŀ¼�����ǻ��Զ������ļ�
	if [ ! -d $log4spath ]
	then
		echo "$nowdate log4s���õ�Ŀ¼�����ڣ���ȷ�������Ƿ���ȷ"
		exit 1;
	fi
	if [ ! -f $log4slog ]
	then
		echo "log4s��־�����ڣ�����log4s��־�ļ�"
		echo "$nowdate log4s��־�����ڣ�����log4s��־�ļ�" >> $log4slog
		chmod 777 $log4slog
	fi
	
	#�жϲ�������
	if [ $# -ne 2 ]
	then
		echo "��������Ϊ2��"
		exit 1;
	fi
	log4sindex=0
	
	###�ָ���־��
	#���շָ�
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
	#�������ָ�
	if [ $splittype = num ]
	then
		if [ ! -f $log4slog ]
		then
			echo "��־�ļ������ڣ����������Ƿ���ȷ"
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

	######��������
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

#########################ռλ�������������޸�#########
#��������Ϊ��ʹ��informix�˻������ű�ʱ�ܻ��֮ǰ�����������Ϣ
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
		echo "����������������"
		exit 2;
	fi
fi
#############������������Ҫ��###############################
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


#�������ģ�壬ÿ�������������Σ�һ������$1Ϊ�����ȼ���ratio1����ratio2
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
	#�����������Ƿ���ȷ
	CheckIPAddr $priip
	if [ $? = 1 ]
	then
		log4s error "����ip $priip �Ƿ�"
		exit 2;
	fi
	CheckIPAddr $secip
	if [ $? = 1 ]
	then
		log4s error "����ip $secip �Ƿ�"
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
		log4s error "ģ����� ${muban} ����"
		exit 2;
	fi
	if [ X$hdrtype != Xhdr ] && [ X$hdrtype != Xonly ]
	then
		log4s error "hdr��ʽ ${hdrtype} ����"
		exit 2;
	fi
	if [ X$dbstype != Xfs ] && [ X$dbstype != Xonly ]
	then
		log4s error "dbs��ʽ ${dbstype} ����"
		exit 2;
	fi
}
###############Զ�̵�¼����������ִ�������Ҫ1��������1��ִ�е�����
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
fun_ftphost()#####��Ҫ�����˻�����IP��ַIPADDR���˻�����passwd
{
log4s info "��ʼ�ϴ�$1�����Լ����ű���$2"
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
log4s info "����ϴ�$1�����Լ����ű���$2"
}

tihuanbasic()
{
	sed "s#$1#$2#g" $3> $3.temp
	mv $3.temp $3
}
gai59()
{
	#����������$1λlvĿ¼����$lvrootdbs1��$2λlv�Ĵ�С
	if [ $2 != 0 ]
	then
		log4s debug "ENV{DM_NAME}==\"$1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\""
		echo "ENV{DM_NAME}==\"$1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
}
gai65()
{
	#3��������$1λ$vgname��$2��lv���Ʊ���rootdbs1��,3��lv�Ĵ�С
	if [ $3 != 0 ]
	then
		log4s debug "ENV{DM_VG_NAME}==\"$1\", ENV{DM_LV_NAME}==\"$2\", OWNER:=\"informix\", GROUP:=\"informix\""
		echo "ENV{DM_VG_NAME}==\"$1\", ENV{DM_LV_NAME}==\"$2\", OWNER:=\"informix\", GROUP:=\"informix\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
}
makeonspace()
{
	#onspaces -c -d logdbs -p /ids/dbfiles/logdbs1 -o 0 -s $sizelogdbs1;
	#$1��logdbs��$2��/ids/dbfiles/logdbs1��$3��$sizelogdbs1��$4�Ǿ�����-c -d ����-a
	if [ $3 != 0 ]
	then
		let onspacetempsize=$3*1000000
		if [ X$4 = Xc ]
		then
			log4s debug "��ʼ����dbspace  $1"
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
				log4s info "$1�����ɹ�"
			else
				log4s error "$1����ʧ��"
				exit 12;
			fi
		fi
		if [ X$4 = Xa ]
		then
			log4s debug "����dbspace  $1"
			onspaces -a $1 -p $2 -o 0 -s $onspacetempsize;
			onresult=$?
			sleep 3;
			if [ $onresult = 0 ]
			then
				log4s info "$1���ӳɹ�"
			else
				log4s error "$1����ʧ��"
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
	#ʹ���ļ�ϵͳ��ʱ���жϴ��̿ռ��Ƿ��㹻
	if [ $dbstype = fs ]
	then
		#�鿴dbfiles�ǹ��ع�����Ŀ¼���Ǿ���ֱ�Ӹ�Ŀ¼
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
				log4s error "���̿ռ䲻��"
				exit 3;
			else
				log4s info "��ǰģ��Ϊ${muban}�������ȼ�Ϊ2"
				return 0;
			fi
		else
			log4s info "��ǰģ��Ϊ${muban}�������ȼ�Ϊ1"
			return 0;
		fi
	elif [ $mubiao -gt $sizeG ] && [ $priorsec != secondary ]
	then
		log4s info "��ǰģ��Ϊ${muban}���ռ��㹻δ����"
		return 0;
	elif [ $mubiao -ge $sizeG ] && [ $priorsec = secondary ]
	then
		log4s error "��ǰΪ�������޷�ʹ�ú�������ͬ��Сdbs"
		exit 3;
	elif [ $mubiao -gt $sizeG ] && [ $priorsec = secondary ]
	then
		log4s info "��ǰΪ����������ʹ�ú�������ͬģ��"
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
		log4s info "�����Ǳ���������Ҫ�޸�ռλ��"
	fi
}
checklv()
{
	#��黮�ֵ�lv��С�Ƿ�������õ�ֵ�������Ƿ񻮷ֳɹ�
	#$1ΪlvĿ¼��$2Ϊ���õĴ�С
	if [ X$1 = X ] || [ X$2 = X ]
	then
		log4s debug "checklv���д��󣬵�һ������Ϊ��$1���ڶ�������Ϊ��$2"
	fi
	if [ X$2 != X0 ]
	then
		lvexist=`lvdisplay $1|grep 'LV Size'|wc -l|awk '{print $1}'`
		if [ X$lvexist != X1 ]
		then
			log4s error "$1������"
			exit 1;
		fi
		huafensize=`lvdisplay $1|grep 'LV Size'|awk '{print $3}'|awk -F'.' '{print $1}'`
		yaoqiusize=$2
		if [ $huafensize -ge $yaoqiusize ]
		then
			log4s debug "${1}��С����Ҫ��"
		else
			log4s error "�����dbs��СΪ$2������lv��СΪ$1��������Ҫ��"
			exit 1;
		fi
	else
		log4s debug "${1}�Ĵ�СΪ0������Ҫ������dbs�����Բ����"
	fi
}
makeln()
{
	#$1��Դ�ļ�Ҳ����lv��$2��Ҫ�����Ĵ�С��$3�������ļ�Ҳ����dbsfile�µ�
	if [ X$2 != X0 ]
	then
		ln -s $1 $3
		log4s info "����$3"
		if [ -L $3 ]
		then
			log4s info "���������ļ� $3 �ɹ�"
		else
			log4s error "���������ļ� $3 ʧ��"
			exit 8;
		fi
	fi
}
tihuan()
{
	log4s debug "��$peizhi�е�\"$1\" �޸�Ϊ \"$2\""
	tihuanbasic "$1" "$2" $peizhi
}
tihuanaao()
{
	log4s debug "��/ids/aaodir/adtcfg�е�\"$1\" �޸�Ϊ \"$2\""
	tihuanbasic "$1" "$2" /ids/aaodir/adtcfg
}
xiugai()
{
	log4s debug "��/tmp/tempIFX12.sh�е�\"$1\" �޸�Ϊ \"$2\""
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
	#$1ΪlvĿ¼��$2Ϊlv��С��$3Ϊlv����
	if [ X$1 = X0 ] || [ X$2 = X0 ] || [ X$3 = X0 ]
	then
		log4s info "��ǰdbs�����������Բ���Ҫ�ж�"
	else
		Plvsizegetsize=`lvdisplay $1|grep 'LV Size'|awk '{print $3}'|awk -F'.' '{print $1}'`
		if [ $Plvsizegetsize -lt $2 ]
		then
			log4s error "$3,���õ�lv�Ĵ�СΪ$Plvsizegetsize��С��Ҫ��Ĵ�С$2"
			exit 1;
		else
			log4s debug "$3,���õ�lv�Ĵ�СΪ$Plvsizegetsize������Ҫ��Ĵ�С$2������Ҫ��"
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
	#$1ΪҪ����pv��Ŀ¼
	pvisexist=`pvscan|grep "$1"|wc -l|awk '{print $1}'`
	if [ X$pvisexist = X0 ]
	then
		pvcreate $1 > $doDIR/makepv.temp
		getpvnum=`pvscan|grep $1|wc -l|awk '{print $1}'`
		getmakeresult=`grep -i successfully $doDIR/makepv.temp|wc -l|awk '{print $1}'`
		if [ X$getpvnum = X1 ] && [ X$getmakeresult = X1 ]
		then
			log4s info "pv�����ɹ�"
		else
			log4s error "pv����ʧ��"
			exit 5;
		fi
	else
		log4s error "pv�Ѿ����ڣ���ע�������Ƿ�����"
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
		log4s info "����vg�ɹ���vg����Ϊ$vgname"
	else
		log4s error "����vgʧ��"
		exit 6;
	fi
}
xiugaiscp()
{
	log4s debug "��$doDIR/scptemp/NFV_IDS_init.sh�е�\"$1\" �޸�Ϊ \"$2\""
	tihuanbasic "$1" "$2" $doDIR/scptemp/NFV_IDS_init.sh
}
xiugaipri()
{
	log4s debug "��$doDIR/tempNFV_IDS_init.sh�е�\"$1\" �޸�Ϊ \"$2\""
	tihuanbasic "$1" "$2" $doDIR/tempNFV_IDS_init.sh
}
makelv()
{
	#ʹ�÷����������һ��������lv�����ڶ���������С����ʽΪ1G��������������vg����
	if [ $2 != 0 ]
	then
		lvcreate -L ${2}G -n $1 $3 > $doDIR/makelv.temp
		getmakelvresult=`grep $1 $doDIR/makelv.temp|grep -i created|wc -l|awk '{print $1}'`
		if [ X$getmakelvresult = X1 ]
		then
			log4s info "$1�����ɹ�"
		else
			log4s error "$1����ʧ��"
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
			log4s info "${2} �����ɹ�"
		else
			log4s error "${2} ����ʧ��"
			exit 4;
		fi
	else
		log4s info "$2 Ԥ���СΪ $1 ���������贴��"
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
		log4s info "��ʼ����pv"
		makepv $devname
		makepvresult="$?"
		if [ "$makepvresult" = 0 ]
		then
			log4s info "����pv�ɹ�"
		else
			log4s error "����pvʧ�ܣ�ʧ�ܴ���Ϊ$makepvresult"
		fi
		log4s info "��ʼ����vg"
		makevg $vgname $devname
		makevgresult="$?"
		if [ "$makevgresult" = 0 ]
		then
			log4s info "����vg�ɹ�"
		else
			log4s error "����vgʧ�ܣ�ʧ�ܴ���Ϊ$makevgresult"
		fi
		log4s info "��ʼ����lv"
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
		log4s info "��ʼ����lv��dbfiles�µ������ļ�"
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
	
		log4s info "����5.9����6.5���ض�����"
		log4s info "ϵͳ�汾Ϊ$XTBANBEN"
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
	log4s info "�޸������ļ�Ȩ��"
	chown informix:informix $idshome/dbfiles/*
	chmod 660 $idshome/dbfiles/*
}
initshell()
{
	#����ת��Ϊ����
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
			#����ģ��
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
			#vpnģ��
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
			#testģ��
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
	#��װ����Ϊ��ʼ��֮ǰ���в�������������ɺ��޸�ռλ���������ű���������
	getdisksize
	if [ ! -d $idshome/dbfiles ]
	then
		mkdir $idshome/dbfiles
	else
		dbfnum=`ls $idshome/dbfiles|wc -l|awk '{print $1}'`
		if [ $dbfnum != 0 ] 
		then
			log4s error "$idshome/dbfilesĿ¼�����ļ�����ȷ���Ƿ�����"
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
		#�ͳ������������Ľű�
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
		
		#�ͳ���ʼ���ű�
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
	
	#�޸������ļ�
	log4s info "�޸�informix�Ļ������������ļ�"
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
	
	#�޸�rhosts
	log4s info "д��.rhosts�ļ����������Ҫ���Լ��޸�.rhost�ļ���Ĭ��Ϊ+"
	echo '+' > /home/informix/.rhosts
	chown informix:informix /home/informix/.rhosts
	chmod 660 /home/informix/.rhosts
	
	#�޸������ļ�
	log4s info "��ʼ�޸������ļ�"
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
		log4s info "����init��ɣ���ʼ֪ͨ����"
		if [ $rshflag = 1 ]
		then
			openrsh;
		fi
		
		datarecive $tongxinduankou1 "bei_ji_init_ok"
		log4s info "�����ȴ�hdr���ͬ��"
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
					log4s info "����hdr״̬��ɣ���ʼ�ָ�rsh״̬"
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
	log4s info "��ʼ��rsh����"
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
	#һ��������ɾ���߼���־�ĺ�
	onparams -d -l $1 <<EOF
y
EOF
		if [ $? = 0 ]
		then
			log4s info "ɾ���߼���־ $1 �ɹ�"
			onstat -l;
		else
			log4s error "ɾ���߼���־ $1 ʧ��"
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
		echo "����informix�˻�����"
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
		log4s info "�ȴ�ϵͳ�ⴴ�����"
		sleep 10;
		bulidsysmasterok=`grep "'sysmaster' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysadminok=`grep "'sysadmin' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysuserok=`grep "'sysuser' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysutilsok=`grep "'sysutils' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		let buildoknum=bulidsysmasterok+bulidsysadminok+bulidsysuserok+bulidsysutilsok
		let dengdainum=dengdainum+1
		if [ $dengdainum -gt 10 ]
		then
			log4s info "�ȴ�ʱ��������������������ݿ���������ϰ�װ�п��ܳ�ʼ���쳣����۲�online.log��־"
			log4s info "���ȷ��sysmaster��sysadmin��sysuser��sysutils���ĸ����ʼ���쳣��������ĳ����û�г�ʼ��"
			if [ $autorepair = 1 ]
			then
				tihuan "^FULL_DISK_INIT.*" "FULL_DISK_INIT  1"
				onmode -ky;
				log4s info "���online.log"
				>/home/informix/online.log
				log4s info "���³�ʼ�����ݿ�"
				oninit -ivy 
				dengdainum=0
			else
				log4s error "��ʼ��ʧ�ܣ����˹���Ԥ"
				exit 10;
			fi
		fi
	done
	chmod a+r $idshome/etc/sqlhosts
	log4s info "���ݿ��ʼ����ɣ���ʼ����dbs";
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
	#�˴��ǽ��߼���־�ƶ���������

	if [ $testflag = 1 ]
	then
		onstat -l;
	fi
	log4s debug "��ʼɾ���߼���־"
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
		log4s debug "�����߼���־����"

		onmode -l;
		onmode -c;
		
		onmode -l;
		onmode -c;
		
		onmode -l;
		onmode -c;
		
		onmode -l;
		onmode -c;
		#�˴�Ӧ���л���7
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
	
	log4s info "������װ��ɣ��ȴ�������װ����źš�"	
	zhujiwancheng=$(datasend $tongxinduankou1 "zhu_ji_init_ok" $secip "bei_ji_init_ok")
	log4s info "������װ��ɣ�׼����ʼ�hdr"
	
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
			log4s info "���Ϸ���Ԥ��"
			break;
		fi
		sleep 1;
	done	
}
makehdr()
{
	onmode -ky;
	oninit;
	log4s info "��ʼ�㱸���ָ�����"
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
				log4s info "�����ָ����"
				break;
			else
				log4s info "�ȴ������ָ����"
			fi
		done	
	fi


	
	log4s info "��ʼ����������״̬"
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
			log4s info "����hdr״̬����"
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
		echo "����informix�˻�����"
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