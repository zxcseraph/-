#!/bin/sh
time=`date +"%Y%m%d%H%M%S"`
timenowUTC=`date +%s`
dt=`date +"%Y%m%d"`
dH=`date +"%Y%m%d%H"`
dHonly=`date +"%H"`
dMonly=`date +"%M"`
dM=`date +"%Y%m%d%H%M"`
dS=`date +"%Y%m%d%H%M%S"`
dSn=`date +"%Y-%m-%d %H:%M:%S"`

runtime=("10" "30" "60" "120" "600" "1800")



tihuanbasic()
{
	sed "s#$1#$2#g" $3> $3.temp
	mv $3.temp $3
}

for timei in ${runtime[*]};do
	workdir=`pwd`/run${timei}
	mkdir $workdir
	cp `pwd`/FIOgonew.sh $workdir/FIOgonew.sh
	tihuanbasic "^testruntime.*"  "testruntime=$timei"  $workdir/FIOgonew.sh
	tihuanbasic "^finalruntime.*" "finalruntime=$timei" $workdir/FIOgonew.sh
	cd $workdir
	sh $workdir/FIOgonew.sh go

done