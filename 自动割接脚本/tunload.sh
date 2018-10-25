echo "导出检查"
diff test/allss.sql ./allss.sql
if [ $? = 0 ]
then
	echo "表结构正常"
else
	echo "ERROR 表结构异常"
fi
getnum()
{
	if [ ! -f test/${1}.unl ]
	then
		xnum=0
	else
		xnum=`wc -l test/${1}.unl|awk '{print $1}'`
	fi
	if [ $2 != $xnum ]
	then
		echo "ERROR 表$1行数异常"	
	fi
}
getnum a               	    4002
getnum testb1  							0
getnum inms_pm_data	 				0
getnum b       							1
getnum c          					0
getnum youhua     					0
getnum twofrag       				0
getnum tlm_table		        2
getnum tlm_errlog   				0
getnum fragtabinfo 					12
getnum mcn_mid_callbilllog	0
getnum mcn_mid_smsbilllog		0
getnum mcn_mid_yb						0
getnum pbxaup_userwhite			2
getnum t_hdr37from36 				0
getnum view_b 							0
getnum aa										2
getnum view_a_aa            0
