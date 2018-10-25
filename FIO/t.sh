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
################log4s配置区#################
log4spath=$doDIR								#输出日志目录
log4sechoCategory=info				#输出到屏幕日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4swriteCategory=debug			#输出到文件日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4slogname=root.log					#输出日志名称
isecho=1											#输出到日志的同时是否打印到屏幕，0是不打印，1是打印
splittype=none								#日志分割方式，none不分割，day按照日期分割后缀名为YYYY-MM-DD，num为按照行模式分割，如果使用num模式则必须填写splitnum参数，这个没思路暂不支持
splitnum=1000
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
#				log4s debug "当前rw值为${rwi}，当前rwmixwrite参数值为${rwmicommand}，当前ioengine值为${ioenginei}，当前bs值为${bsi}，当前numjobs值为${numjobsi}"
#				let commandi=commandi+1
#				testname=${name}${commandi}
#				command="fio -filename=${filename} -direct=1 -iodepth 1 -thread -rw=${rwi} ${rwmicommand} -ioengine=${ioenginei} -bs=${bsi} -size=${size} -numjobs=${numjobsi} -runtime=${testruntime} -group_reporting -name=${testname}"
#				echo "${testname}.${rwi}.testreslut|${command}" >> $worktemp
#				log4s info "当前运行测试项${testname}"
#				$command >> ${testname}.${rwi}.testreslut
#			done
#		done
#	done
#done
#log4s info "测试项目运行完成，开始比较最优测试参数"
#
#log4s info "统计最优参数"
#>$finalcommandfile
tongji()
{
	#接受一个参数，是当前读写模式
	greatfilenum=0
	greatfilename=0
	mubiaotype=$1
	okfilename=${name}_${mubiaotype}
	log4s info "进入${mubiaotype}的统计比较循环"
	while read h
	do
		nowfilesname=`echo "$h"|awk -F'|' '{print $1}'`
		rwtype=`echo "$h"|awk -F'|' '{print $1}'|awk -F'.' '{print $2}'`
		if [ X$rwtype = X$mubiaotype ]
		then
			newnum=`grep BW $nowfilesname|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length())=="k"){ print substr($0,0,length()-1)*1000}else{print $0}}'`
			log4s info "$nowfilesname 中的值为 $newnum"
			if [ $newnum -gt $greatfilenum ]
			then
				greatfilenum=$newnum
				greatfilename=$nowfilesname
				log4s info "新的最大值 $greatfilenum ，该文件名为 $greatfilename"
			fi
		fi
		log4s debug "当前统计类型为${rwtypei}，当前统计的文件名为${nowfilesname}，当前bw最大值为${greatfilenum}，当前最大值文件为${greatfilename}"
	done<$worktemp
	log4s debug "${rwtypei}，最终结果：当前bw最大值为${greatfilenum}，当前最大值文件为${greatfilename}"
	grep ${greatfilename} ${worktemp} |awk -F'|' '{print $2}' |sed "s/-runtime=${testruntime}/-runtime=${finalruntime}/g"|awk  'BEGIN{FS="=";OFS="="} {print $1,$2,$3,$4,$5,$6,$7,$8,$9};{printf("\n")}'|awk -v okfilename=$okfilename 'BEGIN{FS="=";OFS="="} {print $0,okfilename}'|head -1>>$finalcommandfile
}

for rwj in ${rw[*]}; do
	tongji $rwj
done

log4s info "最终命令在$finalcommandfile ，开始执行最终命令"
while read h
do
	finalresfilename=`echo $h|awk -F'=' '{print $10}'`
	log4s info "当前执行结果保存在 $finalresfilename 中"
	$h > $finalresfilename
done <$finalcommandfile