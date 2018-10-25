#!/bin/sh

DATA_DIR=$HOME/closecell/data
LOG_DIR=$HOME/closecell/log

G2_G2=GSM_A-adjacent.unl
TD_G2=GSM_RELA-gsmrelation.unl
G2_TD=TD_A-adjacent_td.unl
TD_TD=TD_RELA-utranrelation.unl
LBS_LATLT=LBS
TD_LATLT=TD_LBS

Line_NUM=10

alarm()
{
 echo "`date` $1" >> $LOG_DIR/alarm.log 
}

panduan()
{
myFile="$DATA_DIR/$1"
if [ ! -f "$myFile" ]
 then alarm "ERROR $1 is empty"
else
 temp=`wc -l $myFile | awk '{print $1}'`
 if [ $temp -le $2 ]
  then alarm "ERROR $1 is too small!"
 fi
fi
}

panduan $G2_G2 $Line_NUM
panduan $TD_G2 $Line_NUM
panduan $G2_TD $Line_NUM
panduan $TD_TD $Line_NUM
panduan $LBS_LATLT $Line_NUM
panduan $TD_LATLT $Line_NUM

