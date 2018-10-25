#!/bin/sh

doDIR=`pwd`
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
dH=`date +"%Y%m%d%H"`
dHonly=`date +"%H"`
dMonly=`date +"%M"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dSn=`date +"%Y-%m-%d %H:%M:%S"`
dMonly=`date +"%M"`
log=$doDIR/testfio.log
libaiorpmfile=libaio-devel-0.3.107-10.el6.x86_64.rpm
anzhuangbao=fio-fio-2.99.tar.gz
worktemp=$doDIR/tempfio.temp
finalcommandfile=$doDIR/finallcommand.file
baogao=$doDIR/result.$dS.html
lvname=/dev/dbvg/testlv				#Ҫ��
name=mytest
bakdir=${doDIR}/${name}bak
testsize=1G
finalsize=2G
testruntime=30									#Ҫ��
finalruntime=600								#Ҫ��
rw=("randwrite" "randread" "randrw" "read" "write" "rw")
rwmixwrite=50
ioengine=("libaio" "psync")

#��ʼ��������
test1n=1
test2n=50
test3n=100
#������λ��ÿ�����ӻ��߼��ٵĵ�λ
stepn=1
setbs()
{
	if [ $1 = libaio ]
	then
		bs=("2k" "8k")
	elif [ $1 = psync ]
	then
		bs=("256k" "1024k")
	fi
}
setrwmix()
{
	if [ $rwforrwmix = randrw ] || [ $rwforrwmix = rw ]
	then
		rwmicommand="-rwmixwrite=$rwmixwrite"
	else
		rwmicommand=""
	fi
}




testflag=0
if [ $testflag = 1 ]
then
	rw=("randwrite" "randread")
fi
wai=`whoami`
################log4s������#################
log4spath=$doDIR								#�����־Ŀ¼
log4sechoCategory=info				#�������Ļ��־�������ƣ�������debug=0��warn=1��info=2��error=3
log4swriteCategory=debug			#������ļ���־�������ƣ�������debug=0��warn=1��info=2��error=3
log4slogname=root.log					#�����־����
isecho=0											#�������־��ͬʱ�Ƿ��ӡ����Ļ��0�ǲ���ӡ��1�Ǵ�ӡ
splittype=none								#��־�ָʽ��none���ָday�������ڷָ��׺��ΪYYYY-MM-DD��numΪ������ģʽ�ָ���ʹ��numģʽ�������дsplitnum���������û˼·�ݲ�֧��
splitnum=1000
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


preinit()
{
	>$worktemp
	if [ ! -d $bakdir ]
	then
		mkdir $bakdir
	fi
	mv $doDIR/${name}* $bakdir 1>/dev/null 2>&1

}


fiorun()
{
	let rwruncount=rwruncount+1
	#���ص�ǰBWֵ
	log4s debug "fiorun: ����fiorun"
	filename=$1
	bst=$2
	sizet=$3
	ioenginet=$4
	rwt=$5
	numjobst=$6
	rwmicommandt=$7
	dS=`date +"%Y%m%d%H%M%S"`
	testnamet=${name}_${rwt}_${ioenginet}_${bst}_${numjobst}.test
	fio -filename=${filename} -direct=1 -iodepth 1 -thread -rw=${rwt} ${rwmicommandt} -ioengine=${ioenginet} -bs=${bst} -size=${sizet} -numjobs=${numjobst} -runtime=${testruntime} -group_reporting -name=${testnamet} > $doDIR/${testnamet}
	
	BWnum=`grep BW ${testnamet}|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length()-4,1)=="M"){ printf "%.f" ,substr($0,0,length()-5)*1024}else if(substr($0,length()-4,1)=="G"){ printf "%.f" ,substr($0,0,length()-5)*1024*1024}else{print substr($0,0,length()-5)}}'`
	log4s debug "fiorun: ��ǰ������������"
	log4s debug "fiorun: fio -filename=${filename} -direct=1 -iodepth 1 -thread -rw=${rwt} ${rwmicommandt} -ioengine=${ioenginet} -bs=${bst} -size=${sizet} -numjobs=${numjobst} -runtime=${testruntime} -group_reporting -name=${testnamet} > $doDIR/${testnamet}"
	log4s debug "fiorun: ��ǰBWֵΪ${BWnum}����ǰnumjobsֵΪ${numjobst}"
	
	if [ X$BWnum = X ] || [ X$numjobst = X ]
	then
		log4s error "fiorun: fio�����쳣���������"
	fi
	log4s info "fiorun: ���ؽ��Ϊ:$BWnum"
	log4s debug "fiorun: fiorun����"
	echo "$BWnum"
}
njobrun()
{
	
	#��������job
	log4s debug "njobrun: ����njobrun"
	filename=$1
	bst=$2
	sizet=$3
	ioenginet=$4
	rwt=$5
	rwmicommandt=$6
	#˼·��Ҫ��3��Զ����1��njob���ж�3��1�Ľ��˭���ڴ�ĵ��м��������������ԣ����һ������ô3��1��njob�ֱ�ݽ�10����
	
	njob1=$test1n
	njob2=$test2n
	njob3=$test3n

	log4s debug "njobrun: njobrunִ��num1����Ϊfiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt"
	log4s debug "njobrun: njobrunִ��num3����Ϊfiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt"
	num1=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt)
	num3=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt)

	njobtemp=0
	numtemp=0
	while true
	do
		log4s debug "njobrun: njobrunִ��num2����Ϊfiorun $filename $bst $sizet $ioenginet $rwt $njob2 $rwmicommandt"
		num2=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob2 $rwmicommandt)
		log4s debug "njobrun: ��ǰ��ȡ����num1-3�ֱ�Ϊ��$num1 $num2 $num3��"
		log4s debug "njobrun: ��ǰnjobs1-3�ֱ�Ϊ��$njob1 $njob2 $njob3"
		if [ $num3 -gt $num1 ]
		then
			njob1=$njob2
			njob3=$njob3
			num1=$num2
			let njob2=(njob3-njob1)/2/stepn*stepn+njob1
			log4s debug "njobrun: 3���������ܴ���1�ţ��µ�1������njobsΪ$njob1���µ�2������Ϊ$njob2���µ�3������Ϊ$njob3"
		elif [ $num3 -lt $num1 ]
		then
			njob1=$njob1
			njob3=$njob2
			num3=$num2
			let njob2=(njob3-njob1)/2/stepn*stepn+njob1
			log4s debug "njobrun: 1���������ܴ���3�ţ��µ�1������njobsΪ$njob1���µ�2������Ϊ$njob2���µ�3������Ϊ$njob3"
		else
			let njob1=njob1+10
			let njob3=njob3-10
			num1=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt)
			num3=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt)
			log4s debug "njobrun: njobrunִ��num1����Ϊfiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt"
			log4s debug "njobrun: njobrunִ��num3����Ϊfiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt"
			num1=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt)
			num3=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt)
			log4s debug "njobrun: 1���������ܵ���3�ţ��µ�1������njobsΪ$njob1���µ�2������Ϊ$njob2���µ�3������Ϊ$njob3"
		fi
		
		if [ $njob2 -le $njob1 ] || [ $njob2 -ge $njob3 ] || [ $njob3 -le $njob1 ]
		then
			log4s info "njobrun: njobrun��ȡ�����BWֵ����ǰBWֵΪ${num2}����ǰnumjobsֵΪ${njob2}����ǰ��������"
			log4s info "njobrun: fiorun $filename $bst $sizet $ioenginet $rwt $njob2 $rwmicommandt"
			log4s info "njobrun: ���ؽ��Ϊ:$njob2|$num2"
			log4s debug "njobrun: njobrun����"
			finalfilename="${rwt}_${ioenginet}_${bst}_final"
			echo "fio -filename=${filename} -direct=1 -iodepth 1 -thread -rw=${rwt} ${rwmicommandt} -ioengine=${ioenginet} -bs=${bst} -size=${sizet} -numjobs=${njob2} -runtime=${finalruntime} -group_reporting -name=${finalfilename}" >>$finalcommandfile
			echo "$njob2|$num2"
			break;
		fi
	done
}
norwgo()
{
	log4s debug "norwgo: ����norwgo"
	filename=$1
	rwt=$2
	sizet=$3
	okjob=0
	oknum=0
	okbs=0
	okioengine=0
	for ioenginei in ${ioengine[*]}; do
		rwforrwmix=$rwt
		setrwmix;
		setbs $ioenginei;
		for bsi in ${bs[*]}; do
			log4s debug "norwgo: norwgoִ������Ϊnjobrun $filename $bs $sizet $ioenginei $rwt $rwmicommand"
			njobresult=$(njobrun $filename $bsi $sizet $ioenginei $rwt $rwmicommand)
			okjobtemp=$(echo $njobresult|awk -F'|' '{print $1}')
			oknumtemp=$(echo $njobresult|awk -F'|' '{print $2}')
			if [ $oknumtemp -ge $oknum ]
			then
				oknum=$oknumtemp
				okjob=$okjobtemp
				okbs=$bsi
				okioengine=$ioenginei
			fi
		done
	done
	log4s info "norwgo: norwgo��ȡ����ǰ${rwt}�����BWֵ����ǰnumjobsΪ${okjob}����ǰBWΪ${oknum}����ǰbsΪ${okbs}����ǰioengineΪ${okioengine}"
	log4s info "norwgo: ���ؽ��Ϊ:$oknum|$okjob|$okbs|$okioengine"
	log4s debug "norwgo: norwgo����"
	log4s debug "norwgo: ȫ�����Ž�Ϊ��${rwt}  ${sizet} ${okbs} ${okioengine}"
	echo "$oknum|$okjob|$okbs|$okioengine"
}
rwgo()
{
	rwruncount=0
	#���ﲻ�ٽ��ܲ����������ǲ��Բ��������ѭ��
	#��������rw��ʽ��ÿ�ֻ�ȡ�����Ų���������ǰ��������д��$finalcommandfile�ļ�
	log4s debug "rwgo: ����rwgo"
	for rwi in ${rw[*]};do
		
		rwforrwmix=$rwi
		setrwmix;
		log4s debug "rwgo: rwgoִ������Ϊnorwgo $lvname $rwi $testsize"
		rwiresult=$(norwgo $lvname $rwi $testsize)
		rwiokbwnum=$(echo $rwiresult|awk -F'|' '{print $1}')
		rwiokjob=$(echo $rwiresult|awk -F'|' '{print $2}')
		rwiokbs=$(echo $rwiresult|awk -F'|' '{print $3}')
		rwiokoengine=$(echo $rwiresult|awk -F'|' '{print $4}')
	done
}


