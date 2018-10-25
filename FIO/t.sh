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
worktemp=$doDIR/tempfio.temp
finalcommandfile=$doDIR/finallcommand.file
filename=/dev/hdvg/testfiolv
name=mytest
bakdir=${doDIR}/${name}bak
size=1G
testruntime=3
finalruntime=5
rw=("randwrite" "randread" "randrw" "read" "write" "rw")
rwmixwrite=50
setbs()
{
	if [ $ioengine = libaio ]
	then
		bs=("2k" "8k")
	elif [ $ioengine = psync ]
	then
		bs=("256k" "1024k")
	fi
}
ioengine=("libaio" "psync")
numjobs=("30" "60" "90" "120")
################log4s������#################
log4spath=$doDIR								#�����־Ŀ¼
log4sechoCategory=info				#�������Ļ��־�������ƣ�������debug=0��warn=1��info=2��error=3
log4swriteCategory=debug			#������ļ���־�������ƣ�������debug=0��warn=1��info=2��error=3
log4slogname=root.log					#�����־����
isecho=1											#�������־��ͬʱ�Ƿ��ӡ����Ļ��0�ǲ���ӡ��1�Ǵ�ӡ
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


setrwmix()
{
	if [ $rw = randrw ] || [ $rw = rw ]
	then
		rwmicommand="-rwmixwrite=$rwmixwrite"
	fi
}

ioengine=("libaio" "psync")
numjobs=("30" "60" "90" "120")

#commandi=0
#>$worktemp
#if [ ! -d $bakdir ]
#then
#	mkdir $bakdir
#fi
#mv $doDIR/${testname}* $bakdir 1>/dev/null 2>&1
#for rwi in ${rw[*]}; do
#	setrwmix
#	for ioenginei in ${ioengine[*]}; do
#		setbs
#		for bsi in ${bs[*]}; do
#			for numjobsi in ${numjobs[*]}; do
#				log4s debug "��ǰrwֵΪ${rwi}����ǰrwmixwrite����ֵΪ${rwmicommand}����ǰioengineֵΪ${ioenginei}����ǰbsֵΪ${bsi}����ǰnumjobsֵΪ${numjobsi}"
#				let commandi=commandi+1
#				testname=${name}${commandi}
#				command="fio -filename=${filename} -direct=1 -iodepth 1 -thread -rw=${rwi} ${rwmicommand} -ioengine=${ioenginei} -bs=${bsi} -size=${size} -numjobs=${numjobsi} -runtime=${testruntime} -group_reporting -name=${testname}"
#				echo "${testname}.${rwi}.testreslut|${command}" >> $worktemp
#				log4s info "��ǰ���в�����${testname}"
#				$command >> ${testname}.${rwi}.testreslut
#			done
#		done
#	done
#done
#log4s info "������Ŀ������ɣ���ʼ�Ƚ����Ų��Բ���"
#
#log4s info "ͳ�����Ų���"
#>$finalcommandfile
tongji()
{
	#����һ���������ǵ�ǰ��дģʽ
	greatfilenum=0
	greatfilename=0
	mubiaotype=$1
	okfilename=${name}_${mubiaotype}
	log4s info "����${mubiaotype}��ͳ�ƱȽ�ѭ��"
	while read h
	do
		nowfilesname=`echo "$h"|awk -F'|' '{print $1}'`
		rwtype=`echo "$h"|awk -F'|' '{print $1}'|awk -F'.' '{print $2}'`
		if [ X$rwtype = X$mubiaotype ]
		then
			newnum=`grep BW $nowfilesname|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length())=="k"){ print substr($0,0,length()-1)*1000}else{print $0}}'`
			log4s info "$nowfilesname �е�ֵΪ $newnum"
			if [ $newnum -gt $greatfilenum ]
			then
				greatfilenum=$newnum
				greatfilename=$nowfilesname
				log4s info "�µ����ֵ $greatfilenum �����ļ���Ϊ $greatfilename"
			fi
		fi
		log4s debug "��ǰͳ������Ϊ${rwtypei}����ǰͳ�Ƶ��ļ���Ϊ${nowfilesname}����ǰbw���ֵΪ${greatfilenum}����ǰ���ֵ�ļ�Ϊ${greatfilename}"
	done<$worktemp
	log4s debug "${rwtypei}�����ս������ǰbw���ֵΪ${greatfilenum}����ǰ���ֵ�ļ�Ϊ${greatfilename}"
	grep ${greatfilename} ${worktemp} |awk -F'|' '{print $2}' |sed "s/-runtime=${testruntime}/-runtime=${finalruntime}/g"|awk  'BEGIN{FS="=";OFS="="} {print $1,$2,$3,$4,$5,$6,$7,$8,$9};{printf("\n")}'|awk -v okfilename=$okfilename 'BEGIN{FS="=";OFS="="} {print $0,okfilename}'|head -1>>$finalcommandfile
}

for rwj in ${rw[*]}; do
	tongji $rwj
done

log4s info "����������$finalcommandfile ����ʼִ����������"
while read h
do
	finalresfilename=`echo $h|awk -F'=' '{print $10}'`
	log4s info "��ǰִ�н�������� $finalresfilename ��"
	$h > $finalresfilename
done <$finalcommandfile