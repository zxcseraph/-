#!/bin/sh
ls -rt mytest* >mulu.txt
while read hang
do
	filename=`echo $hang|awk 'BEGIN{FS="_";OFS="_"} {print $1,$2,$3,$4,$5}'`
	njobs=`echo $filename|awk -F'.' '{print $1}'|awk -F'_' '{print $5}'`
	bw=`grep BW $filename|tail -1|awk -F':' '{print $2}'|awk -F',' '{print $2}'|awk '{print $1}'|awk -F'=' '{print $2}'|awk '{if(substr($0,length()-4,1)=="M"){ printf "%.f" ,substr($0,0,length()-5)*1024}else if(substr($0,length()-4,1)=="G"){ printf "%.f" ,substr($0,0,length()-5)*1024*1024}else{print substr($0,0,length()-5)}}'`
	echo "$njobs   $bw" >> $filename.result
done < mulu.txt
ls *.result >result.txt
while read hang
do
	gnuplot << EOF
set xlabel "numjobs"
set xlabel "BW"
set title "$hang"
unset key
set output './${hang}.jpeg'
set term jpeg
plot "./$hang" with lines
EOF
done < result.txt
