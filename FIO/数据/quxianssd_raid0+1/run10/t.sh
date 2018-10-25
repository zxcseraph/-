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
