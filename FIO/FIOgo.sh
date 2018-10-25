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
lvname=/dev/dbvg/testlv				#要改
name=mytest
bakdir=${doDIR}/${name}bak
testsize=1G
finalsize=2G
testruntime=30									#要改
finalruntime=600								#要改
rw=("randwrite" "randread" "randrw" "read" "write" "rw")
rwmixwrite=50
ioengine=("libaio" "psync")

#初始测试三次
test1n=1
test2n=50
test3n=100
#步进单位，每次增加或者减少的单位
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
################log4s配置区#################
log4spath=$doDIR								#输出日志目录
log4sechoCategory=info				#输出到屏幕日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4swriteCategory=debug			#输出到文件日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4slogname=root.log					#输出日志名称
isecho=0											#输出到日志的同时是否打印到屏幕，0是不打印，1是打印
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
	#返回当前BW值
	log4s debug "fiorun: 进入fiorun"
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
	log4s debug "fiorun: 当前运行命令如下"
	log4s debug "fiorun: fio -filename=${filename} -direct=1 -iodepth 1 -thread -rw=${rwt} ${rwmicommandt} -ioengine=${ioenginet} -bs=${bst} -size=${sizet} -numjobs=${numjobst} -runtime=${testruntime} -group_reporting -name=${testnamet} > $doDIR/${testnamet}"
	log4s debug "fiorun: 当前BW值为${BWnum}，当前numjobs值为${numjobst}"
	
	if [ X$BWnum = X ] || [ X$numjobst = X ]
	then
		log4s error "fiorun: fio运行异常，请检查机器"
	fi
	log4s info "fiorun: 返回结果为:$BWnum"
	log4s debug "fiorun: fiorun结束"
	echo "$BWnum"
}
njobrun()
{
	
	#返回最优job
	log4s debug "njobrun: 进入njobrun"
	filename=$1
	bst=$2
	sizet=$3
	ioenginet=$4
	rwt=$5
	rwmicommandt=$6
	#思路：要求3永远大于1的njob，判断3和1的结果谁大，在大的到中间的区间做减半测试，如果一样大，那么3和1的njob分别递进10重跑
	
	njob1=$test1n
	njob2=$test2n
	njob3=$test3n

	log4s debug "njobrun: njobrun执行num1命令为fiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt"
	log4s debug "njobrun: njobrun执行num3命令为fiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt"
	num1=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt)
	num3=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt)

	njobtemp=0
	numtemp=0
	while true
	do
		log4s debug "njobrun: njobrun执行num2命令为fiorun $filename $bst $sizet $ioenginet $rwt $njob2 $rwmicommandt"
		num2=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob2 $rwmicommandt)
		log4s debug "njobrun: 当前获取到的num1-3分别为：$num1 $num2 $num3。"
		log4s debug "njobrun: 当前njobs1-3分别为：$njob1 $njob2 $njob3"
		if [ $num3 -gt $num1 ]
		then
			njob1=$njob2
			njob3=$njob3
			num1=$num2
			let njob2=(njob3-njob1)/2/stepn*stepn+njob1
			log4s debug "njobrun: 3号任务性能大于1号，新的1号任务njobs为$njob1，新的2号任务为$njob2，新的3号任务为$njob3"
		elif [ $num3 -lt $num1 ]
		then
			njob1=$njob1
			njob3=$njob2
			num3=$num2
			let njob2=(njob3-njob1)/2/stepn*stepn+njob1
			log4s debug "njobrun: 1号任务性能大于3号，新的1号任务njobs为$njob1，新的2号任务为$njob2，新的3号任务为$njob3"
		else
			let njob1=njob1+10
			let njob3=njob3-10
			num1=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt)
			num3=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt)
			log4s debug "njobrun: njobrun执行num1命令为fiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt"
			log4s debug "njobrun: njobrun执行num3命令为fiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt"
			num1=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob1 $rwmicommandt)
			num3=$(fiorun $filename $bst $sizet $ioenginet $rwt $njob3 $rwmicommandt)
			log4s debug "njobrun: 1号任务性能等于3号，新的1号任务njobs为$njob1，新的2号任务为$njob2，新的3号任务为$njob3"
		fi
		
		if [ $njob2 -le $njob1 ] || [ $njob2 -ge $njob3 ] || [ $njob3 -le $njob1 ]
		then
			log4s info "njobrun: njobrun获取到最大BW值，当前BW值为${num2}，当前numjobs值为${njob2}，当前命令如下"
			log4s info "njobrun: fiorun $filename $bst $sizet $ioenginet $rwt $njob2 $rwmicommandt"
			log4s info "njobrun: 返回结果为:$njob2|$num2"
			log4s debug "njobrun: njobrun结束"
			finalfilename="${rwt}_${ioenginet}_${bst}_final"
			echo "fio -filename=${filename} -direct=1 -iodepth 1 -thread -rw=${rwt} ${rwmicommandt} -ioengine=${ioenginet} -bs=${bst} -size=${sizet} -numjobs=${njob2} -runtime=${finalruntime} -group_reporting -name=${finalfilename}" >>$finalcommandfile
			echo "$njob2|$num2"
			break;
		fi
	done
}
norwgo()
{
	log4s debug "norwgo: 进入norwgo"
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
			log4s debug "norwgo: norwgo执行命令为njobrun $filename $bs $sizet $ioenginei $rwt $rwmicommand"
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
	log4s info "norwgo: norwgo获取到当前${rwt}的最大BW值，当前numjobs为${okjob}，当前BW为${oknum}，当前bs为${okbs}，当前ioengine为${okioengine}"
	log4s info "norwgo: 返回结果为:$oknum|$okjob|$okbs|$okioengine"
	log4s debug "norwgo: norwgo结束"
	log4s debug "norwgo: 全局最优解为：${rwt}  ${sizet} ${okbs} ${okioengine}"
	echo "$oknum|$okjob|$okbs|$okioengine"
}
rwgo()
{
	rwruncount=0
	#这里不再接受参数，这里是测试部分最外层循环
	#遍历所有rw方式，每种获取到最优参数，将当前最优命令写入$finalcommandfile文件
	log4s debug "rwgo: 进入rwgo"
	for rwi in ${rw[*]};do
		
		rwforrwmix=$rwi
		setrwmix;
		log4s debug "rwgo: rwgo执行命令为norwgo $lvname $rwi $testsize"
		rwiresult=$(norwgo $lvname $rwi $testsize)
		rwiokbwnum=$(echo $rwiresult|awk -F'|' '{print $1}')
		rwiokjob=$(echo $rwiresult|awk -F'|' '{print $2}')
		rwiokbs=$(echo $rwiresult|awk -F'|' '{print $3}')
		rwiokoengine=$(echo $rwiresult|awk -F'|' '{print $4}')
	done
}


