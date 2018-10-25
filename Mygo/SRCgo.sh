#!/bin/bash

################log4s������#################
log4spath=`pwd`								#�����־Ŀ¼
log4sCategory=debug					#�����־�������ƣ�������debug=0��warn=1��info=2��error=3
logs4logname=root.log					#�����־����
isecho=0											#�������־��ͬʱ�Ƿ��ӡ����Ļ��0�ǲ���ӡ��1�Ǵ�ӡ
splittype=none								#��־�ָʽ��none���ָday�������ڷָ��׺��ΪYYYY-MM-DD��numΪ������ģʽ�ָ���ʹ��numģʽ�������дsplitnum���������û˼·�ݲ�֧��
splitnum=1000
sshport=19222

################log4s����У�鲢��ʼ�����������ó�����Ϊ��ʼ��ֻ��Ҫһ��#############
log4scheck()
{
	if [ X$log4spath = X ]
	then
		echo "log4spath������Ҫ����"
		exit 1;
	fi
	if [ X$log4sCategory = X ]
	then
		echo "log4sCategory������Ҫ����"
		exit 1;
	fi
	if [ X$logs4logname = X ]
	then
		echo "logs4logname������Ҫ����"
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
	log4sCategoryToU=`echo $log4sCategory|tr '[a-z]' '[A-Z]'`
	case $log4sCategoryToU in
		DEBUG)
			log4sCategorylevel=0
			;;
		WARN)
			log4sCategorylevel=1
			;;
		INFO)
			log4sCategorylevel=2
			;;
		ERROR)
			log4sCategorylevel=3
			;;
		*)
			log4sCategorylevel=3
			;;
	esac
}
################log4s������#################
log4slog=${log4spath}/${logs4logname}
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
		echo "$nowdate $logname�����ڣ�����log4s��־�ļ�"
		echo "$nowdate $logname�����ڣ�����log4s��־�ļ�" >> $log4slog
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
	if [ $log4snowlevel -ge $log4sCategorylevel ]
	then
		if [ $isecho = 1 ]
		then
			echo "$nowdate log4s.${log4sinlevel}   $2"
		fi
		echo "$nowdate log4s.${log4sinlevel}   $2" >> $log4slog
	fi
}


X86=`uname -m`
XITONG=`echo $(uname)|tr '[a-z]' '[A-Z]'`  #ϵͳ����
xtong=`echo $(uname)|tr '[A-Z]' '[a-z]'`
XTBANBEN=`cat /etc/issue|head -1|awk '{print $7}'`  #��ȡϵͳ�汾
tXTBB=$(echo $XTBANBEN |awk '{print $1*100}')

