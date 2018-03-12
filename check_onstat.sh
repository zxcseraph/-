#!/bin/bash
fm=`date +"%Y%m%d%H%M%S"`
i=1
max=$1
#多少次移动一次文件
fenyeshu=$2
mulu=$3
echo "`pwd`" >> /home/informix/check/a.log
cd $mulu/
		nohup iostat 1 $max >>$mulu/checkio.log.$fm 2>&1 &
		nohup sar -d 1 $max >>$mulu/checksard.log.$fm 2>&1 &
		nohup sar -v 1 $max >>$mulu/checksarv.log.$fm 2>&1 &
		nohup vmstat 1 $max >>$mulu/checkvmstat.log.$fm 2>&1 &
unloadsysptprof()
{
	n=0
	while [ $n -lt 10 ]
	do
		dbaccess sysmaster <<-EOF
		unload to mcn_mid_userdata30${n}.unl.temp
		select current,*
		from sysptprof where tabname="mcn_mid_userdata30${n}"
		EOF
		cat mcn_mid_userdata30${n}.unl.temp >> $mulu/mcn_mid_userdata30${n}.unl.$fm
		rm $mulu/mcn_mid_userdata30${n}.unl.temp
		let n+=1
	done
}

while [ $i -le $max ]
do
	let idir=i%$fenyeshu
	let lun=i/$fenyeshu
	if [ $idir -eq 1 ]
	then
		fm=`date +"%Y%m%d%H%M%S"`
	fi
#	unloadsysptprof;
	date >> $mulu/checkt.log.$fm
		onstat -t  >> $mulu/checkt.log.$fm
	date >> $mulu/checklmx.log.$fm
		onstat -g lmx >> $mulu/checklmx.log.$fm
	date >> $mulu/checku.log.$fm
		onstat -u >> $mulu/checku.log.$fm
	date >> $mulu/checks.log.$fm
		onstat -s >> checks.log.$fm
	date >> checkk.log.$fm
		onstat -k >> checkk.log.$fm
	date >> checkp.log.$fm
		onstat -p >> checkp.log.$fm
	date >> checkp1.log.$fm
		onstat -P >> checkp1.log.$fm
	date >> $mulu/checkr1.log.$fm
		onstat -R >> $mulu/checkr1.log.$fm
	date >> checkx1.log.$fm
		onstat -X >> checkx1.log.$fm
	date >> checkx.log.$fm
		onstat -x >> checkx.log.$fm
	date >> checkb.log.$fm
		onstat -b >> checkb.log.$fm
	date >> checkstk.log.$fm
		onstat -g stk >> checkstk.log.$fm
	date >> $mulu/checksql.log.$fm
		onstat -g sql 0 >> $mulu/checksql.log.$fm 
	date >> $mulu/onstatppf.log.$fm
		onstat -g ppf >> $mulu/onstatppf.log.$fm
	date >> checkwst.log.$fm
		onstat -g wst >> checkwst.log.$fm
	date >> $mulu/checkses.log.$fm
		onstat -g ses 0|wc -l >> $mulu/checkseses.log.$fm
	date >> $mulu/gckp.$fm
		onstat -g ckp >> $mulu/gckp.$fm
	date >> $mulu/giof.$fm
		onstat -g iof >>$mulu/giof.$fm
	date >> checksqls.log.$fm
		onstat -g sql >> checksqls.log.$fm
	date >> checkglo.log.$fm
		onstat -g glo >> checkglo.log.$fm
	date >> checkath.log.$fm
		onstat -g ath >> checkath.log.$fm
	date >> checkm.log.$fm
		onstat -g mem >> checkm.log.$fm
	date >> checknetan.log.$fm
		netstat -an >> checknetan.log.$fm

	if [ $idir -eq 0 ]
	then
		mkdir $mulu/$lun
		echo "mkdir $mulu/$lun"
		mv $mulu/*.$fm $mulu/${lun}/
	fi
	let i=i+1
	sleep 1
done



exit 0