finalgo()
{
	log4s info "最终命令在$finalcommandfile ，开始执行最终命令"
	while read h
	do
		finalresfilename=`echo $h|awk -F'=' '{print $NF}'`
		log4s info "当前执行结果保存在 $finalresfilename 中"
		$h > $finalresfilename
	done <$finalcommandfile
	log4s info "全部执行完成"
}


xhtml()
{
	echo $1 >> $baogao
}
fenxi()
{
	#$1是文件名，后面4个参数分别是测试的5个参数，分别为：2"rw方式" 3"libaio还是psync" 4"bs大小" 5"jobs数" 6"分配行号"
	fxfilename=$1
	hanghao=$6
	log4s info "开始分析${fxfilename}"
	rwtype=`echo ${fxfilename} |awk -F'_' '{print $1}'`
	
	if [ X$rwtype = Xread ] || [ X$rwtype = Xrandread ]
	then
		#读结果分析
		log4s debug "进入读文件分析流程"
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
		#写结果分析
		log4s debug "进入写文件分析流程"
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
		#混合读写分析
		log4s debug "进入混合读写文件分析流程"
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
		#异常处理
		log4s error "文件rw类型无法识别，请重试"
	fi
}

gohtml()
{
	>$baogao
	#html头部
	xhtml "<html>"
	xhtml "<head>"
	xhtml "<title>FIO测试报告</title>"
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
	xhtml "<th>测试名称</th>"
	xhtml "<th colspan=\"4\">参数</th>"
	xhtml "<th colspan=\"17\">结果</th>"
	xhtml "</tr>"
	xhtml "<tr>"
	xhtml "<th></th>"
	xhtml "<th>rw</th>"
	xhtml "<th>测试方式</th>"
	xhtml "<th>bs大小</th>"
	xhtml "<th>jobs数量</th>"
	xhtml "<th>IOPS</th>"
	xhtml "<th>BW</th>"
	xhtml "<th>slat单位</th>"
	xhtml "<th>slat_min</th>"
	xhtml "<th>slat_max</th>"
	xhtml "<th>slat_avg</th>"
	xhtml "<th>slat_sthev</th>"
	xhtml "<th>clat单位</th>"
	xhtml "<th>clat_min</th>"
	xhtml "<th>clat_max</th>"
	xhtml "<th>clat_avg</th>"
	xhtml "<th>clat_sthev</th>"
	xhtml "<th>lat单位</th>"
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
	#html结尾
	xhtml "</table>"
	xhtml "</body></html>"
}

anzhuang()
{
	if [ $wai != root ]
	then
		log4s error "必须root账户执行"
		exit 1;
	fi
	#判断libaio是否安装
	libaio1=`rpm -qa|grep libaio|wc -l|awk '{print $1}'`
	libaio2=`rpm -qa|grep libaio-devel|wc -l|awk '{print $1}'`
	if [ $libaio1 -lt 2 ] || [ $libaio2 -lt 1 ]
	then
		log4s info "依赖的libaio不全，首先安装libaio"
		if [ ! -f $doDIR/$libaiorpmfile ]
		then
			log4s error "依赖包不存在，无法安装"
			exit 1;
		else
			rpm -ivh $doDIR/$libaiorpmfile 1>$doDIR/rpm.log 2>&1
			if [ $? = 0 ]
			then
				log4s info "依赖包安装完成"
			else
				log4s error "依赖包安装异常，请手动处理"
				exit 1;
			fi
		fi
	fi
	#安装fio包
	if [ ! -f $doDIR/$anzhuangbao ]
	then
		log4s error "fio安装包不存在"
	fi
	cd $doDIR;
	tar -xvf $anzhuangbao
	cd fio-fio-2.99;
	./configure;
	if [ $? = 0 ]
	then
		log4s info "configure 配置成功"
	else
		log4s error "configure 配置失败"
		exit 1;
	fi
	make all;
	if [ $? = 0 ]
	then
		log4s info "make all 编译成功"
	else
		log4s error "make all 编译失败"
		exit 1;
	fi
	make install;
	if [ $? = 0 ]
	then
		log4s info "make install 安装成功"
	else
		log4s error "make install 安装失败"
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