finalgo()
{
	log4s info "����������$finalcommandfile ����ʼִ����������"
	while read h
	do
		finalresfilename=`echo $h|awk -F'=' '{print $NF}'`
		log4s info "��ǰִ�н�������� $finalresfilename ��"
		$h > $finalresfilename
	done <$finalcommandfile
	log4s info "ȫ��ִ�����"
}


xhtml()
{
	echo $1 >> $baogao
}
fenxi()
{
	#$1���ļ���������4�������ֱ��ǲ��Ե�5���������ֱ�Ϊ��2"rw��ʽ" 3"libaio����psync" 4"bs��С" 5"jobs��" 6"�����к�"
	fxfilename=$1
	hanghao=$6
	log4s info "��ʼ����${fxfilename}"
	rwtype=`echo ${fxfilename} |awk -F'_' '{print $1}'`
	
	if [ X$rwtype = Xread ] || [ X$rwtype = Xrandread ]
	then
		#���������
		log4s debug "������ļ���������"
		fx_r_IOPS=`cat       $fxfilename|grep IOPS|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f" ,substr($0,0,length())*1000}else if(substr($0,length(),1)=="m"){ printf "%.f" ,substr($0,0,length())*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_BW=`cat         $fxfilename|grep BW|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length()-4,1)=="M"){ printf "%.f" ,substr($0,0,length()-5)*1024}else if(substr($0,length()-4,1)=="G"){ printf "%.f" ,substr($0,0,length()-5)*1024*1024}else{print substr($0,0,length()-5)}}'`
		if [ X$3 = Xpsync ]
		then
			fx_r_slat_flag=NULL
			fx_r_slat_min=NULL
			fx_r_slat_max=NULL
			fx_r_slat_avg=NULL
			fx_r_slat_stdev=NULL
		else
			fx_r_slat_flag=`cat  $fxfilename|grep slat|grep min|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
			fx_r_slat_min=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
			fx_r_slat_max=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
			fx_r_slat_avg=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
			fx_r_slat_stdev=`cat $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		fi
		fx_r_clat_flag=`cat  $fxfilename|grep clat|grep min|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_r_clat_min=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
		fx_r_clat_max=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
		fx_r_clat_avg=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
		fx_r_clat_stdev=`cat $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		fx_r_lat_flag=`cat   $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_r_lat_min=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
		fx_r_lat_max=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
		fx_r_lat_avg=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
		fx_r_lat_stdev=`cat  $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		let yushu=hanghao%2
		if [ X$yushu = X1 ]
		then
			ji_ou=ji
		else
			ji_ou=ou
		fi
		xhtml "<tr>"
		xhtml "<th>$fxfilename</th>"
		xhtml "<td class=\"$ji_ou\">$2</td>"
		xhtml "<td class=\"$ji_ou\">$3</td>"
		xhtml "<td class=\"$ji_ou\">$4</td>"
		xhtml "<td class=\"$ji_ou\">$5</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_IOPS</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_BW</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_stdev</td>"
		xhtml "</tr>"
	elif [ X$rwtype = Xwrite ] || [ X$rwtype = Xrandwrite ]
	then
		#д�������
		log4s debug "����д�ļ���������"
		fx_w_IOPS=`cat       $fxfilename|grep IOPS|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f" ,substr($0,0,length())*1000}else if(substr($0,length(),1)=="m"){ printf "%.f" ,substr($0,0,length())*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_BW=`cat         $fxfilename|grep BW|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length()-4,1)=="M"){ printf "%.f" ,substr($0,0,length()-5)*1024}else if(substr($0,length()-4,1)=="G"){ printf "%.f" ,substr($0,0,length()-5)*1024*1024}else{print substr($0,0,length()-5)}}'`
		if [ X$3 = Xpsync ]
		then
			fx_w_slat_flag=NULL
			fx_w_slat_min=NULL
			fx_w_slat_max=NULL
			fx_w_slat_avg=NULL
			fx_w_slat_stdev=NULL
			fx_w_slat_flag=NULL
		else
			fx_w_slat_flag=`cat  $fxfilename|grep slat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
			fx_w_slat_min=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
			fx_w_slat_max=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
			fx_w_slat_avg=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
			fx_w_slat_stdev=`cat $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
			fx_w_slat_flag=`cat  $fxfilename|grep clat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fi
		fx_w_clat_flag=`cat  $fxfilename|grep clat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_w_clat_min=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
		fx_w_clat_max=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
		fx_w_clat_avg=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
		fx_w_clat_stdev=`cat $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		fx_w_lat_flag=`cat   $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_w_lat_min=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
		fx_w_lat_max=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
		fx_w_lat_avg=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
		fx_w_lat_stdev=`cat  $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		let yushu=hanghao%2
		if [ X$yushu = X1 ]
		then
			ji_ou=ji
		else
			ji_ou=ou
		fi
		xhtml "<tr>"
		xhtml "<th>$fxfilename</th>"
		xhtml "<td class=\"$ji_ou\">$2</td>"
		xhtml "<td class=\"$ji_ou\">$3</td>"
		xhtml "<td class=\"$ji_ou\">$4</td>"
		xhtml "<td class=\"$ji_ou\">$5</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_IOPS</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_BW</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_stdev</td>"
		xhtml "</tr>"
	elif [ X$rwtype = Xrw ] || [ X$rwtype = Xrandrw ]
	then
		#��϶�д����
		log4s debug "�����϶�д�ļ���������"
		fx_r_IOPS=`cat       $fxfilename|grep IOPS|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f" ,substr($0,0,length())*1000}else if(substr($0,length(),1)=="m"){ printf "%.f" ,substr($0,0,length())*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_BW=`cat         $fxfilename|grep BW|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length()-4,1)=="M"){ printf "%.f" ,substr($0,0,length()-5)*1024}else if(substr($0,length()-4,1)=="G"){ printf "%.f" ,substr($0,0,length()-5)*1024*1024}else{print substr($0,0,length()-5)}}'`
		fx_r_clat_flag=`cat  $fxfilename|grep clat|grep min|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_r_clat_min=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
		fx_r_clat_max=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
		fx_r_clat_avg=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
		fx_r_clat_stdev=`cat $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		fx_r_lat_flag=`cat   $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_r_lat_min=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
		fx_r_lat_max=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
		fx_r_lat_avg=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
		fx_r_lat_stdev=`cat  $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		if [ X$3 = Xpsync ]
		then
			fx_w_slat_flag=NULL
			fx_w_slat_min=NULL
			fx_w_slat_max=NULL
			fx_w_slat_avg=NULL
			fx_w_slat_stdev=NULL
			fx_w_slat_flag=NULL
			fx_r_slat_flag=NULL
			fx_r_slat_min=NULL
			fx_r_slat_max=NULL
			fx_r_slat_avg=NULL
			fx_r_slat_stdev=NULL
		else
			fx_r_slat_flag=`cat  $fxfilename|grep slat|grep min|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
			fx_r_slat_min=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
			fx_r_slat_max=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
			fx_r_slat_avg=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
			fx_r_slat_stdev=`cat $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
			fx_w_slat_flag=`cat  $fxfilename|grep slat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
			fx_w_slat_min=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
			fx_w_slat_max=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
			fx_w_slat_avg=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
			fx_w_slat_stdev=`cat $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
			fx_w_slat_flag=`cat  $fxfilename|grep clat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fi
		fx_w_IOPS=`cat       $fxfilename|grep IOPS|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f" ,substr($0,0,length())*1000}else if(substr($0,length(),1)=="m"){ printf "%.f" ,substr($0,0,length())*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_BW=`cat         $fxfilename|grep BW|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length()-4,1)=="M"){ printf "%.f" ,substr($0,0,length()-5)*1024}else if(substr($0,length()-4,1)=="G"){ printf "%.f" ,substr($0,0,length()-5)*1024*1024}else{print substr($0,0,length()-5)}}'`
		fx_w_clat_flag=`cat  $fxfilename|grep clat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_w_clat_min=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
		fx_w_clat_max=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
		fx_w_clat_avg=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
		fx_w_clat_stdev=`cat $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		fx_w_lat_flag=`cat   $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_w_lat_min=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'`
		fx_w_lat_max=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'`
		fx_w_lat_avg=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'`
		fx_w_lat_stdev=`cat  $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
		let hang1=hanghao-1
		hang2=$hanghao
		let yushu=hang1%2
		if [ X$yushu = X1 ]
		then
			ji_ou=ji
		else
			ji_ou=ou
		fi
		xhtml "<tr>"
		xhtml "<th rowspan=\"2\">$fxfilename</th>"
		xhtml "<td class=\"$ji_ou\">$2</td>"
		xhtml "<td class=\"$ji_ou\">$3</td>"
		xhtml "<td class=\"$ji_ou\">$4</td>"
		xhtml "<td class=\"$ji_ou\">$5</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_IOPS</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_BW</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_lat_stdev</td>"
		xhtml "</tr>"
		xhtml "<tr>"
		let yushu=hang2%2
		if [ X$yushu = X1 ]
		then
			ji_ou=ji
		else
			ji_ou=ou
		fi
		xhtml "<td class=\"$ji_ou\">$2</td>"
		xhtml "<td class=\"$ji_ou\">$3</td>"
		xhtml "<td class=\"$ji_ou\">$4</td>"
		xhtml "<td class=\"$ji_ou\">$5</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_IOPS</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_BW</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_flag</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_lat_stdev</td>"
		xhtml "</tr>"
	else
		#�쳣����
		log4s error "�ļ�rw�����޷�ʶ��������"
	fi
}

gohtml()
{
	>$baogao
	#htmlͷ��
	xhtml "<html>"
	xhtml "<head>"
	xhtml "<title>FIO���Ա���</title>"
	xhtml "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"
	xhtml "<style>"
	xhtml "table"
	xhtml "{"
	xhtml "	border:1px solid;"
	xhtml "	border-collapse:collapse;"
	xhtml "}"
	xhtml "table tr,td"
	xhtml "{"
	xhtml "	border:1px solid black;"
	xhtml "}"
	xhtml ".ji"
	xhtml "{"
	xhtml " background-color:#c7e5ff"
	xhtml "}"
	xhtml ""
	xhtml ".ou"
	xhtml "{"
	xhtml " background-color:#eaf5ff"
	xhtml "}"
	xhtml "table th"
	xhtml "{"
	xhtml "	border:1px solid;"
	xhtml "	border-collapse:collapse;"
	xhtml "}"
	xhtml "</style>"
	xhtml "</head>"
	xhtml "<body>" 
	xhtml "<table>"
	xhtml "<tr>"
	xhtml "<th>��������</th>"
	xhtml "<th colspan=\"4\">����</th>"
	xhtml "<th colspan=\"17\">���</th>"
	xhtml "</tr>"
	xhtml "<tr>"
	xhtml "<th></th>"
	xhtml "<th>rw</th>"
	xhtml "<th>���Է�ʽ</th>"
	xhtml "<th>bs��С</th>"
	xhtml "<th>jobs����</th>"
	xhtml "<th>IOPS</th>"
	xhtml "<th>BW</th>"
	xhtml "<th>slat��λ</th>"
	xhtml "<th>slat_min</th>"
	xhtml "<th>slat_max</th>"
	xhtml "<th>slat_avg</th>"
	xhtml "<th>slat_sthev</th>"
	xhtml "<th>clat��λ</th>"
	xhtml "<th>clat_min</th>"
	xhtml "<th>clat_max</th>"
	xhtml "<th>clat_avg</th>"
	xhtml "<th>clat_sthev</th>"
	xhtml "<th>lat��λ</th>"
	xhtml "<th>lat_min</th>"
	xhtml "<th>lat_max</th>"
	xhtml "<th>lat_avg</th>"
	xhtml "<th>lat_sthev</th>"
	xhtml "</tr>"
	hangnum=1
	while read hang
	do
		ceshimingcheng=`echo $hang|awk -F'=' '{print $NF}'`
		ceshirw=`echo $hang|awk '{print $7}'|awk -F'=' '{print $NF}'`
		if [ X$ceshirw = Xrw ] || [ X$ceshirw = Xrandrw ]
		then
			ceshirw=`echo $hang|awk '{print $7}'|awk -F'=' '{print $NF}'`
			ceshifangshi=`echo $hang|awk '{print $9}'|awk -F'=' '{print $NF}'`
			ceshibs=`echo $hang|awk '{print $10}'|awk -F'=' '{print $NF}'`
			ceshijobs=`echo $hang|awk '{print $12}'|awk -F'=' '{print $NF}'`
			let hangnum=hangnum+2
		else
			ceshirw=`echo $hang|awk '{print $7}'|awk -F'=' '{print $NF}'`
			ceshifangshi=`echo $hang|awk '{print $8}'|awk -F'=' '{print $NF}'`
			ceshibs=`echo $hang|awk '{print $9}'|awk -F'=' '{print $NF}'`
			ceshijobs=`echo $hang|awk '{print $11}'|awk -F'=' '{print $NF}'`
			let hangnum=hangnum+1
		fi

		fenxi "$ceshimingcheng" "$ceshirw" "$ceshifangshi" "$ceshibs" "$ceshijobs" "hangnum"
		
	done < $finalcommandfile
	#html��β
	xhtml "</table>"
	xhtml "</body></html>"
}

anzhuang()
{
	if [ $wai != root ]
	then
		log4s error "����root�˻�ִ��"
		exit 1;
	fi
	#�ж�libaio�Ƿ�װ
	libaio1=`rpm -qa|grep libaio|wc -l|awk '{print $1}'`
	libaio2=`rpm -qa|grep libaio-devel|wc -l|awk '{print $1}'`
	if [ $libaio1 -lt 2 ] || [ $libaio2 -lt 1 ]
	then
		log4s info "������libaio��ȫ�����Ȱ�װlibaio"
		if [ ! -f $doDIR/$libaiorpmfile ]
		then
			log4s error "�����������ڣ��޷���װ"
			exit 1;
		else
			rpm -ivh $doDIR/$libaiorpmfile 1>$doDIR/rpm.log 2>&1
			if [ $? = 0 ]
			then
				log4s info "��������װ���"
			else
				log4s error "��������װ�쳣�����ֶ�����"
				exit 1;
			fi
		fi
	fi
	#��װfio��
	if [ ! -f $doDIR/$anzhuangbao ]
	then
		log4s error "fio��װ��������"
	fi
	cd $doDIR;
	tar -xvf $anzhuangbao
	cd fio-fio-2.99;
	./configure;
	if [ $? = 0 ]
	then
		log4s info "configure ���óɹ�"
	else
		log4s error "configure ����ʧ��"
		exit 1;
	fi
	make all;
	if [ $? = 0 ]
	then
		log4s info "make all ����ɹ�"
	else
		log4s error "make all ����ʧ��"
		exit 1;
	fi
	make install;
	if [ $? = 0 ]
	then
		log4s info "make install ��װ�ɹ�"
	else
		log4s error "make install ��װʧ��"
		exit 1;
	fi
}

if [ $1 = go ]
then
	preinit;
	rwgo;
	finalgo;
	gohtml;
fi

if [ $1 = anzhuang ]
then
	anzhuang
fi