if [ $# = 0 ]
then
	echo "������Ҫ������install�����а�װ��������������ϸ�Ķ�������"
	echo "SecureCRT need defult"
	echo "ru guo zhong wen luan ma ,qing geng gai SecureCRT bian ma wei defult"
	exit 0;
fi


if [ $XITONG = "LINUX" ]
then
	envprofile='.bash_profile'
else
	envprofile='.profile'
fi
#############����������1.ϵͳ���ͣ�SCPAS/CLAS/SCIM����2.�������ͣ�BEP/SIP/MS/RS/DB����3.IP��ַ��XXX.XXX.XXX.XXX����4.ͳһ�˻����룬5.��������IP
#SYSTYPE=`echo $1|tr '[a-z]' '[A-Z]'`
#HOSTYPE=`echo $2|tr '[a-z]' '[A-Z]'`
#IPADDR=$3
#PASSWD=$4
#ALARMIP="$5:3000"



##bep��װ��Ҫ7�������ֱ�Ϊ�����������ļ�����DOMAINID��CLUSTER������ip��INFORMIXDIR��INFORMIXSERVER��ONCONFIG
fun_bepinstall() {
if [ $# != 7 ]
then
log4s error "��̨��װ�����������󣡺�̨��װʧ��"
return 1
fi
cd $HOME
mkdir cin
log4s info "��ʼ��ѹ��̨�����"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "�Ҳ�����Ӧ�ĺ�̨���������װ��̨ʧ��"
	return 2
fi
pacname=`ls|grep Package|grep -v tar|grep -v gz|grep -v zip|grep -v bak`
if [[ X$pacname = X ]]
then
	log4s error "Package�ļ��в����ڣ���ȷ����ѹ���Package*�ļ�����\$HOME��"
	return 3
fi
cat $HOME/Package*/profile >> $HOME/$1
sed -i "s!^INFORMIXDIR.*!INFORMIXDIR=$5!g" $HOME/$1
sed -i "s/^INFORMIXSERVER.*/INFORMIXSERVER=$6/g" $HOME/$1
sed -i "s/^ONCONFIG.*/ONCONFIG=$7/g" $HOME/$1
sed -i "s/^DOMAINID.*/DOMAINID=$2/g" $HOME/$1
echo "CLUSTER=$3" >> $HOME/$1
echo 'export CLUSTER' >> $HOME/$1
echo 'ulimit -c 2' >> $HOME/$1
log4s info "��̨���������������"
. $HOME/$1
log4s info "��ʼ��װ��̨"
$HOME/Package*/makefifo
cp $HOME/Package*/install.sc $HOME 
chmod +x $HOME/install.sc
sleep 5
log4s info "��ʼ�����̨"
{ echo "0"; echo "i"; echo "i"; echo "y"; }|$HOME/install.sc -all $pacname
if [ $? -eq 0 ]
then
log4s info "��̨����ɹ�"
else
log4s error "��̨����ʧ��"
return 4
fi
sed -i "1s/SERVER.*/SERVER=$4:3000/" $CINDIR/etc/alarm.bep
sed -i "s/<addr.*port=\"1500\".*/<addr ip=\"$4\" port=\"1500\"\/>/" $CINDIR/etc/config.ne
log4s info "��̨��װ��ɣ����ֹ��޸�SDFDB��SMPDB����������config.comm��config.manager��sync.conf��config.sys�����ļ�"
}

##sip��װ��Ҫ4�������ֱ�Ϊ�����������ļ�����SIPDOMAINID��CLUSTER������IP
fun_sipinstall() {
if [ $# != 4 ]
then
	log4s error "sip��װ������������sip��װʧ��"
	return 1
fi
echo 'SIPDIR=$HOME/sipserver' >> $1
echo 'PATH=$PATH:$SIPDIR/bin' >> $1
echo "SIPDOMAINID=$2" >> $1
echo "CLUSTER=$3" >> $1
echo 'export  SIPDIR PATH SIPDOMAINID CLUSTER' >> $1
log4s info "sip���������������"
cd $HOME
. $HOME/$1
log4s info "��ʼ��ѹsip�����"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "�Ҳ�����Ӧ��sip�������sip��װʧ��"
	return 2
fi
if [[ ! -d "sipserver" ]]
then
	log4s error "sipserver�ļ��в����ڣ���ȷ����ѹ���sipserver�ļ�����\$HOME��"
	return 3
fi
log4s info "��ʼ��װsip"
chmod +x $HOME/sipserver/bin/sipmake
sleep 5
log4s info "��ʼ����sip"
sipmake
if [ $? -eq 0 ]
then
log4s info "sip����ɹ�"
else
log4s error "sip����ʧ��"
return 4
fi
chmod +x $HOME/sipserver/bin/*
sed -i "s/<inmsAlarmServer.*/<inmsAlarmServer ip=\"$4\" port=\"3000\"\/>/g" $HOME/sipserver/etc/config.alarm
log4s info "sip��װ��ɣ����ֹ��޸�config.sipserver��config.comm�����ļ�"
}

##gealarm��װ��Ҫ5����7�������ֱ�Ϊ�����������ļ�����DOMAINID��CLUSTER������ip�˿ڡ�root���롢��ѡ(INFORMIXDIR��INFORMIXSERVER)
fun_geinstall() {
if [ $# == 5 ]
then
	echo 'CINDIR=$HOME/genalarm' >> $1
	echo 'PATH=$PATH:.:$CINDIR/bin:/usr/vacpp/bin' >> $1
	echo "CLUSTER=$3" >> $1
	echo "DOMAINID=$2" >> $1
	echo 'export CINDIR PATH CLUSTER DOMAINID' >> $1
	geType='noDB'
	log4s info "gealarm���������������"
elif [ $# == 7 ]
then
	echo "INFORMIXDIR=$6" >> $1 
	echo "INFORMIXSERVER=$7" >> $1
	echo 'PATH=$PATH:$INFORMIXDIR/bin:$INFORMIXDIR/lib/esql' >> $1
	echo 'LD_LIBRARY_PATH=$INFORMIXDIR/lib:$INFORMIXDIR/lib/esql:/usr/local/lib' >> $1
	echo 'export INFORMIXDIR PATH INFORMIXSERVER LD_LIBRARY_PATH' >> $1
	echo 'CINDIR=$HOME/genalarm' >> $1
	echo 'PATH=$PATH:.:$CINDIR/bin:/usr/vacpp/bin' >> $1
	echo "CLUSTER=$3" >> $1
	echo "DOMAINID=$2" >> $1
	echo 'export CINDIR PATH CLUSTER DOMAINID' >> $1
	geType='DB'
	log4s info "gealarm���������������"
else
	log4s error "gealarm��װ������������gealarm��װʧ��"
	return 1	
fi
cd $HOME
. $HOME/$1
log4s info "��ʼ��ѹgealarm�����"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "�Ҳ���gealarm���������װgealarmʧ��"
	return 2
fi
gesrcDir=`ls|grep genalarm|grep -v tar|grep -v gz|grep -v zip`
mv $gesrcDir genalarm
if [[ ! -d "genalarm" ]]
then
	log4s error "genalarm�ļ��в����ڣ���ȷ����ѹ���genalarm�ļ�����\$HOME��"
	return 3
fi
log4s info "��ʼ��װgealarm"
cd $CINDIR/src
sleep 5
log4s info "��ʼ����gealarm"
makeall $geType
if [ $? -eq 0 ]
then
log4s info "gealarm����ɹ�"
else
log4s error "gealarm����ʧ��"
return 4
fi
chmod +x $HOME/genalarm/bin/*
sed -i "1s/.*/SERVER=$4/" $CINDIR/etc/config.alarm
sed -i "s/<subnet name=\"ckpro\" fe=\"checkpro\".*/<subnet name=\"ckpro\" fe=\"checkpro\" startinstance=\"1\" number=\"1\" initialnumber=\"1\" \/>/g" $CINDIR/etc/config.comm
if [ $# == 7 ]
then
	sed -i "s/<subnet name=\"ckDB\" fe=\"checkDB\".*/<subnet name=\"ckDB\" fe=\"checkDB\" startinstance=\"1\" number=\"1\" initialnumber=\"1\" \/>/g" $CINDIR/etc/config.comm
fi
log4s info "�����־�ļ��ɶ�Ȩ��"
if [ $XITONG = "LINUX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*assword:"
send "$5\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "chmod +x /home/*;chmod 644 /var/log/messages\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
elif [ $XITONG = "AIX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*assword:"
send "$5\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "chmod +rx /usr/bin/svmon;chmod u+s /usr/bin/svmon;chmod +r /var/spool/mail/root\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
elif [ $XITONG = "HPUX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*assword:"
send "$5\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "chmod +r /var/adm/syslog/syslog.log;chmod +r /var/mail/root\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
fi
if [ $# == 7 ]
then
log4s info "���ֹ���gealarm�˻����dbaccessȨ��"
fi
log4s info "gealarm��װ���"
}

##omsan��װ��Ҫ4����6�������ֱ�Ϊ�����������ļ�����CLUSTER������ip���������˿ڣ���root���롢��ѡ(INFORMIXDIR��INFORMIXSERVER)
fun_aninstall() {
if [ $# == 4 ]
then
	echo '########OMS########' >> $1
	echo 'export OMSDOMAINID=3' >> $1
	echo 'export OMSDIR=$HOME/oms' >> $1
	echo "export CLUSTER=$2" >> $1
	echo 'export PATH=$PATH:$OMSDIR/bin:/usr/bin:/usr/local/bin:/usr/sbin:/sbin' >> $1
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OMSDIR/lib' >> $1
	echo 'export LANG=zh_CN.GB18030' >> $1
	log4s info "omsan���������������"
elif [ $# == 6 ]
then
	echo '########INFORMIX########' >> $1 
	echo "export INFORMIXDIR=$5" >> $1
	echo "export INFORMIXSERVER=$6" >> $1
	echo 'export LD_LIBRARY_PATH=$INFORMIXDIR/lib:$INFORMIXDIR/lib/esql' >> $1
	echo 'export INFORMIXCONTIME=2' >> $1
	echo 'export INFORMIXCONRETRY=1' >> $1
	echo 'export PATH=$PATH:$INFORMIXDIR/bin:$INFORMIXDIR/lib/esql' >> $1
	echo '########OMS########' >> $1
	echo 'export OMSDOMAINID=3' >> $1
	echo 'export OMSDIR=$HOME/oms' >> $1
	echo "export CLUSTER=$2" >> $1
	echo 'export PATH=$PATH:$OMSDIR/bin:/usr/bin:/usr/local/bin:/usr/sbin:/sbin' >> $1
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OMSDIR/lib' >> $1
	echo 'export LANG=zh_CN.GB18030' >> $1
	log4s info "omsan���������������"
else
	log4s error "omsan��װ������������omsan��װʧ��"
	return 1
fi
cd $HOME
. $HOME/$1
log4s info "��ʼ��ѹomsan�����"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "�Ҳ���omsan���������װomsanʧ��"
	return 2
fi
ansrcDir=`ls|grep ^oms|grep -v tar|grep -v gz|grep -v zip`
mv $ansrcDir oms
if [[ ! -d "oms" ]]
then
	log4s error "oms�ļ��в����ڣ���ȷ����ѹ���oms�ļ�����\$HOME��"
	return 3
fi
log4s info "��ʼ��װomsan"
sed -i "1s/.*/SERVER=$3:3000/" $OMSDIR/etc/alarmcfg
sed -i "/<process feId=\"230\"/{n;n;s/<serverAddr>.*/<serverAddr>$3<\/serverAddr>/g}" $OMSDIR/etc/config.outcomm
sed -i "s/<Subsystem>.*/<Subsystem>agent<\/Subsystem>/g" $OMSDIR/etc/config.oms
sleep 5
echo "1"|config
sleep 2
build -nc
if [ $? -eq 0 ]
then
log4s info "omsan����ɹ�"
else
log4s error "omsan����ʧ��"
return 4
fi
sleep 2
if [ $XITONG = "LINUX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*assword:"
send "$4\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "cd /home/omsan/oms/bin;chown root:root superexe;chmod 6755 superexe\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
elif [ $XITONG = "AIX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*assword:"
send "$4\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "cd /home/omsan/oms/bin;chown root:system superexe;chmod 6755 superexe\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
fi
log4s info "omsan��װ���"
}

######pfmcapi��װ��Ҫ1����2���������������ļ�������ѡ32λ����
fun_pfmcinstall() {
if [ $# != 1 -a $# != 2 ]
then
log4s error "pfmcapi��װ�����������󣡺�̨��װʧ��"
return 1
fi
echo 'PFMCAPIDIR=$HOME/pfmcapi' >> $1
echo 'export PFMCAPIDIR' >> $1
echo 'LD_LIBRARY_PATH=$PFMCAPIDIR/lib:$LD_LIBRARY_PATH' >> $1
echo 'export LD_LIBRARY_PATH' >> $1
echo 'LIBPATH=$PFMCAPIDIR/lib:$LIBPATH' >> $1
echo 'export LIBPATH' >> $1
log4s info "pfmcapi���������������"
cd $HOME
. $HOME/$1
if [[ ! -d "pfmcapi" ]]
then
	log4s error "pfmcapi�ļ��в����ڣ���ȷ����ѹ���pfmcapi�ļ�����\$HOME��"
	log4s error "pfmcapi��װʧ��"
	return 3
fi
log4s info "��ʼ��װpfmcapi"
if [[ $# -eq 2 ]] && [[ $2 -eq 32 ]]
then
sed -i "s/^LONGBIT.*/LONGBIT = 32/g" $PFMCAPIDIR/src/makefile.include
fi
cd $PFMCAPIDIR/src/
make
if [ $? -eq 0 ]
then
log4s info "pfmcapi����ɹ�"
else
log4s error "pfmcapi����ʧ��"
return 4
fi
cd $HOME
cd ..
chmod a+x omsan
cd $HOME
if [ $XITONG = "LINUX" ]
then
chmod 777 -R pfmcapi
elif [ $XITONG = "HPUX" ]
then
chmod -R 777 pfmcapi
fi
log4s info "pfmcapi��װ�ɹ�"
}

##dia��װ��Ҫ8�������ֱ�Ϊ�����������ļ�����DOMAINID��CLUSTER������ip�˿ڡ�dra����ip��ַ�����ӷ�ʽ��OriginHost��OriginRealm����dra�Զ˵�ַ��dra�˿ڣ���ʱ����
fun_diainstall() 
{
if [ $# != 8 ]
then
	log4s error "diameter��װ������������diameter��װʧ��"
	return 1
fi
echo 'DIAMETERFEPDIR=$HOME/diameter' >> $1
echo 'PATH=$PATH:$DIAMETERFEPDIR/bin' >> $1
echo 'export DIAMETERFEPDIR PATH' >> $1
echo "DOMAINID=$2" >> $1
echo "CLUSTER=$3" >> $1
echo 'export DOMAINID CLUSTER' >> $1
log4s info "diameter���������������"
cd $HOME
. $HOME/$1
log4s info "��ʼ��ѹdiameter�����"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "�Ҳ���diameter���������װdiameterʧ��"
	return 2
fi
if [[ ! -d "diameter" ]]
then
	log4s error "diameter�ļ��в����ڣ���ȷ����ѹ���diameter�ļ�����\$HOME��"
	return 3
fi
log4s info "��ʼ��װdiameter"
cd $HOME/diameter/src
sleep 2
make clean
sleep 3
log4s info "��ʼ����diameter"
if [ $6 == 'tcp' ]
then
make
elif [ $6 == 'stcp' ]
then
make sctp
elif [ $6 == 'tcps' ]
then
make tcps
elif [ $6 == 'stcps' ]
then
make sctps
else
echo "dia���ӷ�ʽ���ʹ��󣬱���ʧ��"
log4s error "dia���ӷ�ʽ���ʹ��󣬱���ʧ��"
return 4
fi
if [ $? -eq 0 ]
then
log4s info "diameter����ɹ�"
else
log4s error "diameter����ʧ��"
return 4
fi
sed -i "1s/.*/SERVER=$4/" $DIAMETERFEPDIR/etc/config.alarm
sed -i "s/<avp name=\"Origin-Host\".*/<avp name=\"Origin-Host\" value=\"$7\" \/>/g" $DIAMETERFEPDIR/etc/CER.dat
sed -i "s/<avp name=\"Origin-Realm\".*/<avp name=\"Origin-Realm\" value=\"$8\" \/>/g" $DIAMETERFEPDIR/etc/CER.dat
sed -i "s/<avp name=\"Host-IP-Address\".*/<avp name=\"Host-IP-Address\" value=\"$5\"\/>/g" $DIAMETERFEPDIR/etc/CER.dat
#sed -i "s/<diameterlinkitem host=.*/<diameterlinkitem host=\"$9\" port=\"${10}\" \/>/g" $DIAMETERFEPDIR/etc/config.diameterfep
log4s info "diameter��װ���"
}

##mspre��װ��Ҫ2�������ֱ�Ϊ�����������ļ�����CLUSTER
fun_mspreinstall() 
{
if [ $# != 2 ]
then
	log4s error "mspre��װ������������mspre��װʧ��"
	return 1
fi
echo 'USR=iip' >> $1
echo 'export USR' >> $1
echo 'CINDIR=$HOME/cin' >> $1
echo 'PATH=$PATH:$CINDIR/bin:/usr/bin:/sbin:.' >> $1
echo 'export CINDIR PATH' >> $1
echo 'MANAGERID=1' >> $1
echo 'export MANAGERID' >> $1
echo 'DOMAINID=11' >> $1
echo 'export DOMAINID' >> $1
echo "export CLUSTER=$2" >> $1
echo 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CINDIR/lib' >> $1
echo 'export LD_LIBRARY_PATH' >> $1
log4s info "mspre���������������"
cd $HOME
. $HOME/$1
log4s info "��ʼ��ѹdiameter�����"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "�Ҳ���mspre���������װmspreʧ��"
	return 2
fi
if [[ ! -d "cin" ]] || [[ ! -d "services" ]]
then
	log4s error "cin��services�ļ��в����ڣ���ȷ����ѹ���cin��services�ļ�����\$HOME��"
	return 3
fi
log4s info "��ʼ��װmspre"
cp $HOME/services/voltepre/config.manager.1 $HOME/cin/etc/
cp $HOME/services/voltepre/config.comm $HOME/cin/etc/
cp $HOME/services/voltepre/config.srflib $HOME/cin/etc/
cp $HOME/services/voltepre/xjoinConfig.dat $HOME/cin/etc/
cp $HOME/services/voltepre/voltepre.xml $HOME/cin/services/
log4s info "��ʼ����mspre"
cd $HOME/src_cn*
makesrc.nodb -all
cd $HOME/services/
makeservice voltepre voltepre
if [ $? -eq 0 ]
then
log4s info "mspre����ɹ�"
else
log4s error "mspre����ʧ��"
return 4
fi
log4s info "mspre��װ���"
}

##alarmAPI��װ��Ҫ3�������ֱ�Ϊ�����������ļ�����CLUSTER������ip�˿�
fun_apiinstall()
{
if [ $# == 3 ]
then
	sed -i "s/^PATH.*/&:./g" $1
	log4s info "alarmAPI���������������"
else
	log4s error "alarmAPI��װ������������alarmAPI��װʧ��"
	return 1
fi
cd $HOME
. $HOME/$1
tarNum=`ls|grep alarmAPI.tar|wc -l`
if [ $tarNum -eq 0 ]
then
	log4s error "�Ҳ���alarmAPI���������װalarmAPIʧ��"
	return 2
fi
cp $HOME/alarmAPI.tar $INFORMIXDIR/
cd $INFORMIXDIR
ls alarmAPI.tar | xargs -n1 tar xf
if [[ ! -d "$INFORMIXDIR/alarmAPI" ]]
then
	log4s error "alarmAPI�ļ��в����ڣ���ȷ����ѹ���galarmAPI�ļ�����\$INFORMIXDIR��"
	return 3
fi
log4s info "��ʼ��װalarmAPI"
cd $INFORMIXDIR/alarmAPI
sleep 5
log4s info "��ʼ����alarmAPI"
make -f makefile.$xtong
if [ $? -eq 0 ]
then
log4s info "alarmAPI����ɹ�"
else
log4s error "alarmAPI����ʧ��"
return 4
fi
log4s info "��ʼ�޸�alarmAPI�����ļ�"
sed -i "s/^SERVER.*/SERVER=$3/g" $INFORMIXDIR/alarmAPI/alarmcfg
sed -i "29a\CLUSTER=$2\nexport CLUSTER" $INFORMIXDIR/alarmAPI/log_full.sh
sed -i "s/^instance.*/instance=\'$HOSTNAME.$2.DB\'/g" $INFORMIXDIR/alarmAPI/log_full.sh
sed -i "s!^ALARMPROGRAM.*!ALARMPROGRAM    ${INFORMIXDIR}/alarmAPI/log_full.sh!g" $INFORMIXDIR/etc/$ONCONFIG
chmod +x $INFORMIXDIR/alarmAPI/log_full.sh
log4s info "alarmAPI�����ļ��޸����"
log4s info "alarmAPI��װ���"
}

##n7server��װ��Ҫ3�������ֱ�Ϊ�����������ļ�����CLUSTER������ip�˿�
fun_ss7install() {
if [ $# != 3 ]
then
	log4s error "n7server��װ������������n7server��װʧ��"
	return 1
fi
cd $HOME
log4s info "��ʼ��ѹn7server�����"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "�Ҳ���n7server���������װn7serverʧ��"
	return 2
fi
if [[ ! -d "No7_IPS_n7server" ]]
then
	log4s error "No7_IPS_n7server�ļ��в����ڣ���ȷ����ѹ���No7_IPS_n7server�ļ�����\$HOME��"
	return 3
fi
cd $HOME/No7_IPS_n7server
sleep 5
log4s info "��ʼ��װn7server"
{ echo "y"; echo "s"; echo "n"; echo "n"; echo "y"; }|./install -all
if [ $? -eq 0 ]
then
log4s info "n7server����ɹ�"
else
log4s error "n7server����ʧ��"
return 4
fi
log4s info "��ʼ�޸Ļ��������������ļ�"
sed -i "s/CLUSTER.*/CLUSTER=$2/g" $HOME/$1
. $HOME/$1
sed -i "s/SERVER.*/SERVER=$3/" $CINDIR/etc/config.udp.alarm
log4s info "n7server��װ��ɣ����ֹ��޸�N7SERVERNUM����������config.n7server�����ļ�"
}

fun_ftphost()#####��Ҫ�����˻�����IP��ַIPADDR���˻�����passwd
{
log4s info "��ʼ�ϴ�$1�����Լ����ű���$2"
srcFile=`ls $1/*`
for file in $srcFile
do
file=${file//\[/\\\[}
file=${file//\]/\\\]}
/usr/bin/expect <<-EOF
set timeout 60
spawn scp -oPort=$sshport -r $file $1@$2:./
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$3\r" }
}
expect eof
EOF
done
/usr/bin/expect <<-EOF
set timeout 60
spawn scp -oPort=$sshport -r $0 $1@$2:./
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$3\r" }
}
expect eof
EOF
log4s info "����ϴ�$1�����Լ����ű���$2"
}

fun_extftphost()#####��Ҫ����Ŀ¼�����˻�����IP��ַIPADDR���˻�����passwd
{
log4s info "��ʼ�ϴ�$1�����Լ����ű���$3"
srcFile=`ls $1/*`
for file in $srcFile
do
file=${file//\[/\\\[}
file=${file//\]/\\\]}
/usr/bin/expect <<-EOF
set timeout 5
spawn ssh -p $sshport $2@$3
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$4\r" }
}
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "mkdir tmp;mkdir tmp/$1\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
/usr/bin/expect <<-EOF
set timeout 60
spawn scp -oPort=$sshport -r $file $2@$3:./tmp/$1/
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$4\r" }
}
expect eof
EOF
done
log4s info "����ϴ�$1�����Լ����ű���$2"
}

###############Զ�̵�¼����������ִ�������Ҫ4��������1����¼�˻���2����¼ip��3����¼���룬4��ִ�е�����
fun_srcgo()
{
/usr/bin/expect <<-EOF
set timeout 5
spawn ssh -p $sshport $1@$2
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$3\r" }
}
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "$4\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "sleep 2\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
}

#############Զ�������˻�����Ҫ3��������1.�������˻�����2.��ַ��3.����
##########send "passwd $1\r"
##########expect "*ew password:"
##########send "$3\r"
##########expect "*ew password:"
##########send "$3\r"
fun_adduser()
{
/usr/bin/expect <<-EOF
set timeout 5
spawn ssh -p $sshport root@$2
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$3\r" }
}
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "useradd -g users -d /home/$1 $1\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "echo \"$1:$3\" | chpasswd\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
}

#############Զ�������˻��������Լ����飬��Ҫ3��������1.�������˻�����2.��ַ��3.����
fun_addnewuser()
{
/usr/bin/expect <<-EOF
set timeout 5
spawn ssh -p $sshport root@$2
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$3\r" }
}
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "groupadd $1\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "useradd -g $1 -d /home/$1 $1\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "echo \"$1:$3\" | chpasswd\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
}

#############Զ��дetchost����Ҫ3��������1.��ַ��2.���룬3.��Ӧhost����Ϣ
fun_addetchost()
{
/usr/bin/expect <<-EOF
set timeout 5
spawn ssh -p $sshport root@$1
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$2\r" }
}
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "echo \"$3\" >> /etc/hosts\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
}

######################��װ����lib��������libgcc��gcc��glibc-devel�������#############
fun_baselibinstall()
{
log4s debug "����fun_baselibinstall����"
cd /tmp
if [ ! -f "/tmp/install.log" ]
then
touch /tmp/install.log
chmod 777 /tmp/install.log
log4s info "�����ļ�/tmp/install.log"
fi
echo "start baselib install" >> /tmp/install.log
log4s info "start baselib installд��/tmp/install.log�ļ�"
if [[ ! `rpm -qa |grep libgcc|grep x86_64` ]]
then
log4s info "��Ҫ��װlibgcc��x86_64��"
rpm -ivh libgcc*x86_64.rpm --force --nodeps
	if [ $? -eq 0 ]
	then
	log4s info "libgcc��x86_64����װ���"
	else
	log4s error "libgcc��x86_64����װʧ��"
	echo "install completed" >> /tmp/install.log
	exit 1
	fi
fi
if [[ ! `rpm -qa |grep libgcc|grep i686` ]]
then
log4s info "��Ҫ��װlibgcc��i686��"
rpm -ivh libgcc*i686.rpm --force --nodeps
	if [ $? -eq 0 ]
	then
	log4s info "libgcc��i686����װ���"
	else
	log4s error "libgcc��i686����װʧ��"
	echo "install completed" >> /tmp/install.log
	exit 1
	fi
fi
if [[ ! `rpm -qa |grep glibc-devel|grep x86_64` ]]
then
log4s info "��Ҫ��װglibc-devel��x86_64��"
rpm -ivh glibc-devel*x86_64.rpm --force --nodeps
	if [ $? -eq 0 ]
	then
	log4s info "glibc-devel��x86_64����װ���"
	else
	log4s error "glibc-devel��x86_64����װʧ��"
	echo "install completed" >> /tmp/install.log
	exit 1
	fi
fi
if [[ ! `rpm -qa |grep glibc-devel|grep i686` ]]
then
log4s info "��Ҫ��װglibc-devel��i686��"
rpm -ivh glibc-devel*i686.rpm --force --nodeps
	if [ $? -eq 0 ]
	then
	log4s info "glibc-devel��i686����װ���"
	else
	log4s error "glibc-devel��i686����װʧ��"
	echo "install completed" >> /tmp/install.log
	exit 1
	fi
fi
if [[ ! `rpm -qa |grep libstdc++-4|grep x86_64` ]]
then
log4s info "��Ҫ��װlibstdc++��x86_64��"
rpm -ivh libstdc++-4*x86_64.rpm --force --nodeps
	if [ $? -eq 0 ]
	then
	log4s info "libstdc++��x86_64����װ���"
	else
	log4s error "libstdc++��x86_64����װʧ��"
	echo "install completed" >> /tmp/install.log
	exit 1
	fi
fi
if [[ ! `rpm -qa |grep libstdc++-4|grep i686` ]]
then
log4s info "��Ҫ��װlibstdc++��i686��"
rpm -ivh libstdc++-4*i686.rpm --force --nodeps
	if [ $? -eq 0 ]
	then
	log4s info "libstdc++��i686����װ���"
	else
	log4s error "libstdc++��i686����װʧ��"
	echo "install completed" >> /tmp/install.log
	exit 1
	fi
fi
if [[ $X86 == "x86_64" ]]
then
	if [ `rpm -qa|grep ^gcc|wc -l` -lt 2 ]
	then
		log4s info "��Ҫ��װgcc��x86_64��"
		rpm -ivh gcc*x86_64.rpm --force --nodeps
		if [ $? -eq 0 ]
		then
			log4s info "gcc��x86_64����װ���"
		else
			log4s error "gcc��x86_64����װʧ��"
			echo "install completed" >> /tmp/install.log
			exit 1
		fi
	fi
elif [[ $X86 == "i686" ]]
then
	if [ `rpm -qa|grep ^gcc|wc -l` -lt 2 ]
	then
		log4s info "��Ҫ��װgcc��i686��"
		rpm -ivh gcc*i686.rpm --force --nodeps
		if [ $? -eq 0 ]
		then
			log4s info "gcc��i686����װ���"
		else
			log4s error "gcc��i686����װʧ��"
			echo "install completed" >> /tmp/install.log
			exit 1
		fi
	fi
fi
log4s info "baselib����װ���"
log4s info "install completedд��/tmp/install.log�ļ�"
echo "install completed" >> /tmp/install.log
}

######################��װ32λlib�����������#############
fun_libinstall()
{
cd /tmp
if [ ! -f "/tmp/install.log" ]
then
touch /tmp/install.log
chmod 777 /tmp/install.log
log4s info "�����ļ�/tmp/install.log"
fi
echo "start lib install" >> /tmp/install.log
log4s info "start lib installд��/tmp/install.log�ļ�"
if [[ ! `rpm -qa |grep libstdc++-devel|grep x86_64` ]]
then
log4s info "��Ҫ��װlibstdc++-devel��x86_64��"
rpm -ivh libstdc++-devel*x86_64.rpm --force --nodeps
if [ $? -eq 0 ]
then
log4s info "libstdc++-devel��x86_64����װ���"
else
log4s error "libstdc++-devel��x86_64����װʧ��"
echo "install completed" >> /tmp/install.log
exit 1
fi
fi
if [[ ! `rpm -qa |grep ncurses-devel|grep x86_64` ]]
then
log4s info "��Ҫ��װncurses-devel��x86_64��"
rpm -ivh ncurses-devel*x86_64.rpm --force --nodeps
if [ $? -eq 0 ]
then
log4s info "ncurses-devel��x86_64����װ���"
else
log4s error "ncurses-devel��x86_64����װʧ��"
echo "install completed" >> /tmp/install.log
exit 1
fi
fi
if [[ ! `rpm -qa |grep glibc-devel|grep i686` ]] || [[ ! `rpm -qa |grep libstdc++-devel|grep i686` ]] || [[ ! `rpm -qa |grep ncurses-devel|grep i686` ]]
then
log4s info "��Ҫ��װi686��"
rpm -ivh /tmp/*i686.rpm --force --nodeps
if [ $? -eq 0 ]
then
log4s info "i686����װ���"
else
log4s error "i686����װʧ��"
echo "install completed" >> /tmp/install.log
exit 1
fi
fi
log4s info "��װfftw��"
rpm -ivh /tmp/fftw*.rpm --force --nodeps
if [ $? -eq 0 ]
then
log4s info "fftw����װ���"
else
log4s error "fftw����װʧ��"
echo "install completed" >> /tmp/install.log
exit 1
fi
log4s info "lib����װ���"
log4s info "install completedд��/tmp/install.log�ļ�"
echo "install completed" >> /tmp/install.log
}

###########################�ڱ����ϲ���automs����ms���һ����װ
fun_msinstall()
{
echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts
echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|wc -l`
tempi='1'
while  [ $tempi -le $tempnum ]
do
	msaddr=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
	mspass=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==$tempi'{print $5}')
	mshost=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==$tempi'{print $6}')
	msmedi=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==$tempi'{print $7}')
	echo "$msaddr   $mshost" >> /etc/hosts
	log4s info "����$msaddr��ms�˻�"
	fun_adduser ms $msaddr $mspass
	templib=0
	while [ $templib -lt 100 ]
	do
		log4s info "���${msaddr}��pfmcapi�Ƿ�װ"
		/usr/bin/expect <<-EOF
		set timeout 5
		spawn ssh -p $sshport ms@$msaddr "test -f /home/omsan/pfmcapi/lib/libpfmcpthread.so.1.0.0||echo xxxxxxxxxxxxxooooooooooo"
		expect {
		"*yes/no" { send "yes\r"; exp_continue }
		"*assword:" { send "$mspass\r" }
		}
		expect xxxxxxxxxxxxxooooooooooo { exit 55 }
		EOF
		if [ $? -eq 0 ]
		then
		log4s info "${msaddr}��pfmcapi��װ�����"
		templib=500
		else
		log4s debug "${msaddr}��pfmcapi��װδ��ɣ���${templib}��ѭ��"
		sleep 60
		templib=`expr $templib + 1`
		if [ $templib -eq 100 ]
		then
		log4s error "${msaddr}��pfmcapi��װδ��ɣ������ȶ�ִ��ʱ�䣬�˳��ýű�"
		exit 0
		fi
		fi
	done
	tempi=`expr $tempi + 1`
done
if [[ `ls ms/automs*|wc -l` -eq 0 ]]
then
echo "ms·���²�����automs��������˳��ýű�"
log4s error "ms·���²�����automs��������˳��ýű�"
return 2
fi
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|wc -l`
tempi='1'
automsip='['
automsme='['
while  [ $tempi -le $tempnum ]
do
	msaddr=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
	mspass=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==$tempi'{print $5}')
	msmedi=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==$tempi'{print $7}')
	if [ $tempi -eq $tempnum ]
	then
	automsip="${automsip}\\\"${msaddr}\\\""
	automsme="${automsme}\\\"${msmedi}\\\""
	else
	automsip="${automsip}\\\"${msaddr}\\\", "
	automsme="${automsme}\\\"${msmedi}\\\", "
	fi
	log4s info "�ϴ�/etc/hosts�ļ���${msaddr}"
	/usr/bin/expect <<-EOF
	set timeout 60
	spawn scp -oPort=$sshport /etc/hosts root@$msaddr:/etc/
	expect {
	"*yes/no" { send "yes\r"; exp_continue }
	"*assword:" { send "$mspass\r" }
	}
	expect eof
	EOF
	tempi=`expr $tempi + 1`
done
automsip=${automsip}]
automsme=${automsme}]
mstype=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==1'{print $1}')
msword=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|awk -F '|' ''NR==1'{print $5}')
if [[ $mstype = 'CLAS' ]] || [[ $mstype = 'EOP' ]]
then
projname='crbt'
elif [ $mstype = 'SCPAS' ]
then
projname='volte_as'
elif [ $mstype = 'VIDEO' ]
then
projname='video_crbt'
elif [ $mstype = 'CENTREX' ]
then
projname='centrex'
else
echo "δ֪��ϵͳ���Ͱ�װms������˳��ýű�"
log4s error "δ֪��ϵͳ���Ͱ�װms������˳��ýű�"
return 5
fi
log4s info "����������automs�˻�"
useradd -g users -d /home/automs automs
passwd automs <<-EOF
$LOCALPASSWD
$LOCALPASSWD
EOF
log4s info "���𱾻���automs���"
msgzfile=`ls ms/automs*`
cp $msgzfile /home/automs/
chown automs:users /home/automs/automs*
su - automs -c ". ./.bash_profile;tar -xzf automs*.*;cd automs;./install_env"
su - automs -c ". ./.bash_profile;sed -i -e \"/inms/{n;n;s/.*ip.*/            \'ip\': \'$OMSIP\',/g;}\" -e \"/alarm/{n;s/.*ip.*/            \'ip\': \'$OMSIP\',/g;}\" /home/automs/deploy/config/msconfig.py;sed -i -e \"/inms/{n;n;n;s/.*port.*/            \'port\': 1400/g;}\" -e \"/alarm/{n;n;s/.*port.*/            \'port\': 3000/g;}\" /home/automs/deploy/config/msconfig.py;sed -i -e \"s/.*project.*/        \'project\' : '${projname}\',/g;\" -e \"s/.*hosts.*/        \'hosts\' : ${automsip},/g;\" -e \"s/.*mediaip.*/        'mediaip' : ${automsme},/g;\" /home/automs/deploy/config/msconfig.py"
su - automs -c ". ./.bash_profile;sed -i -e \"s/env.port.*/env.port = \'$sshport\'/g;\" -e \"s/env.password.*/env.password = \'$msword\'/g;\" /home/automs/deploy/fabfile.py"
su - automs -c ". ./.bash_profile;cd deploy;fab -P deploy_msenv;fab -P deploy_conf"
sleep 2
su - automs -c ". ./.bash_profile;cd deploy;fab -P deploy_rcs"
sleep 2
su - automs -c ". ./.bash_profile;cd deploy;fab -P deploy_rms"
sleep 2
su - automs -c ". ./.bash_profile;cd deploy;fab -P deploy_imp"
log4s info "��̨ms�����װ���"
}

##mysql��װ��Ҫ5�������ֱ�Ϊ�����������ļ�����root�˻����롢������ַ���˿ڡ�mysqlservid��group_seeds
fun_mysqlinstall()
{
if [ $# != 5 ]
then
	log4s error "mysql��װ������������mysql��װʧ��"
	return 1
fi
log4s info "��ʼ��ѹmysql�����"
if [[ -n `ls|grep gz$` ]]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [[ -n `ls|grep zip$` ]]
then
	ls *.zip | xargs -n1 unzip
elif [[ -n `ls|grep tar$` ]]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "�Ҳ���mysql���������װmysqlʧ��"
	return 2
fi
mysqldir=`ls|grep ^mysql|grep -v tar|grep -v gz|grep -v zip|grep -v test`
echo "PATH=/home/mysql/${mysqldir}/bin:\$PATH:\$HOME/bin" >> $1
echo 'export PATH' >> $1
log4s info "mysql���������������"
cd $HOME
. $HOME/$1
touch install.result
cd $mysqldir
mkdir mysql-files
chmod 770 mysql-files
chown -R mysql:mysql /home/mysql
fullpath=$HOME/$mysqldir
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*assword:"
send "$2\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "$fullpath/bin/mysqld --initialize --datadir=$fullpath/data/ --user=mysql 1>$HOME/install.result 2>&1\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
send "exit\r"
expect eof
EOF
sleep 30
mysqlpasswd=`grep root@localhost $HOME/install.result`
mysqlpasswd=${mysqlpasswd##*root@localhost: }
echo '[client]' >> my.cnf
echo 'default-character-set=utf8' >> my.cnf
echo '[mysqld]' >> my.cnf
echo 'character-set-server=utf8' >> my.cnf
echo 'log_bin_trust_function_creators=1' >> my.cnf
echo 'innodb_buffer_pool_size = 1000M' >> my.cnf
echo 'innodb_flush_log_at_trx_commit=2' >> my.cnf
echo 'innodb_log_file_size=1000M' >> my.cnf
echo "basedir=${fullpath}" >> my.cnf
echo "datadir=${fullpath}/data" >> my.cnf
echo '########replication framework' >> my.cnf
echo "server-id=$4" >> my.cnf
echo 'log-bin=mysql-bin' >> my.cnf
echo 'binlog-format=ROW' >> my.cnf
echo 'log-slave-updates=on' >> my.cnf
echo 'gtid-mode=on' >> my.cnf
echo 'enforce-gtid-consistency=on' >> my.cnf
echo 'master_info_repository=TABLE' >> my.cnf
echo 'relay_log_info_repository=TABLE' >> my.cnf
echo 'binlog_checksum=NONE' >> my.cnf
echo '########group replication' >> my.cnf
echo 'transaction_write_set_extraction=XXHASH64' >> my.cnf
echo 'loose-group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"' >> my.cnf
echo 'loose-group_replication_start_on_boot=off' >> my.cnf
echo "loose-group_replication_local_address=\"$3\"" >> my.cnf
echo "loose-group_replication_group_seeds=\"$5\"" >> my.cnf
echo 'loose-group_replication_bootstrap_group=off' >> my.cnf
echo 'loose-group_replication_single_primary_mode=true' >> my.cnf
echo 'loose-group_replication_enforce_update_everywhere_checks=false' >> my.cnf
sleep 5
mysqld_safe --defaults-file=$fullpath/my.cnf --user=mysql &
sleep 30
/usr/bin/expect <<-EOF
set timeout 5
spawn mysqladmin -u root -p password $2
expect "*assword:"
send "$mysqlpasswd\r"
expect {
"*>" {}
"*]" {}
"*#" {}
"*\\\\$" {}
}
expect eof
EOF
sleep 5
/usr/bin/expect <<-EOF
set timeout 5
spawn mysql -u root -p
expect "*assword:"
send "$2\r"
expect "mysql>"
send "install plugin group_replication soname 'group_replication.so';\r"
expect "mysql>"
send "set sql_log_bin=0;\r"
expect "mysql>"
send "create user eop@'%' identified with mysql_native_password by '$2';\r"
expect "mysql>"
send "grant all privileges on *.* to eop@'%';\r"
expect "mysql>"
send "create user rpl_user@'%' identified by 'rpl_user123';\r"
expect "mysql>"
send "grant replication slave,replication client on *.* to rpl_user@'%';\r"
expect "mysql>"
send "FLUSH PRIVILEGES;\r"
expect "mysql>"
send "SET SQL_LOG_BIN=1;\r"
expect "mysql>"
send "quit\r"
expect eof
EOF
sleep 2
/usr/bin/expect <<-EOF
set timeout 5
spawn mysql -u rpl_user -p
expect "*assword:"
send "rpl_user123\r"
expect "mysql>"
send "quit\r"
expect eof
EOF
sleep 2
if [ $4 -eq 1 ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn mysql -u root -p
expect "*assword:"
send "$2\r"
expect "mysql>"
send "change master to master_user='rpl_user',master_password='rpl_user123' for channel 'group_replication_recovery';\r"
expect "mysql>"
send "SET GLOBAL group_replication_bootstrap_group = ON;\r"
expect "mysql>"
send "START GROUP_REPLICATION;\r"
expect "mysql>"
send "SET GLOBAL group_replication_bootstrap_group = OFF;\r"
expect "mysql>"
send "quit\r"
expect eof
EOF
else
/usr/bin/expect <<-EOF
set timeout 5
spawn mysql -u root -p
expect "*assword:"
send "$2\r"
expect "mysql>"
send "reset master;\r"
expect "mysql>"
send "stop slave;\r"
expect "mysql>"
send "change master to master_user='rpl_user',master_password='rpl_user123' for channel 'group_replication_recovery';\r"
expect "mysql>"
send "START GROUP_REPLICATION;\r"
expect "mysql>"
send "quit\r"
expect eof
EOF
fi
}

##web��װ��Ҫ5�������ֱ�Ϊ�����������ļ��������ܵ�ַ�����ɷֵ�����������ַ�˿ڡ�mysql���ݿ��ַ�˿ڡ�mysql����
fun_webinstall()
{
if [ $# != 5 ]
then
	log4s error "web��װ������������web��װʧ��"
	return 1
fi
cd $HOME;mkdir local
echo 'PATH=$HOME/local/webjoin/bin:$PATH' >> $1
echo 'export PATH' >> $1
echo 'WEBJOIN_HOME=$HOME/local/webjoin' >> $1
echo 'export WEBJOIN_HOME' >> $1
log4s info "web���������������"
. $HOME/$1
log4s info "��ʼ��ѹweb�����"
if [[ -n `ls|grep webjoin|grep gz$` ]]
then
	ls|grep webjoin|grep gz$|xargs -n1 -I {} tar xzf {} -C local/
elif [[ -n `ls|grep webjoin|grep zip$` ]]
then
	ls|grep webjoin|grep zip$|xargs -n1 -I {} unzip {} -d local/
elif [[ -n `ls|grep webjoin|grep tar$` ]]
then
	ls|grep webjoin|grep tar$|xargs -n1 -I {} tar xf {} -C local/
else
	log4s error "�Ҳ���web���������װwebʧ��"
	return 2
fi
cd local
ls|grep webjoin-server|xargs -n1 -I {} ln -s {} webjoin
echo '# -*- coding: utf-8 -*-' > $WEBJOIN_HOME/conf/server.rb
echo "inms_statserver_address '$2:1400'" >> $WEBJOIN_HOME/conf/server.rb
echo "inms_alarmserver_address '$2:3000'" >> $WEBJOIN_HOME/conf/server.rb
echo "inms_device_id '48'" >> $WEBJOIN_HOME/conf/server.rb
echo -ne "\n" >> $WEBJOIN_HOME/conf/server.rb
echo 'tomcat :eop do' >> $WEBJOIN_HOME/conf/server.rb
echo '  stdout false' >> $WEBJOIN_HOME/conf/server.rb
echo '  java_opts "-Xms1024m -Xmx1024m -server -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+UseTLAB -XX:+CMSIncrementalMode -XX:+CMSIncrementalPacing -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=~/heap.bin"' >> $WEBJOIN_HOME/conf/server.rb
echo '  executor :shared, :min => 10, :max => 2000' >> $WEBJOIN_HOME/conf/server.rb
echo '  connector :http, 8080, :executor => :shared' >> $WEBJOIN_HOME/conf/server.rb
echo "  webapp '/eop' do" >> $WEBJOIN_HOME/conf/server.rb
echo '    env[:appname] = "eop"' >> $WEBJOIN_HOME/conf/server.rb
echo '  end' >> $WEBJOIN_HOME/conf/server.rb
echo 'end' >> $WEBJOIN_HOME/conf/server.rb
echo -ne "\n" >> $WEBJOIN_HOME/conf/server.rb
echo 'nginx :proxy do' >> $WEBJOIN_HOME/conf/server.rb
echo '  server do' >> $WEBJOIN_HOME/conf/server.rb
echo '    listen :http, 8090' >> $WEBJOIN_HOME/conf/server.rb
echo "    location \"/\", :proxy_to => [$3]" >> $WEBJOIN_HOME/conf/server.rb
echo '  end' >> $WEBJOIN_HOME/conf/server.rb
echo 'end' >> $WEBJOIN_HOME/conf/server.rb
cd $WEBJOIN_HOME/webapps;mkdir eop
cd $HOME
if [[ -n `ls|grep war$` ]]
then
	ls|grep war$|xargs -n1 -I {} unzip {} -d $WEBJOIN_HOME/webapps/eop/
else
	log4s error "�Ҳ���war���������װwarʧ��"
	return 2
fi
#######war��������Ҫ����
cd $WEBJOIN_HOME/webapps/eop/WEB-INF/classes/spring/
awk -F '?' -v OFS='?' '{sub(/p:url.*/,"p:url=\"jdbc:mysql://'"$4"'/eop",$1);print $0;print >"applicationContext-datasource.xml"}' applicationContext-datasource.xml
sed -i "s/p:username.*/p:username=\"eop\"/g" $WEBJOIN_HOME/webapps/eop/WEB-INF/classes/spring/applicationContext-datasource.xml
sed -i "s/p:password.*/p:password=\"$5\"/g" $WEBJOIN_HOME/webapps/eop/WEB-INF/classes/spring/applicationContext-datasource.xml
sleep 2
webjoin start
}

##ismp��װ��Ҫ7�������ֱ�Ϊ�����������ļ��������ܵ�ַ�˿ڡ����ɷֵ�����������ַ�˿ڡ�mysql���ݿ����õ�ַ�˿ڡ�mysql���ݿⱸ�õ�ַ�˿ڡ�mysql���ݿ����롢��������
fun_ismpinstall()
{
if [ $# != 7 ]
then
	log4s error "ismp��װ������������ismp��װʧ��"
	return 1
fi
log4s info "��ʼ��ѹismp�����"
if [[ -n `ls|grep ismp|grep gz$` ]]
then
	ls|grep ismp|grep gz$|xargs -n1 tar xzf
elif [[ -n `ls|grep ismp|grep zip$` ]]
then
	ls|grep ismp|grep zip$|xargs -n1 unzip
elif [[ -n `ls|grep ismp|grep tar$` ]]
then
	ls|grep ismp|grep tar$|xargs -n1 tar xf
else
	log4s error "�Ҳ���ismp���������װismpʧ��"
	return 2
fi
ismpsrc=`ls|grep ^ismp|grep -v gz|grep -v tar|grep -v zip`
mv $ismpsrc cmin02sms
cat $HOME/cmin02sms/etc/profile.demo >> $HOME/$1
echo 'JAVA_HOME=/usr/lib/jvm/java' >> $HOME/$1
echo 'CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/charsets.jar:$JAVA_HOME/jre/lib/rt.jar:$SMPDIR/sdc/lib/*' >> $HOME/$1
echo 'JAVA_OPTS="-server -XX:+UseParallelGC -Xms1024M -Xmx1024M -XX:PermSize=256M -XX:MaxPermSize=256M"' >> $HOME/$1
echo 'PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH' >> $HOME/$1
echo 'export JAVA_HOME CLASSPATH JAVA_OPTS PATH' >> $HOME/$1
echo 'export PATH=$PATH:$HOME/nginx/sbin' >> $HOME/$1
. $HOME/$1
log4s info "ismp���������������"
cd $SMPDIR/etc
cp template.conf/conf.*.json .
sed -i "s/^SERVER.*/SERVER=$2/g" $SMPDIR/etc/alarm.config
sed -i "s/HTTP_PORT.*/HTTP_PORT\": 8100,/g" $SMPDIR/etc/conf.httpjson.json
cp $SMPDIR/src/shell/* $SMPDIR/bin
log4s info "��ʼ����ismp"
makeall $7
if [ $? -eq 0 ]
then
log4s info "ismp����ɹ�"
else
log4s error "ismp����ʧ��"
return 4
fi
log4s info "��ʼ��ѹsdc�����"
cd $HOME
if [[ -n `ls|grep ^sdc|grep gz$` ]]
then
	ls|grep ^sdc|grep gz$|xargs -n1 -I {} tar xzf {} -C cmin02sms/
elif [[ -n `ls|grep ^sdc|grep zip$` ]]
then
	ls|grep ^sdc|grep zip$|xargs -n1 -I {} unzip {} -d cmin02sms/
elif [[ -n `ls|grep ^sdc|grep tar$` ]]
then
	ls|grep ^sdc|grep tar$|xargs -n1 -I {} tar xf {} -C cmin02sms/
else
	log4s error "�Ҳ���sdc���������װsdcʧ��"
	return 2
fi
cd $HOME/cmin02sms
sdcsrc=`ls|grep ^sdc|grep -v gz|grep -v tar|grep -v zip`
mv $sdcsrc sdc
sed -i "s/JDBCDriver.*/JDBCDriver\":\"com.mysql.jdbc.Driver\",/g" $HOME/cmin02sms/etc/conf.sdc.json
sed -i "s/JDBCConnectionURL.*/JDBCConnectionURL\":\"jdbc:mysql:\/\/$4\/eop\",/g" $HOME/cmin02sms/etc/conf.sdc.json
sed -i "s/DbMode.*/DbMode\":\"HDR\",/g" $HOME/cmin02sms/etc/conf.sdc.json
sed -i "s/SlaveJDBCURL.*/SlaveJDBCURL\":\"jdbc:mysql:\/\/$5\/eop\",/g" $HOME/cmin02sms/etc/conf.sdc.json
sed -i "s/UserName.*/UserName\":\"eop\",/g" $HOME/cmin02sms/etc/conf.sdc.json
sed -i "s/Password.*/Password\":\"$6\",/g" $HOME/cmin02sms/etc/conf.sdc.json
log4s info "sdc��װ���"
log4s info "��ʼ��ѹnginx�����"
cd $HOME
if [[ -n `ls|grep ^nginx|grep gz$` ]]
then
	ls|grep ^nginx|grep gz$|xargs -n1 tar xzf
elif [[ -n `ls|grep ^nginx|grep zip$` ]]
then
	ls|grep ^nginx|grep zip$|xargs -n1 unzip
elif [[ -n `ls|grep ^nginx|grep tar$` ]]
then
	ls|grep ^nginx|grep tar$|xargs -n1 tar xf
else
	log4s error "�Ҳ���nginx���������װnginxʧ��"
	return 2
fi
nginxsrc=`ls|grep ^nginx|grep -v tar|grep -v gz|grep -v zip`
mkdir -p $HOME/nginx
cd $nginxsrc
log4s info "��ʼ����nginx"
./configure --prefix=$HOME/nginx --with-pcre=pcre-8.37/ --with-http_ssl_module
make && make install
if [ $? -eq 0 ]
then
log4s info "nginx����ɹ�"
else
log4s error "nginx����ʧ��"
return 4
fi
cp -r $HOME/$nginxsrc/conf/certificate  $HOME/nginx/conf/
cp $HOME/$nginxsrc/shell/cut_nginx_log.sh  $HOME/nginx/sbin
echo '59 * * * * . $HOME/.bash_profile && cut_nginx_log.sh >>/dev/null 2>&1 &' >> $SMPDIR/etc/mycron.conf
setcron master
#######�޸�nginx����
sed -i "/upstream httpjson.ismp/,/keepalive/s/server/\#server/g" $HOME/nginx/conf/nginx.conf
for tempi in $3
do
sed -i "/upstream httpjson.ismp/a\        server $tempi;" $HOME/nginx/conf/nginx.conf
done
log4s info "ismp��װ���"
}

###############redis��װ���谲װ����
fun_redisinstall()
{
log4s info "��ʼ��ѹredis�����"
cd $HOME
if [[ -n `ls|grep ^redis|grep gz$` ]]
then
	ls|grep ^redis|grep gz$|xargs -n1 tar xzf
elif [[ -n `ls|grep ^redis|grep zip$` ]]
then
	ls|grep ^redis|grep zip$|xargs -n1 unzip
elif [[ -n `ls|grep ^redis|grep tar$` ]]
then
	ls|grep ^redis|grep tar$|xargs -n1 tar xf
else
	log4s error "�Ҳ���redis���������װredisʧ��"
	return 2
fi
mkdir redis-run
log4s info "��ʼ����redis"
cd redis/src && make install
if [ $? -eq 0 ]
then
log4s info "redis����ɹ�"
else
log4s error "redis����ʧ��"
return 4
fi
}

######slrlua��װ���谲װ����
fun_eopluainstall()
{
log4s info "��ʼ��ѹlua�����"
cd $HOME/tmp/slrlua
if [[ -n `ls|grep gz$` ]]
then
	ls|grep gz$|xargs -n1 tar xzf
elif [[ -n `ls|grep zip$` ]]
then
	ls|grep zip$|xargs -n1 unzip
elif [[ -n `ls|grep tar$` ]]
then
	ls|grep tar$|xargs -n1 tar xf
else
	log4s error "�Ҳ���lua���������װluaʧ��"
	return 2
fi
cp -r $HOME/tmp/slrlua/lib/* $SMPDIR/lib/
cp -r $HOME/tmp/slrlua/sl* $SMPDIR/slrlua/
log4s info "lua��װ���"
}

##httpfep��װ��Ҫ1�������ֱ�Ϊ�����������ļ���
fun_httpfepinstall()
{
if [ $# != 2 ]
then
	log4s error "httpfep��װ������������httpfep��װʧ��"
	return 1
fi
log4s info "��ʼ��ѹhttpfep�����"
if [[ -n `ls|grep httpfep|grep gz$` ]]
then
	ls|grep httpfep|grep gz$|xargs -n1 tar xzf
elif [[ -n `ls|grep httpfep|grep zip$` ]]
then
	ls|grep httpfep|grep zip$|xargs -n1 unzip
elif [[ -n `ls|grep httpfep|grep tar$` ]]
then
	ls|grep httpfep|grep tar$|xargs -n1 tar xf
else
	log4s error "�Ҳ���httpfep���������װhttpfepʧ��"
	return 2
fi
httpfepsrc=`ls|grep ^httpfep|grep -v gz|grep -v tar|grep -v zip`
mv $httpfepsrc httpfep
echo "DOMAINID=$2" >> $HOME/$1
echo 'export DOMAINID' >> $HOME/$1
echo 'HTTPFEPDIR=$HOME/httpfep' >> $HOME/$1
echo 'PATH=$PATH:$HTTPFEPDIR/bin' >> $HOME/$1
echo 'export PATH HTTPFEPDIR' >> $HOME/$1
. $HOME/$1
log4s info "httpfep���������������"
chmod a+x httpfep/bin/httpexe
chmod a+x httpfep/bin/httpdown
cd $HOME/httpfep/src
log4s info "��ʼ����httpfep"
make
if [ $? -eq 0 ]
then
log4s info "httpfep����ɹ�"
else
log4s error "httpfep����ʧ��"
return 4
fi
################���httpfep�����޸�
log4s info "httpfep��װ���"
}

fun_install()
{
if [ ! -f "conf.unl" ]
then
echo "�����ļ�conf.unl�����ڣ������˳�"
log4s error "�����ļ�conf.unl�����ڣ������˳�"
exit 1
fi
INFDIR=`grep ^INFORMIX_CLIENT_PATH conf.unl|awk -F '|' '{print $2}'`
DBDIR=`grep ^INFORMIX_SERVER_PATH conf.unl|awk -F '|' '{print $2}'`
INFSER=`grep ^INFORMIXSERVER conf.unl|awk -F '|' '{print $2}'`
INFCONF=`grep ^ONCONFIG conf.unl|awk -F '|' '{print $2}'`
CLUSTER=`grep ^CLUSTER conf.unl|awk -F '|' '{print $2}'`
OMSIP=`grep ^OMSCC conf.unl|awk -F '|' '{print $2}'`
#ISMPIP=`grep ^ISMP conf.unl|awk -F '|' '{print $2}'`
ORIGINHOST=`grep ^ORIGINHOST conf.unl|awk -F '|' '{print $2}'`
ORIGINREALM=`grep ^ORIGINREALM conf.unl|awk -F '|' '{print $2}'`
#DRAADDR=`grep ^DRAADDR conf.unl|awk -F '|' '{print $2}'`
#DRAPORT=`grep ^DRAPORT conf.unl|awk -F '|' '{print $2}'`
DRATYPE=`grep ^DRATYPE conf.unl|awk -F '|' '{print $2}'|tr '[A-Z]' '[a-z]'`
LOCALPASSWD=`grep ^LOCALPASSWD conf.unl|awk -F '|' '{print $2}'`

############################################�ϴ�����װbaselib��
addrandpass=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|awk -F '|' '{print $4"|"$5}'|sort -u`
for addrapass in $addrandpass
do
#tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|wc -l`
#tempi='1'
#while  [ $tempi -le $tempnum ]
#do
###libaddr=$(grep -E "^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|MS|omsan|"|awk -F '|' ''NR==$tempi'{print $4}')
###libpass=$(grep -E "^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|MS|omsan|"|awk -F '|' ''NR==$tempi'{print $5}')
#	libtype=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|awk -F '|' ''NR==$tempi'{print $1}')
#	libhost=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|awk -F '|' ''NR==$tempi'{print $2}')
#	libname=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|awk -F '|' ''NR==$tempi'{print $3}')
#	libaddr=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|awk -F '|' ''NR==$tempi'{print $4}')
#	libpass=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|awk -F '|' ''NR==$tempi'{print $5}')
	libaddr=`echo $addrapass|awk -F '|' '{print $1}'`
	libpass=`echo $addrapass|awk -F '|' '{print $2}'`
	log4s info "��ʼ�ϴ�lib���Լ����ű���$libaddr"
	srcFile=`ls lib/*`
	for file in $srcFile
	do
		/usr/bin/expect <<-EOF
		set timeout 60
		spawn scp -oPort=$sshport -r $file root@$libaddr:/tmp/
		expect {
		"*yes/no" { send "yes\r"; exp_continue }
		"*assword:" { send "$libpass\r" }
		}
		expect eof
		EOF
	done
	/usr/bin/expect <<-EOF
	set timeout 60
	spawn scp -oPort=$sshport -r $0 root@$libaddr:/tmp/
	expect {
	"*yes/no" { send "yes\r"; exp_continue }
	"*assword:" { send "$libpass\r" }
	}
	expect eof
	EOF
	log4s info "����ϴ�lib���Լ����ű���$libaddr"
	fun_srcgo root $libaddr $libpass "nohup /tmp/SRCgo.sh baselib &"
	log4s info "$libaddr���ڽ���lib����װ���Ժ���鿴���н��"
done

############################################��װ32λlib����MS�������ϴ�������ǰ�������
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|MS|omsan|"|wc -l`
tempi='1'
while  [ $tempi -le $tempnum ]
do
	libaddr=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|MS|omsan|"|awk -F '|' ''NR==$tempi'{print $4}')
	libpass=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|MS|omsan|"|awk -F '|' ''NR==$tempi'{print $5}')
	fun_srcgo root $libaddr $libpass "nohup /tmp/SRCgo.sh lib &"
	log4s info "$libaddr���ڽ���lib����װ���Ժ���鿴���н��"
	tempi=`expr $tempi + 1`
done

############################################д��mysql group replication�����/etc/hosts������ȡgroup_seeds�Լ�mysql����ip
##########mysqlpri�����õ�ַ��mysqlsla�Ǳ��õ�ַ����ҵ�������ʹ�ã���allhost��Ҫд��/etc/hosts��������ַ��group_seeds��mysql group replication������Ϣ
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|mysql|"|grep -v "|ms|"|wc -l`
tempi='1'
allhost=''
mysqlpri='1.1.1.1'
mysqlsla='1.1.1.1'
group_seeds=''
while  [ $tempi -le $tempnum ]
do
	mysqlhost=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|mysql|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $6}')
	mysqlip=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|mysql|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $7}')
	mysqladd=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|mysql|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
	if [ $tempi -eq 1 ]
	then
		mysqlpri=$mysqladd
	fi
	if [ $tempi -eq 2 ]
	then
		mysqlsla=$mysqladd
	fi
	if [ $tempi -eq $tempnum ]
	then
		allhost+="${mysqlip} ${mysqlhost}"
		group_seeds+="${mysqlip}:24901"
	else
		allhost+="${mysqlip} ${mysqlhost}\n"
		group_seeds+="${mysqlip}:24901,"
	fi
	tempi=`expr $tempi + 1`
done
##########д���̨mysql����/etc/hosts��Ϣ
tempi='1'
while  [ $tempi -le $tempnum ]
do
	mysqlpass=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|mysql|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $5}')
	mysqlip=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|mysql|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $7}')
	mysqladd=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|mysql|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
	fun_addetchost ${mysqladd} ${mysqlpass} "${allhost}"
	tempi=`expr $tempi + 1`
done

############################################��ȡwebjoin server nginx����ķַ�����Ϣ
##########nginx_seeds�Ƿַ�����Ϣ
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|webjoin|"|grep -v "|ms|"|wc -l`
tempi='1'
nginx_seeds=''
while  [ $tempi -le $tempnum ]
do
	webip=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|webjoin|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
	if [ $tempi -eq $tempnum ]
	then
		nginx_seeds+="'${webip}:8080'"
	else
		nginx_seeds+="'${webip}:8080', "
	fi
	tempi=`expr $tempi + 1`
done

############################################��ȡnginx����ķַ�����Ϣ
##########ni_seeds��eop_ni�ַ�����Ϣ
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|eop_ni|"|grep -v "|ms|"|wc -l`
tempi='1'
ni_seeds=''
while  [ $tempi -le $tempnum ]
do
	webip=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|eop_ni|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
	if [ $tempi -eq $tempnum ]
	then
		ni_seeds+="${webip}:8100"
	else
		ni_seeds+="${webip}:8100 "
	fi
	tempi=`expr $tempi + 1`
done
##########as_seeds��eop_as�ַ�����Ϣ
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|eop_as|"|grep -v "|ms|"|wc -l`
tempi='1'
as_seeds=''
while  [ $tempi -le $tempnum ]
do
	webip=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|eop_as|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
	if [ $tempi -eq $tempnum ]
	then
		as_seeds+="${webip}:8100"
	else
		as_seeds+="${webip}:8100 "
	fi
	tempi=`expr $tempi + 1`
done
##########stack_seeds��eop_as�ַ�����Ϣ
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|httpstack|"|grep -v "|ms|"|wc -l`
tempi='1'
stack_seeds=''
while  [ $tempi -le $tempnum ]
do
	webip=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|httpstack|"|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
	if [ $tempi -eq $tempnum ]
	then
		stack_seeds+="${webip}:8100"
	else
		stack_seeds+="${webip}:8100 "
	fi
	tempi=`expr $tempi + 1`
done

###############################�������װ����ȥms���
sipdomainid='118'
bepdomainid='1'
sdfdomainid='11'
diadomainid='81'
mysqlservid='1'
fepdomainid='51'
tempnum=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep -v "|ms|"|wc -l`
tempi='1'
while  [ $tempi -le $tempnum ]
do
srctype=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $1}')
srchost=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $2}')
srcname=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $3}')
srcaddr=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $4}')
srcpass=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $5}')
cgaddr=$(grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep -v "|ms|"|awk -F '|' ''NR==$tempi'{print $7}')
if [ $srcname == mysql -a $srchost == MYSQL ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_addnewuser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh mysql \\\"$srcpass\\\" $cgaddr:24901 $mysqlservid \\\"$group_seeds\\\" &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
mysqlservid=`expr $mysqlservid + 1`
elif [ $srcname == webjoin -a $srchost == WEBJOIN ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh webjoin $OMSIP \\\"$nginx_seeds\\\" $mysqlpri:3306 \\\"$srcpass\\\" &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == eop_as -a $srchost == ISMP ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
fun_extftphost slrlua $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh ismpas $OMSIP:3000 \\\"$as_seeds\\\" $mysqlpri:3306 $mysqlsla:3306 \\\"$srcpass\\\" http &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == eop_ni -a $srchost == ISMP ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh ismp $OMSIP:3000 \\\"$ni_seeds\\\" $mysqlpri:3306 $mysqlsla:3306 \\\"$srcpass\\\" http &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == httpstack -a $srchost == ISMP ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh ismp $OMSIP:3000 \\\"$stack_seeds\\\" $mysqlpri:3306 $mysqlsla:3306 \\\"$srcpass\\\" \\\"http stack\\\" &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == httpfep -a $srchost == ISMP ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh httpfep $fepdomainid &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
fepdomainid=`expr $fepdomainid + 1`
elif [ $srcname == redis -a $srchost == REDIS ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh redis &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == sip -a $srchost == SIP ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh sip $sipdomainid $CLUSTER $OMSIP &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
sipdomainid=`expr $sipdomainid + 1`
elif [ $srcname == min -a $srchost == BEP ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh min $bepdomainid $CLUSTER $OMSIP $INFDIR $INFSER $INFCONF &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
bepdomainid=`expr $bepdomainid + 1`
elif [ $srcname == copyring -a $srchost == BEP ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh copyring $sdfdomainid $CLUSTER $OMSIP $INFDIR $INFSER $INFCONF &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
sdfdomainid=`expr $sdfdomainid + 1`
elif [ $srcname == dia -a $srchost == MS ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh dia $diadomainid $CLUSTER $OMSIP:3000 $cgaddr $DRATYPE $ORIGINHOST $ORIGINREALM &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
diadomainid=`expr $diadomainid + 1`
elif [ $srcname == mspre -a $srchost == MS ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh mspre $CLUSTER &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == mssip -a $srchost == MS ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh mssip 118 $CLUSTER $OMSIP &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == gealarm -a $srchost != DB ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh gealarm 16 $CLUSTER $OMSIP:3000 \\\"$srcpass\\\" &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == gealarm -a $srchost == DB ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh gealarm 16 $CLUSTER $OMSIP:3000 \\\"$srcpass\\\" $DBDIR $INFSER &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == omsan -a $srchost != DB -a $srchost != MS ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh omsan $CLUSTER $OMSIP \\\"$srcpass\\\" &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == omsan -a $srchost == DB ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh omsan $CLUSTER $OMSIP \\\"$srcpass\\\" $DBDIR $INFSER &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
elif [ $srcname == omsan -a $srchost == MS ]
then
log4s info "��ʼ����$srcname@$srcaddr��װ�ű�"
fun_adduser $srcname $srcaddr $srcpass
fun_ftphost $srcname $srcaddr $srcpass
sleep 2
fun_srcgo $srcname $srcaddr $srcpass "nohup ./SRCgo.sh omsan $CLUSTER $OMSIP \\\"$srcpass\\\" 32 &"
log4s info "$srcname@$srcaddr���ڽ��а�װ���Ժ���鿴���н��"
else
echo "δ֪ϵͳ�����˺�$srctype:$srchost:$srcname@$srcaddr"
fi
tempi=`expr $tempi + 1`
sleep 5
done

################################ms��װ
if [ `grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|grep "|ms|"|wc -l` != 0 ]
then
log4s info "��ʼ�ڱ����ϲ���automs����ms���һ����װ�ű�"
fun_msinstall
fi
}



###########�˲������˻������װ�Ƿ�ִ�����#####
######1.�˲��ļ�ȫ·����2.���һ�к˲���־���ݣ�3.ѭ��������4.ÿ��ѭ������ʱ��
checkprosess()
{
if [ ! -f "$1" ]
then
touch $1
chmod 777 $1
log4s info "�����ļ�$1"
fi
runntimes=0
while [ X"`tail -1 $1`" != X"$2" -a X"`tail -1 $1`" != X ]
do
	if [ $runntimes -lt $3 ]
	then
	sleep $4
	runntimes=`expr $runntimes + 1`
	log4s debug "��${runntimes}��ѭ��"
	else
	log4s info "�����ȶ�ִ��ʱ����δ��ʼ���г����˳��ýű�"
	exit 0
	fi
done
}

###########################Զ�̸�������װtcl�Լ�expect�������ֹ���������
fun_expinstall()
{
if [ ! -f "conf.unl" ]
then
echo "�����ļ�conf.unl�����ڣ������˳�"
log4s error "�����ļ�conf.unl�����ڣ������˳�"
exit 1
fi
expaddr=`grep -E "^EOP|^SCIM|^VIDEO|^SCPAS|^CLAS|^CENTREX" conf.unl|awk -F '|' '{print $4}'|sort -u`
for libaddr in $expaddr
do
	log4s info "��ʼ�ϴ�tcl�Լ�expect���Լ����ű���$libaddr"
	srcFile=`ls lib/tcl*x86_64.rpm lib/expect*x86_64.rpm`
	for file in $srcFile
	do
		scp -oPort=$sshport -r $file root@$libaddr:/tmp/
	done
	ssh -oPort=$sshport root@$libaddr "cd /tmp/;nohup rpm -ivh tcl*x86_64.rpm  --force --nodeps &"
	ssh -oPort=$sshport root@$libaddr "cd /tmp/;nohup rpm -ivh expect*x86_64.rpm  --force --nodeps &"
done
}

if [ $# = 1 -a $1 = install ]
then
	log4s debug "��ʼ����install����"
	fun_install
	log4s debug "install�����������"
elif [ $# = 1 -a $1 = expinstall ]
then
	log4s debug "��ʼ����expinstall����"
	fun_expinstall
	log4s debug "expinstall�����������"
elif [ $# = 1 -a $1 = lib ]
then
	log4s info "��ʼ��װlib��"
	log4s debug "��ʼ����libinstall����"
	fun_libinstall
elif [ $# = 1 -a $1 = baselib ]
then
	log4s info "��ʼ��װbaselib��"
	log4s debug "��ʼ����baselibinstall����"
	fun_baselibinstall
elif [ $# = 4 -a $1 = sip ]
then
	log4s info "��ʼ��װsip���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start sip install" >> /tmp/install.log
	log4s info "start sip installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����sipinstall����"
	fun_sipinstall $envprofile $2 $3 $4
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "sip�����װ���"
elif [ $# = 5 -a $1 = gealarm ]
then
	log4s info "��ʼ��װgealarm���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start gealarm install" >> /tmp/install.log
	log4s info "start gealarm installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����geinstall����"
	fun_geinstall $envprofile $2 $3 $4 $5
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "gealarm�����װ���"
elif [ $# = 7 -a $1 = gealarm ]
then
	log4s info "��ʼ��װgealarm���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start gealarm install" >> /tmp/install.log
	log4s info "start gealarm installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����geinstall����"
	fun_geinstall $envprofile $2 $3 $4 $5 $6 $7
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "gealarm�����װ���"
elif [ $# = 4 -a $1 = omsan ]
then
	log4s info "��ʼ��װomsan���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start omsan install" >> /tmp/install.log
	log4s info "start omsan installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����aninstall����"
	fun_aninstall $envprofile $2 $3 $4
	log4s debug "��ʼ����pfmcinstall����"
	fun_pfmcinstall $envprofile
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "omsan�����װ���"
elif [ $# = 5 -a $1 = omsan ]
then
	log4s info "��ʼ��װomsan���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start omsan install" >> /tmp/install.log
	log4s info "start omsan installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����aninstall����"
	fun_aninstall $envprofile $2 $3 $4
	log4s debug "��ʼ����pfmcinstall����"
	fun_pfmcinstall $envprofile $5
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "omsan�����װ���"
elif [ $# = 6 -a $1 = omsan ]
then
	log4s info "��ʼ��װomsan���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start omsan install" >> /tmp/install.log
	log4s info "start omsan installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����aninstall����"
	fun_aninstall $envprofile $2 $3 $4 $5 $6
	log4s debug "��ʼ����pfmcinstall����"
	fun_pfmcinstall $envprofile
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "omsan�����װ���"
elif [ $# = 7 -a $1 = min ]
then
	log4s info "��ʼ��װ��̨���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start min install" >> /tmp/install.log
	log4s info "start bep installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����bepinstall����"
	fun_bepinstall $envprofile $2 $3 $4 $5 $6 $7
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "��̨�����װ���"
elif [ $# = 7 -a $1 = copyring ]
then
	log4s info "��ʼ��װ�����˻����"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start copyring install" >> /tmp/install.log
	log4s info "start copyring installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����bepinstall����"
	fun_bepinstall $envprofile $2 $3 $4 $5 $6 $7
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "�����˻������װ���"
elif [ $# = 3 -a $1 = informix ]
then
	log4s info "��ʼ��װ���ݿ�alarmAPI���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start alarmAPI install" >> /tmp/install.log
	log4s info "start alarmAPI installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����apiinstall����"
	fun_apiinstall $envprofile $2 $3
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "���ݿ�alarmAPI�����װ���"
elif [ $# = 3 -a $1 = ss7 ]
then
	log4s info "��ʼ��װn7server���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start n7server install" >> /tmp/install.log
	log4s info "start n7server installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����ss7install����"
	fun_ss7install $envprofile $2 $3
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "n7server�����װ���"
elif [ $# = 8 -a $1 = dia ]
then
	log4s info "��ʼ��װdiameter���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start diameter install" >> /tmp/install.log
	log4s info "start diameter installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����diainstall����"
	fun_diainstall $envprofile $2 $3 $4 $5 $6 $7 $8
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "diameter�����װ���"
elif [ $# = 2 -a $1 = mspre ]
then
	log4s info "��ʼ��װmspre���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start mspre install" >> /tmp/install.log
	log4s info "start mspre installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����mspreinstall����"
	fun_mspreinstall $envprofile $2
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "mspre�����װ���"
elif [ $# = 4 -a $1 = mssip ]
then
	log4s info "��ʼ��װmssip���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start mssip install" >> /tmp/install.log
	log4s info "start mssip installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����sipinstall����"
	fun_sipinstall $envprofile $2 $3 $4
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "mssip�����װ���"
elif [ $# = 5 -a $1 = mysql ]
then
	log4s info "��ʼ��װmysql���"
	log4s debug "��ʼ����mysqlinstall����"
	fun_mysqlinstall $envprofile "$2" $3 $4 "$5"
	log4s info "mysql�����װ���"
elif [ $# = 5 -a $1 = webjoin ]
then
	log4s info "��ʼ��װwebjoin���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start webjoin install" >> /tmp/install.log
	log4s info "start webjoin installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����webinstall����"
	fun_webinstall $envprofile $2 "$3" $4 "$5"
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "webjoin�����װ���"
elif [ $# = 7 -a $1 = ismpas ]
then
	log4s info "��ʼ��װismp���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start ismp install" >> /tmp/install.log
	log4s info "start ismp installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����ismpinstall����"
	fun_ismpinstall $envprofile $2 "$3" $4 $5 "$6" "$7"
	fun_eopluainstall
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "ismp�����װ���"
elif [ $# = 7 -a $1 = ismp ]
then
	log4s info "��ʼ��װismp���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start ismp install" >> /tmp/install.log
	log4s info "start ismp installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����ismpinstall����"
	fun_ismpinstall $envprofile $2 "$3" $4 $5 "$6" "$7"
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "ismp�����װ���"
elif [ $# = 2 -a $1 = httpfep ]
then
	log4s info "��ʼ��װhttpfep���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start httpfep install" >> /tmp/install.log
	log4s info "start httpfep installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����ismpinstall����"
	fun_httpfepinstall $envprofile $2
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "httpfep�����װ���"
elif [ $# = 1 -a $1 = redis ]
then
	log4s info "��ʼ��װredis���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start redis install" >> /tmp/install.log
	log4s info "start redis installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����redisinstall����"
	fun_redisinstall
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "redis�����װ���"
fi
