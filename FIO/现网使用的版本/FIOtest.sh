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
lvname=/dev/testvg/testlv				#要改
name=mytest
bakdir=${doDIR}/${name}bak
testnjobs=("40" "60"  "80")
testsize=200G
testruntime=300								#每次测试时间，单位为秒，总测试时间是该值乘以24乘以testnjobs的个数，得到总测试时间
rw=("randwrite" "randread" "randrw" "read" "write" "rw")
rwmixwrite=50
ioengine=("libaio" "psync")

#初始测试三次
test1n=1
test2n=2
test3n=500
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
	rw=("rw" "randread")
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
	mv $doDIR/${testname}* $bakdir 1>/dev/null 2>&1
	mv $bakdir/FIOtest.sh ./
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

fiogo()
{
	for rwi in ${rw[*]};do
		#rw循环，获取rw
		rwforrwmix=$rwi
		#根据rw设置读写比例
		setrwmix;
		log4s info "rw循环获取参数为 rw=$rwi rwmicommand=$rwmicommand "
		for ioenginei in ${ioengine[*]}; do
			#驱动循环设置驱动，根据驱动设置bs合集
			setbs $ioenginei;
			log4s info "ioengine循环获取 ioengine=$ioenginei"
			for bsi in ${bs[*]}; do
				#bs循环，根据上面获取的bs合集获取bs
				log4s info "bs循环获取的bs为 bs=$bsi"
				njobok=0
				numok=0
				for njobi in ${testnjobs[*]};do
					#前面条件相同的时候，不同njobs跑，获取最优值
					num=$(fiorun $lvname $bsi $testsize $ioenginei $rwi $njobi $rwmicommand)
					log4s info "当前num值为 $num"
					if [ $num -gt $numok ]
					then
						njobok=$njobi
						log4s info "当前num大于之前的，设置为最大值，相应njob设置为 njobok=$njobi"
					fi
				done
					testnamet=${name}_${rwi}_${ioenginei}_${bsi}_${njobok}.test
					finalfilename="${rwi}_${ioenginei}_${bsi}_final"
					mv ${name}_${rwi}_${ioenginei}_${bsi}_${njobok}.test $finalfilename
					echo "fio -filename=${lvname} -direct=1 -iodepth 1 -thread -rw=${rwi} ${rwmicommand} -ioengine=${ioenginei} -bs=${bsi} -size=${testsize} -numjobs=${njobok} -runtime=${testruntime} -group_reporting -name=${finalfilename}" >>$finalcommandfile
					log4s info "最终命令为 fio -filename=${lvname} -direct=1 -iodepth 1 -thread -rw=${rwi} ${rwmicommand} -ioengine=${ioenginei} -bs=${bsi} -size=${testsize} -numjobs=${njobok} -runtime=${testruntime} -group_reporting -name=${finalfilename}"
			done
		done
	done
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
		log4s debug "IOPS=$fx_r_IOPS"
		log4s debug "BW=$fx_r_BW"
		if [ X$3 = Xpsync ]
		then
			fx_r_slat_flag=N/A
			fx_r_slat_min=N/A
			fx_r_slat_max=N/A
			fx_r_slat_avg=N/A
			fx_r_slat_stdev=N/A
		else
			fx_r_slat_flag=`cat  $fxfilename|grep slat|grep min|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
			fx_r_slat_min=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_max=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_avg=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_stdev=`cat $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		fx_r_clat_flag=`cat  $fxfilename|grep clat|grep min|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_r_clat_min=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_clat_max=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_clat_avg=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_clat_stdev=`cat $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_lat_flag=`cat   $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_r_lat_min=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_lat_max=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_lat_avg=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_lat_stdev=`cat  $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		if [ X$fx_r_slat_flag = Xmsec ]
		then
			fx_r_slat_min=`awk -v t="$fx_r_slat_min" 'BEGIN {printf "%d",t*1000}'`
			fx_r_slat_max=`awk -v t="$fx_r_slat_max" 'BEGIN {printf "%d",t*1000}'`
			fx_r_slat_avg=`awk -v t="$fx_r_slat_avg" 'BEGIN {printf "%d",t*1000}'`
			fx_r_slat_stdev=`awk -v t="$fx_r_slat_stdev" 'BEGIN {printf "%d",t*1000}'`
		elif [ X$fx_r_slat_flag = Xnsec ]
		then
			fx_r_slat_min=`awk -v t="$fx_r_slat_min" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_slat_max=`awk -v t="$fx_r_slat_max" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_slat_avg=`awk -v t="$fx_r_slat_avg" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_slat_stdev=`awk -v t="$fx_r_slat_stdev" 'BEGIN {printf "%.5f",t/1000}'`
		fi
		if [ X$fx_r_clat_flag = Xmsec ]
		then
			fx_r_clat_min=`awk -v t="$fx_r_clat_min" 'BEGIN {printf "%d",t*1000}'`
			fx_r_clat_max=`awk -v t="$fx_r_clat_max" 'BEGIN {printf "%d",t*1000}'`
			fx_r_clat_avg=`awk -v t="$fx_r_clat_avg" 'BEGIN {printf "%d",t*1000}'`
			fx_r_clat_stdev=`awk -v t="$fx_r_clat_stdev" 'BEGIN {printf "%d",t*1000}'`
		elif [ X$fx_r_clat_flag = Xnsec ]
		then
			fx_r_clat_min=`awk -v t="$fx_r_clat_min" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_clat_max=`awk -v t="$fx_r_clat_max" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_clat_avg=`awk -v t="$fx_r_clat_avg" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_clat_stdev=`awk -v t="$fx_r_clat_stdev" 'BEGIN {printf "%.5f",t/1000}'`
		fi
		if [ X$fx_r_lat_flag = Xmsec ]
		then
			fx_r_lat_min=`awk -v t="$fx_r_lat_min" 'BEGIN {printf "%d",t*1000}'`
			fx_r_lat_max=`awk -v t="$fx_r_lat_max" 'BEGIN {printf "%d",t*1000}'`
			fx_r_lat_avg=`awk -v t="$fx_r_lat_avg" 'BEGIN {printf "%d",t*1000}'`
			fx_r_lat_stdev=`awk -v t="$fx_r_lat_stdev" 'BEGIN {printf "%d",t*1000}'`
		elif [ X$fx_r_lat_flag = Xnsec ]
		then
			fx_r_lat_min=`awk -v t="$fx_r_lat_min" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_lat_max=`awk -v t="$fx_r_lat_max" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_lat_avg=`awk -v t="$fx_r_lat_avg" 'BEGIN {printf "%.5f",t/1000}'`
			fx_r_lat_stdev=`awk -v t="$fx_r_lat_stdev" 'BEGIN {printf "%.5f",t/1000}'`
		fi
		let yushu=hanghao%2
		if [ X$yushu = X1 ]
		then
			ji_ou=ji
		else
			ji_ou=ou
		fi
		log4s debug "读流程 slat_flag=$fx_r_slat_flag"
		log4s debug "读流程 slat_min=$fx_r_slat_min"
		log4s debug "读流程 slat_max=$fx_r_slat_max"
		log4s debug "读流程 slat_avg=$fx_r_slat_avg"
		log4s debug "读流程 slat_avg=$fx_r_slat_avg"
		xhtml "<tr>"
		xhtml "<th>$fxfilename</th>"
		if [ $rwnow = 0 ]
		then
			xhtml "<td class=\"$ji_ou\" rowspan=\"4\">$2</td>"
		fi
		if [ $fangshinow = 0 ]
		then
			xhtml "<td class=\"$ji_ou\" rowspan=\"2\">$3</td>"
		fi
		xhtml "<td class=\"$ji_ou\">${4} 读</td>"
		xhtml "<td class=\"$ji_ou\">$5</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_IOPS</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_BW</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_stdev</td>"
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
			fx_w_slat_flag=N/A
			fx_w_slat_min=N/A
			fx_w_slat_max=N/A
			fx_w_slat_avg=N/A
			fx_w_slat_stdev=N/A
		else
			fx_w_slat_flag=`cat  $fxfilename|grep slat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
			fx_w_slat_min=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_max=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_avg=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_stdev=`cat $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		fx_w_clat_flag=`cat  $fxfilename|grep clat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_w_clat_min=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_clat_max=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_clat_avg=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_clat_stdev=`cat $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_lat_flag=`cat   $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_w_lat_min=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_lat_max=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_lat_avg=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_lat_stdev=`cat  $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		if [ X$fx_w_slat_flag = Xmsec ]
		then
			fx_w_slat_min=`awk -v t="$fx_w_slat_min" 'BEGIN {printf "%d",t*1000}'`
			fx_w_slat_max=`awk -v t="$fx_w_slat_max" 'BEGIN {printf "%d",t*1000}'`
			fx_w_slat_avg=`awk -v t="$fx_w_slat_avg" 'BEGIN {printf "%d",t*1000}'`
			fx_w_slat_stdev=`awk -v t="$fx_w_slat_stdev" 'BEGIN {printf "%d",t*1000}'`
		elif [ X$fx_w_slat_flag = Xnsec ]
		then
			fx_w_slat_min=`awk -v t="$fx_w_slat_min" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_slat_max=`awk -v t="$fx_w_slat_max" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_slat_avg=`awk -v t="$fx_w_slat_avg" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_slat_stdev=`awk -v t="$fx_w_slat_stdev" 'BEGIN {printf "%.5f",t/1000}'`
		fi
		if [ X$fx_w_clat_flag = Xmsec ]
		then
			fx_w_clat_min=`awk -v t="$fx_w_clat_min" 'BEGIN {printf "%d",t*1000}'`
			fx_w_clat_max=`awk -v t="$fx_w_clat_max" 'BEGIN {printf "%d",t*1000}'`
			fx_w_clat_avg=`awk -v t="$fx_w_clat_avg" 'BEGIN {printf "%d",t*1000}'`
			fx_w_clat_stdev=`awk -v t="$fx_w_clat_stdev" 'BEGIN {printf "%d",t*1000}'`
		elif [ X$fx_w_clat_flag = Xnsec ]
		then
			fx_w_clat_min=`awk -v t="$fx_w_clat_min" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_clat_max=`awk -v t="$fx_w_clat_max" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_clat_avg=`awk -v t="$fx_w_clat_avg" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_clat_stdev=`awk -v t="$fx_w_clat_stdev" 'BEGIN {printf "%.5f",t/1000}'`
		fi
		if [ X$fx_w_lat_flag = Xmsec ]
		then
			fx_w_lat_min=`awk -v t="$fx_w_lat_min" 'BEGIN {printf "%d",t*1000}'`
			fx_w_lat_max=`awk -v t="$fx_w_lat_max" 'BEGIN {printf "%d",t*1000}'`
			fx_w_lat_avg=`awk -v t="$fx_w_lat_avg" 'BEGIN {printf "%d",t*1000}'`
			fx_w_lat_stdev=`awk -v t="$fx_w_lat_stdev" 'BEGIN {printf "%d",t*1000}'`
		elif [ X$fx_w_lat_flag = Xnsec ]
		then
			fx_w_lat_min=`awk -v t="$fx_w_lat_min" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_lat_max=`awk -v t="$fx_w_lat_max" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_lat_avg=`awk -v t="$fx_w_lat_avg" 'BEGIN {printf "%.5f",t/1000}'`
			fx_w_lat_stdev=`awk -v t="$fx_w_lat_stdev" 'BEGIN {printf "%.5f",t/1000}'`
		fi
		let yushu=hanghao%2
		if [ X$yushu = X1 ]
		then
			ji_ou=ji
		else
			ji_ou=ou
		fi
		xhtml "<tr>"
		xhtml "<th>$fxfilename</th>"
		if [ $rwnow = 0 ]
		then
			xhtml "<td class=\"$ji_ou\" rowspan=\"4\">$2</td>"
		fi
		if [ $fangshinow = 0 ]
		then
			xhtml "<td class=\"$ji_ou\" rowspan=\"2\">$3</td>"
		fi
		xhtml "<td class=\"$ji_ou\">${4} 写</td>"
		xhtml "<td class=\"$ji_ou\">$5</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_IOPS</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_BW</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_stdev</td>"
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
		fx_r_clat_min=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_clat_max=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_clat_avg=`cat   $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_clat_stdev=`cat $fxfilename|grep clat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_lat_flag=`cat   $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_r_lat_min=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_lat_max=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_lat_avg=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_r_lat_stdev=`cat  $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		if [ X$3 = Xpsync ]
		then
			fx_w_slat_flag=N/A
			fx_w_slat_min=N/A
			fx_w_slat_max=N/A
			fx_w_slat_avg=N/A
			fx_w_slat_stdev=N/A
			fx_r_slat_flag=N/A
			fx_r_slat_min=N/A
			fx_r_slat_max=N/A
			fx_r_slat_avg=N/A
			fx_r_slat_stdev=N/A
		else
			fx_r_slat_flag=`cat  $fxfilename|grep slat|grep min|head -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
			fx_r_slat_min=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_max=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_avg=`cat   $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_stdev=`cat $fxfilename|grep slat|grep min|head -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_flag=`cat  $fxfilename|grep slat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
			fx_w_slat_min=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_max=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_avg=`cat   $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_stdev=`cat $fxfilename|grep slat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		fx_w_IOPS=`cat       $fxfilename|grep IOPS|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f" ,substr($0,0,length())*1000}else if(substr($0,length(),1)=="m"){ printf "%.f" ,substr($0,0,length())*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_BW=`cat         $fxfilename|grep BW|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length()-4,1)=="M"){ printf "%.f" ,substr($0,0,length()-5)*1024}else if(substr($0,length()-4,1)=="G"){ printf "%.f" ,substr($0,0,length()-5)*1024*1024}else{print substr($0,0,length()-5)}}'`
		fx_w_clat_flag=`cat  $fxfilename|grep clat|grep min|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_w_clat_min=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_clat_max=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_clat_avg=`cat   $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_clat_stdev=`cat $fxfilename|grep clat|grep min|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_lat_flag=`cat   $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk '{print $2}'|awk '{print substr($0,2,length())}'|awk '{print substr($0,1,length()-2)}'`
		fx_w_lat_min=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_lat_max=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_lat_avg=`cat    $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $3}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fx_w_lat_stdev=`cat  $fxfilename|grep lat|grep min|grep -v slat|grep -v clat|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $4}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		if [ X$fx_r_slat_flag = Xmsec ]
		then
			fx_r_slat_min=`awk -v t="$fx_r_slat_min" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_max=`awk -v t="$fx_r_slat_max" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_avg=`awk -v t="$fx_r_slat_avg" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_stdev=`awk -v t="$fx_r_slat_stdev" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		elif [ X$fx_r_slat_flag = Xnsec ]
		then
			fx_r_slat_min=`awk -v t="$fx_r_slat_min" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_max=`awk -v t="$fx_r_slat_max" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_avg=`awk -v t="$fx_r_slat_avg" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_slat_stdev=`awk -v t="$fx_r_slat_stdev" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		if [ X$fx_r_clat_flag = Xmsec ]
		then
			fx_r_clat_min=`awk -v t="$fx_r_clat_min" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_clat_max=`awk -v t="$fx_r_clat_max" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_clat_avg=`awk -v t="$fx_r_clat_avg" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_clat_stdev=`awk -v t="$fx_r_clat_stdev" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		elif [ X$fx_r_clat_flag = Xnsec ]
		then
			fx_r_clat_min=`awk -v t="$fx_r_clat_min" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_clat_max=`awk -v t="$fx_r_clat_max" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_clat_avg=`awk -v t="$fx_r_clat_avg" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_clat_stdev=`awk -v t="$fx_r_clat_stdev" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		if [ X$fx_r_lat_flag = Xmsec ]
		then
			fx_r_lat_min=`awk -v t="$fx_r_lat_min" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_lat_max=`awk -v t="$fx_r_lat_max" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_lat_avg=`awk -v t="$fx_r_lat_avg" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_lat_stdev=`awk -v t="$fx_r_lat_stdev" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		elif [ X$fx_r_lat_flag = Xnsec ]
		then
			fx_r_lat_min=`awk -v t="$fx_r_lat_min" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_lat_max=`awk -v t="$fx_r_lat_max" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_lat_avg=`awk -v t="$fx_r_lat_avg" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_r_lat_stdev=`awk -v t="$fx_r_lat_stdev" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		if [ X$fx_w_slat_flag = Xmsec ]
		then
			fx_w_slat_min=`awk -v t="$fx_w_slat_min" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_max=`awk -v t="$fx_w_slat_max" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_avg=`awk -v t="$fx_w_slat_avg" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_stdev=`awk -v t="$fx_w_slat_stdev" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		elif [ X$fx_w_slat_flag = Xnsec ]
		then
			fx_w_slat_min=`awk -v t="$fx_w_slat_min" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_max=`awk -v t="$fx_w_slat_max" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_avg=`awk -v t="$fx_w_slat_avg" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_slat_stdev=`awk -v t="$fx_w_slat_stdev" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		if [ X$fx_w_clat_flag = Xmsec ]
		then
			fx_w_clat_min=`awk -v t="$fx_w_clat_min" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_clat_max=`awk -v t="$fx_w_clat_max" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_clat_avg=`awk -v t="$fx_w_clat_avg" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_clat_stdev=`awk -v t="$fx_w_clat_stdev" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		elif [ X$fx_w_clat_flag = Xnsec ]
		then
			fx_w_clat_min=`awk -v t="$fx_w_clat_min" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_clat_max=`awk -v t="$fx_w_clat_max" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_clat_avg=`awk -v t="$fx_w_clat_avg" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_clat_stdev=`awk -v t="$fx_w_clat_stdev" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		if [ X$fx_w_lat_flag = Xmsec ]
		then
			fx_w_lat_min=`awk -v t="$fx_w_lat_min" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_lat_max=`awk -v t="$fx_w_lat_max" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_lat_avg=`awk -v t="$fx_w_lat_avg" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_lat_stdev=`awk -v t="$fx_w_lat_stdev" 'BEGIN {printf "%d",t*1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		elif [ X$fx_w_lat_flag = Xnsec ]
		then
			fx_w_lat_min=`awk -v t="$fx_w_lat_min" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_lat_max=`awk -v t="$fx_w_lat_max" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_lat_avg=`awk -v t="$fx_w_lat_avg" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
			fx_w_lat_stdev=`awk -v t="$fx_w_lat_stdev" 'BEGIN {printf "%.5f",t/1000}'|awk '{if(substr($0,length(),1)=="k"){ printf "%.f",substr($0,0,length()-1)*1000}else if(substr($0,length(),1)=="M"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else if(substr($0,length(),1)=="m"){ printf "%.f",substr($0,0,length()-1)*1000*1000}else{print substr($0,0,length())}}'`
		fi
		
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
		if [ $rwnow = 0 ]
		then
			xhtml "<td class=\"$ji_ou\" rowspan=\"8\">$2</td>"
		fi
		if [ $fangshinow = 0 ]
		then
			xhtml "<td class=\"$ji_ou\" rowspan=\"4\">$3</td>"
		fi
		xhtml "<td class=\"$ji_ou\">${4} 读</td>"
		xhtml "<td class=\"$ji_ou\">$5</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_IOPS</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_BW</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_slat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_r_clat_stdev</td>"
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
		xhtml "<td class=\"$ji_ou\">${4} 写</td>"
		xhtml "<td class=\"$ji_ou\">$5</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_IOPS</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_BW</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_slat_stdev</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_min</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_max</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_avg</td>"
		xhtml "<td class=\"$ji_ou\">$fx_w_clat_stdev</td>"
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
	xhtml "<th colspan=\"14\">结果</th>"
	xhtml "</tr>"
	xhtml "<tr>"
	xhtml "<th rowspan=\"2\"></th>"
	xhtml "<th rowspan=\"2\" width=\"1000px\">rw</th>"
	xhtml "<th rowspan=\"2\" width=\"4000px\">测试方式</th>"
	xhtml "<th rowspan=\"2\" width=\"5000px\">bs大小</th>"
	xhtml "<th rowspan=\"2\" width=\"7000px\">jobs数量</th>"
	xhtml "<th rowspan=\"2\" width=\"4000px\">IOPS</th>"
	xhtml "<th rowspan=\"2\" width=\"4000px\">BW（单位kb）</th>"
	xhtml "<th colspan=\"4\">slat（单位usec）</th>"
	xhtml "<th colspan=\"4\">clat（单位usec）</th>"
	xhtml "<th colspan=\"4\">lat（单位usec）</th>"
	xhtml "</tr>"
	
	xhtml "<tr>"
	xhtml "<th width=\"4000px\">slat_min</th>"
	xhtml "<th width=\"4000px\">slat_max</th>"
	xhtml "<th width=\"4000px\">slat_avg</th>"
	xhtml "<th width=\"4000px\">slat_stdev</th>"
	xhtml "<th width=\"4000px\">clat_min</th>"
	xhtml "<th width=\"4000px\">clat_max</th>"
	xhtml "<th width=\"4000px\">clat_avg</th>"
	xhtml "<th width=\"4000px\">clat_stdev</th>"
	xhtml "<th width=\"4000px\">lat_min</th>"
	xhtml "<th width=\"4000px\">lat_max</th>"
	xhtml "<th width=\"4000px\">lat_avg</th>"
	xhtml "<th width=\"4000px\">lat_stdev</th>"
	xhtml "</tr>"
	hangnum=1
	rwnow=0
	fangshinow=0
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
		if [ $rwnow != $ceshirw ] && [ $rwnow != 0 ]
		then
			rwnow=0
		fi
		if [ $fangshinow != $ceshifangshi ] && [ $fangshinow != 0 ]
		then
			fangshinow=0
		fi
		fenxi "$ceshimingcheng" "$ceshirw" "$ceshifangshi" "$ceshibs" "$ceshijobs" "$hangnum"
		rwnow=$ceshirw
		fangshinow=$ceshifangshi
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
oldfx()
{
	filelist=("randwrite_libaio_2k_" "randwrite_libaio_8k_" "randwrite_psync_256k_" "randwrite_psync_1024k_" "randread_libaio_2k_" "randread_libaio_8k_" "randread_psync_256k_" "randread_psync_1024k_" "randrw_libaio_2k_" "randrw_libaio_8k_" "randrw_psync_256k_" "randrw_psync_1024k_" "read_libaio_2k_" "read_libaio_8k_" "read_psync_256k_" "read_psync_1024k_" "write_libaio_2k_" "write_libaio_8k_" "write_psync_256k_	" "write_psync_1024k_" "rw_libaio_2k_" "rw_libaio_8k_" "rw_psync_256k_" "rw_psync_1024k_")
	for i in ${filelist[@]}
	do
		ls|grep mytest_$i|grep -v result|grep -v final>t.temp
		oldnum=0
		newnum=0
		while read hang
		do
			newnum=`echo $hang|awk -F'.' '{print $1}'|awk -F"_" '{print $5}'`
			if [ $newnum -ge $oldnum ]
			then
				oldnum=$newnum
			fi
		done <t.temp
		finallfilet=mytest_${i}${oldnum}.test
		finallfile=${i}final
		cp $finallfilet $finallfile
	
		ceshirw=`echo $i|awk -F"_" '{print $1}'`
		ceshifangshi=`echo $i|awk -F"_" '{print $2}'`
		ceshibs=`echo $i|awk -F"_" '{print $3}'`
		ceshijobs=$oldnum
		ceshiruntime=`pwd|awk -F'/' '{print $NF}'|awk '{print substr($0,4,length($0)-3)}'`
		if [ X$ceshirw = Xrw ] || [ X$ceshirw = Xrandrw ]
		then
			string="fio -filename=/dev/vg3pariscsi/scsitestlv -direct=1 -iodepth 1 -thread -rw=$ceshirw -rwmixwrite=50 -ioengine=$ceshifangshi -bs=$ceshibs -size=10G -numjobs=$ceshijobs -runtime=$ceshiruntime -group_reporting -name=$finallfile"
		else
			string="fio -filename=/dev/vg3pariscsi/scsitestlv -direct=1 -iodepth 1 -thread -rw=$ceshirw -ioengine=$ceshifangshi -bs=$ceshibs -size=10G -numjobs=$ceshijobs -runtime=$ceshiruntime -group_reporting -name=$finallfile"
		fi
		echo "$string" >> finallcommand.file
		echo "$finallfile" >> rm.txt
	done
	echo "finallcommand.file" >> rm.txt
	echo "t.temp" >> rm.txt
}
if [ X$1 = Xgo ]
then
	preinit;
	fiogo;
	gohtml;
fi

if [ X$1 = Xanzhuang ]
then
	anzhuang
fi


if [ X$1 = Xgohtml ]
then
	gohtml
fi

if [ X$1 = Xoldfx ]
then
	oldfx
	gohtml
fi