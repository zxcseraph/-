echo "������"
>d.sql
dbschema -d test -ss d.sql
diff ./d.sql ./allss.sql
if [ $? = 0 ]
then
	echo "��ṹ����"
else
	echo "ERROR ��ṹ�쳣"
fi
getnum()
{
	echo "unload to $1.unl select  count(*) from $1"|dbaccess test 1>/dev/null 2>&1
	if [ $? != 0 ]
	then
		echo "$1 ���ݿ��쳣"
	fi
	check1=`wc -l $1.unl|awk '{print $1}'`
	if [ $check1 != 1 ]
	then
		echo "$1 sysmaster�����쳣"
	else
		xnum=`cat $1.unl|awk   '{print $1}'|awk -F'.' '{print $1}'`
		if [ $2 != $xnum ]
		then
			echo "ERROR ��$1�����쳣"
		fi
		rm $1.unl
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
getnum t_hdr37from36 				1
getnum view_b 							1
getnum aa										2
getnum view_a_aa            4

