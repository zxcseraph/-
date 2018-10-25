#!/bin/sh
workdir=`pwd`
ls |grep run|grep -v txt >run.txt
while read timehang
do
	cd $timehang
	ls -rt mytest*.test >mulu.txt
	rm -rf *.daifenxi
	while read hang
	do
		filename=`echo $hang|awk -F'.' '{print $1}'|awk 'BEGIN{FS="_";OFS="_"} {print $1,$2,$3,$4}'`
		njobs=`echo $hang|awk -F'.' '{print $1}'|awk -F'_' '{print $5}'`
		bw=`grep BW $hang|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length()-4,1)=="M"){ printf "%.f" ,substr($0,0,length()-5)*1024}else if(substr($0,length()-4,1)=="G"){ printf "%.f" ,substr($0,0,length()-5)*1024*1024}else{print substr($0,0,length()-5)}}'`
		echo "$njobs   $bw" >> $filename.daifenxi
		sort -n -k 1 $filename.daifenxi >temp.unl
		mv temp.unl $filename.daifenxi
	done < mulu.txt
	ls *.daifenxi >result.txt
	while read hang
	do
		gnuplot << EOF
	set xlabel "numjobs"
	set xlabel "BW"
	set title "${timehang}_$hang"
	unset key
	set output './${timehang}_${hang}.jpeg'
	set term jpeg
	plot "./$hang" with lines
EOF
	done < result.txt
done <run.txt