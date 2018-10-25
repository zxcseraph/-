
 create table tlm_table 
  (
    table_name varchar(30) not null ,
    column_fragment varchar(30),
    time_granularity integer,
    prefix_fragment varchar(10),
    dbs_name varchar(30) default 'userdbs',
    retention_num integer default -1,
    retention_days integer default -1,
    bak_tabname varchar(30) default 'none',
    last_date datetime year to second,
    failures integer default 0,
	bak_retention_num integer default -1,
	bak_retention_days integer default -1,
	fragment_type char(1) default '0', 
	is_interval char(1) default '0', // 1 代表 interval 自增分区 
	interval_type varchar(10) default 'none',//int,hour,day,month,year
	initial_highvalue varchar(20) default 'none',
    primary key (table_name) 
  ); 
  table_name: 分区表名
  column_fragment:分区建
  time_granularity:分区粒度
  prefix_fragment: ：分区名前缀，不自增分区的情况下，默认都是p 。分区名都是p2018081700的格式
  dbs_name: 分区所在的dbs
  retention_num:分区保留个数，ids12自增分区时采用
  retention_days: 分区保留天数，不采用自增分区时采用
  bak_tabname:备份数据所在的分区表名
  last_date:最后一次操作分区表的时间
  failures:操作失败次数
  bak_retention_num: 备份分区表的保留分区个数
  bak_retention_days: 备份分区表的保留分区天数
  fragment_type:范围分区是根据int数值类型、时间的char类型还是时间的date类型
                0 ：时间的char类型
				1：int数值类型
				2：时间的date类型
  is_interval: 该分区表是否为自增分区，
                0 代表 不采用数据库自带的interval自增分区
				1 代表 interval 自增分区 
  interval_type: 自增分区类型 int,hour,day,month,year
  initial_highvalue:初始定义的分区的最大值
  
  
  
  /*
  后期完善功能，可添加retention_type属性列
  retention_type:分区删除时根据retention_num还是retention_days 进行操作。
				n 根据retention_num
				d 根据retention_days
  */
  
  
  create table tlm_errlog 
  (
    procname varchar(30),
    tabname varchar(30),
    proc_ext datetime year to second,
    sql_err integer,
    isam_err integer,
    err_txt varchar(200),
    count_exec integer
  );
  
  
  drop table fragtabinfo;
  create table fragtabinfo
  (
   optime datetime year to second,
   tabname varchar(50),
   partition varchar(50),
   begintime varchar(20),
   endtime varchar(20)
  );
  create unique index tabpar on fragtabinfo(tabname,partition);
  
  
  
  
  
  
  
  
  create table tlm_table 
  (
    table_name varchar(30) not null ,
    column_fragment varchar(30),
    time_granularity integer,
    prefix_fragment varchar(10),
    dbs_name varchar(30) default 'userdbs',
    retention_num integer default -1,
    retention_days integer default -1,
    bak_tabname varchar(30) default 'none',
    last_date datetime year to second,
    failures integer default 0,
	bak_retention_num integer default -1,
	bak_retention_days integer default -1,
	fragment_type char(1) default '0', 
	is_interval char(1) default '0', 
	interval_type varchar(10) default 'none',
	initial_highvalue varchar(20) default 'none',
    primary key (table_name) 
  );
  
  
  
添加分区测试一：
    insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,fragment_type) 
      values('mcn_contralogtest','callbegintime',24,'userdbs','0');
	  
	  
create table mcn_contralogtest 
  (
    streamnumber serial not null ,
    servicekey integer,
    calltype char(1),
    chargetype char(1),
    roamflag char(1),
    callingpartynumber char(16),
    calledpartynumber char(24),
    mcnnumber char(16),
    roamareanumber char(6),
    mscaddress char(16),
    callreferencenum char(16),
    msinfovlrnumber char(20),
    msinfolai char(10),
    msinfocellid char(14),
    msinfoimsi char(16),
    callbegintime char(14),
    callendtime char(14),
    callduration integer,
    chargepartyindicat char(1),
    extbearercapabilit char(27),
    teleservicecode char(10),
    bearerservicecode char(10),
    scfid char(10),
    callingvareanumber char(6),
    calledvareanumber char(6),
    callinghlrnumber char(6),
    calledhlrnumber char(6),
    callingpartyscateg smallint,
    redirectingpartyid char(16),
    redirectioninfor char(4),
    subscriberstate smallint,
    cause char(5),
    reason char(2)
  ) 
  fragment by expression 
    partition p2018050200 ((callbegintime >= '20180502000000' 
              ) AND (callbegintime < '20180503000000' ) ) in userdbs,
    partition p2018050300 ((callbegintime >= '20180503000000' 
              ) AND (callbegintime < '20180504000000' ) ) in userdbs,
    partition rmd remainder in userdbs;
	
	
  insert into fragtabinfo values(current year to second,'mcn_contralogtest','p2018050200','20180502000000','20180503000000');
  insert into fragtabinfo values(current year to second,'mcn_contralogtest','p2018050300','20180503000000','20180504000000');
  
  
  添加分区测试二：
  
  create table txcy_deliverinfo
  (
    streamnumber serial not null ,
    phonenumber varchar(24),
    sourceid integer ,
    type varchar(3),
    marktime integer,
    id integer default 1
  )
  fragment by expression 
    partition p1 ((streamnumber >=0
              ) AND (streamnumber < 10 ) ) in userdbs,
    partition p2 ((streamnumber >= 10
              ) AND (streamnumber < 20 ) ) in userdbs,
    partition rmd remainder in userdbs;
  
  create index idx_deliverinfo_streamNumber on txcy_deliverinfo(streamnumber);
  
  insert into txcy_deliverinfo(streamnumber) values(0);
  
      insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,fragment_type) 
      values('txcy_deliverinfo','streamnumber',10,'userdbs','1');
	  
	insert into fragtabinfo values(current year to second,'txcy_deliverinfo','p1','0','10');
    insert into fragtabinfo values(current year to second,'txcy_deliverinfo','p2','10','20');
	 insert into fragtabinfo values(current year to second,'txcy_deliverinfo','p10','90','100');
	
	
  添加分区测试三：
  create table txcy_whitephone
(
   phoneNumber varchar(24),
   markdate datetime year to second
)
  fragment by expression 
    partition p2018050200 ((markdate >=to_date('20180502000000','%Y%m%d%H%M%S')
              ) AND (markdate < to_date('20180503000000','%Y%m%d%H%M%S') ) ) in userdbs,
    partition p2018050300 ((markdate >=to_date('20180503000000','%Y%m%d%H%M%S')
              ) AND (markdate < to_date('20180504000000','%Y%m%d%H%M%S') ) ) in userdbs,
    partition rmd remainder in userdbs;
	
	insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,fragment_type) 
      values('txcy_whitephone','markdate',24,'userdbs','2');
	  
	  
    insert into fragtabinfo values(current year to second,'txcy_whitephone','p2018050200','20180502000000','20180503000000');
    insert into fragtabinfo values(current year to second,'txcy_whitephone','p2018050300','20180503000000','20180504000000');
	
	

	
删除分区 测试一
    insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,fragment_type) 
      values('mcn_contralogtest','callbegintime',24,'userdbs','0');
	  
table_name          mcn_contralogtest
column_fragment     callbegintime
time_granularity    24
prefix_fragment
dbs_name            userdbs
retention_num       -1
retention_days      -1
bak_tabname         none
last_date           2018-08-21 16:34:10
failures            0
bak_retention_num   -1
bak_retention_days  -1
fragment_type       0
is_interval         0
interval_type       none
initial_highvalue   none

    update tlm_table set retention_days = 30 where table_name='mcn_contralogtest';


create table mcn_contralogtest_old
  (
    streamnumber int ,
    servicekey integer,
    calltype char(1),
    chargetype char(1),
    roamflag char(1),
    callingpartynumber char(16),
    calledpartynumber char(24),
    mcnnumber char(16),
    roamareanumber char(6),
    mscaddress char(16),
    callreferencenum char(16),
    msinfovlrnumber char(20),
    msinfolai char(10),
    msinfocellid char(14),
    msinfoimsi char(16),
    callbegintime char(14),
    callendtime char(14),
    callduration integer,
    chargepartyindicat char(1),
    extbearercapabilit char(27),
    teleservicecode char(10),
    bearerservicecode char(10),
    scfid char(10),
    callingvareanumber char(6),
    calledvareanumber char(6),
    callinghlrnumber char(6),
    calledhlrnumber char(6),
    callingpartyscateg smallint,
    redirectingpartyid char(16),
    redirectioninfor char(4),
    subscriberstate smallint,
    cause char(5),
    reason char(2)
  ) 
  fragment by expression 
    partition p2018050200 ((callbegintime >= '20180502000000' 
              ) AND (callbegintime < '20180503000000' ) ) in userdbs,
    partition rmd remainder in userdbs;
	
	  insert into fragtabinfo values(current year to second,'mcn_contralogtest_old','p2018050200','20180502000000','20180503000000');
   

   update tlm_table set bak_tabname = 'mcn_contralogtest_old', bak_retention_days=90 where table_name='mcn_contralogtest';
   
   
   删除分区测试二：
   
         insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,fragment_type) 
      values('txcy_deliverinfo','streamnumber',10,'userdbs','1');
		table_name          txcy_deliverinfo
		column_fragment     streamnumber
		time_granularity    10
		prefix_fragment
		dbs_name            userdbs
		retention_num       -1
		retention_days      -1
		bak_tabname         none
		last_date           2018-08-27 11:25:42
		failures            0
		bak_retention_num   -1
		bak_retention_days  -1
		fragment_type       1
		is_interval         0
		interval_type       none
		initial_highvalue   none
		
		update tlm_table set retention_num =10 where table_name='txcy_deliverinfo';
		
		
  create table txcy_deliverinfo_old
  (
    streamnumber int ,
    phonenumber varchar(24),
    sourceid integer ,
    type varchar(3),
    marktime integer,
    id integer default 1
  )
  fragment by expression 
    partition pp ((streamnumber >=-1
              ) AND (streamnumber < 0 ) ) in userdbs,
    partition rmd remainder in userdbs;
	
	insert into fragtabinfo values(current year to second,'txcy_deliverinfo_old','pp','-1','0');
	
	update tlm_table set bak_tabname ='txcy_deliverinfo_old',bak_retention_num=30 where table_name='txcy_deliverinfo';
	
	
	
	删除分区测试三
		insert into tlm_table(table_name,column_fragment,time_granularity,dbs_name,fragment_type) 
      values('txcy_whitephone','markdate',24,'userdbs','2');
	  
		table_name          txcy_whitephone  
		column_fragment     markdate
		time_granularity    24
		prefix_fragment
		dbs_name            userdbs
		retention_num       -1
		retention_days      -1
		bak_tabname         none
		last_date           2018-08-28 11:32:15
		failures            0
		bak_retention_num   -1
		bak_retention_days  -1
		fragment_type       2
		is_interval         0
		interval_type       none
		initial_highvalue   none
	
	update tlm_table set retention_days = 10 where table_name='txcy_whitephone';
	
	  create table txcy_whitephone_old
(
   phoneNumber varchar(24),
   markdate datetime year to second
)
  fragment by expression 
    partition p2018050200 ((markdate >=to_date('20180502000000','%Y%m%d%H%M%S')
              ) AND (markdate < to_date('20180503000000','%Y%m%d%H%M%S') ) ) in userdbs,
    partition rmd remainder in userdbs;
	
	update tlm_table set bak_tabname='txcy_whitephone_old',bak_retention_days=30 where table_name='txcy_whitephone';
	
	
	    insert into fragtabinfo values(current year to second,'txcy_whitephone_old','p2018050200','20180502000000','20180503000000');
		
		
 删除分区测试四：
 
 create table ods_record 
  (
    date_key integer,
    fivemin_key integer,
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by range(date_key) interval(1) store in(userdbs) 
    partition p0 VALUES < 13934 in userdbs
  extent size 16 next size 16 lock mode page;
  

		
 	insert into tlm_table(table_name,column_fragment,time_granularity,retention_num,fragment_type,is_interval,interval_type,initial_highvalue) 
      values('ods_record','date_key',1,10,'1','1','int','13934');
	  
		table_name          ods_record
		column_fragment     date_key
		time_granularity    1 
		prefix_fragment
		dbs_name            userdbs
		retention_num       10
		retention_days      -1
		bak_tabname         none
		last_date           
		failures            0
		bak_retention_num   -1
		bak_retention_days  -1
		fragment_type       1
		is_interval         1
		interval_type       int 
		initial_highvalue   13934
	
	     select a.*
		 from  sysfragments a,systables b 
		 where a.tabid =b.tabid
		   and a.fragtype='T'
		   and a.evalpos >0
		   and b.tabname='ods_record'
		   order by evalpos;
		   
		 select count(*)
		 from  sysfragments a,systables b 
		 where a.tabid =b.tabid
		   and a.fragtype='T'
		   and a.evalpos >0
		   and b.tabname='ods_record';
		   
		insert into ods_record(date_key) values(13970);
		insert into ods_record(date_key) values(13971);
		insert into ods_record(date_key) values(13972);
		insert into ods_record(date_key) values(13973);
		insert into ods_record(date_key) values(13974);
		insert into ods_record(date_key) values(13975);
		insert into ods_record(date_key) values(13976);
		insert into ods_record(date_key) values(13977);
		insert into ods_record(date_key) values(13978);
		insert into ods_record(date_key) values(13979);
		
		
		alter fragment online on table ods_record detach partition sys_p2 ods_recordsys_p2;
		
		
  create table ods_record_old
  (
    date_key integer,
    fivemin_key integer,
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by expression 
    partition p1 ((date_key >=0
              ) AND (date_key < 13934 ) ) in userdbs,
    partition rmd remainder in userdbs;
	
	
	insert into fragtabinfo values(current year to second,'ods_record_old','p1','0','13934');

	update tlm_table set bak_tabname='ods_record_old',bak_retention_num=15 where table_name='ods_record';
	
	
删除分区测试五：

	create table ft
  (
    calltime date,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by range(calltime) interval(1 units day)
    store in(userdbs) 
    partition p0 VALUES < date('01/01/2018') in userdbs
  extent size 16 next size 16 lock mode page;
  

   	insert into tlm_table(table_name,column_fragment,time_granularity,retention_num,fragment_type,is_interval,interval_type,initial_highvalue) 
      values('ft','calltime',1,10,'2','1','day','20180101000000');
  
	table_name          ft
	column_fragment     calltime
	time_granularity    1 
	prefix_fragment
	dbs_name            userdbs
	retention_num       10
	retention_days      -1
	bak_tabname         none
	last_date           
	failures            0
	bak_retention_num   -1
	bak_retention_days  -1
	fragment_type       2
	is_interval         1
	interval_type       day 
	initial_highvalue   20180101000000
	
	
	  insert into ft(calltime) values (date('07/21/2018'));
	  insert into ft(calltime) values (date('07/22/2018'));
	  insert into ft(calltime) values (date('07/23/2018'));
	  insert into ft(calltime) values (date('07/24/2018'));
	  insert into ft(calltime) values (date('07/25/2018'));
	  insert into ft(calltime) values (date('07/26/2018'));
	  insert into ft(calltime) values (date('07/27/2018'));
	  insert into ft(calltime) values (date('07/28/2018'));
	  insert into ft(calltime) values (date('07/29/2018'));
	  insert into ft(calltime) values (date('07/30/2018'));
	  
	  insert into ft(calltime) values (to_date('20180601000000','%Y%m%d%H%M%S'))
	  
	  insert into ft(calltime) values (to_date('20180602000000','%Y%m%d%H%M%S'))

      insert into ft(calltime) values('2018-06-03 00:00:00');
  /*
		 select a.*
		 from  sysfragments a,systables b 
		 where a.tabid =b.tabid
		   and a.fragtype='T'
		   and a.evalpos >0
		   and b.tabname='ft'
		   order by evalpos;
		   
		   
		 select count(*)
		 from  sysfragments a,systables b 
		 where a.tabid =b.tabid
		   and a.fragtype='T'
		   and a.evalpos >0
		   and b.tabname='fh';
*/		   
	
    update tlm_table set bak_tabname='ft_old',bak_retention_num=15 where table_name='ft';	
		   
	create table ft_old
	  (
		calltime date,
		callingnumber_key integer,
		callednumber_key integer,
		callingattr_key integer,
		calledattr_key integer,
		call_result_key integer,
		ringtime integer,
		callduration integer,
		islanjie integer
	  ) 
	  fragment by expression 
      partition p0 ((calltime >=to_date('20180501000000','%Y%m%d%H%M%S')) AND (calltime < to_date('20180502000000','%Y%m%d%H%M%S') ) ) in userdbs,
      partition rmd remainder in userdbs;
	  
	insert into fragtabinfo values(current year to second,'ft_old','p0','20180501000000','20180502000000');
    insert into fragtabinfo values(current year to second,'ft_old','sys_p186','20180705000000','20180706000000');
	insert into fragtabinfo values(current year to second,'ft_old','sys_p187','20180706000000','20180707000000');
	
	
	
	
	
	create table ftt
  (
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by range(calltime) interval(1 units day)
    store in(userdbs) 
    partition p0 VALUES < to_date('20180101000000','%Y%m%d%H%M%S') in userdbs
  extent size 16 next size 16 lock mode page;

  
     insert into tlm_table(table_name,column_fragment,time_granularity,retention_num,fragment_type,is_interval,interval_type,initial_highvalue) 
      values('ftt','calltime',1,10,'2','1','day','20180101000000');
	  
	  
	  insert into ftt(calltime) values (date('03/20/2018'));
	  insert into ftt(calltime) values (date('03/21/2018'));
	  insert into ftt(calltime) values (date('03/22/2018'));
	  insert into ftt(calltime) values (date('03/23/2018'));
	  insert into ftt(calltime) values (date('03/24/2018'));
	  insert into ftt(calltime) values (date('03/25/2018'));
	  insert into ftt(calltime) values (date('03/26/2018'));
	  insert into ftt(calltime) values (date('03/27/2018'));
	  insert into ftt(calltime) values (date('03/28/2018'));
	  insert into ftt(calltime) values (date('03/29/2018'));

	  
	  
	  update tlm_table set bak_tabname='ftt_old',bak_retention_num=15 where table_name='ftt';	
	  
	  	create table ftt_old
	  (
		calltime datetime year to second,
		callingnumber_key integer,
		callednumber_key integer,
		callingattr_key integer,
		calledattr_key integer,
		call_result_key integer,
		ringtime integer,
		callduration integer,
		islanjie integer
	  ) 
	  fragment by expression 
      partition p0 ((calltime >=to_date('20180501000000','%Y%m%d%H%M%S')) AND (calltime < to_date('20180502000000','%Y%m%d%H%M%S') ) ) in userdbs,
      partition rmd remainder in userdbs;
	  
	  
	  insert into fragtabinfo values(current year to second,'ftt_old','p0','20180501000000','20180502000000');	  
	  execute procedure del_par_for_date_interval('ftt');
	  
/*	  
	  date coltype=7
     select b.colname,b.coltype
     from systables a,syscolumns b
     where a.tabid=b.tabid and a.tabname='ft';
	
      datetime coltype=10	
     select b.colname,b.coltype
     from systables a,syscolumns b
     where a.tabid=b.tabid and a.tabname='ftt';
*/



	insert into tlm_table(table_name,column_fragment,time_granularity,retention_num,fragment_type,is_interval,interval_type,initial_highvalue) 
      values('fh','calltime',4,10,'2','1','hour','20180101000000');
	  
   create table fh
  (
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by range(calltime) interval(4 units hour)
    store in(userdbs) 
    partition p0 VALUES < to_date('20180101000000','%Y%m%d%H%M%S') in userdbs
  extent size 16 next size 16 lock mode page;
  
  
     insert into fh(calltime) values (to_date('20180107010000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107020000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107030000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107040000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107050000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107060000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107070000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107080000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107090000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107100000','%Y%m%d%H%M%S'));	 
	 insert into fh(calltime) values (to_date('2018010711000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('2018010712000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107130000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107140000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107150000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107160000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107170000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107180000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107190000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107200000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107210000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107220000','%Y%m%d%H%M%S'));
	 insert into fh(calltime) values (to_date('20180107230000','%Y%m%d%H%M%S')); 
	 
	 
	 execute procedure del_par_for_date_interval('fh');
	 
	 drop table fh_old;
	  create table fh_old
  (
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by expression 
      partition p0 ((calltime >=to_date('20170101000000','%Y%m%d%H%M%S')) AND (calltime < to_date('20180101000000','%Y%m%d%H%M%S') ) ) in userdbs,
      partition rmd remainder in userdbs;
	  
	  
 	  update tlm_table set bak_tabname='fh_old',bak_retention_num=15 where table_name='fh';	
	  insert into fragtabinfo values(current year to second,'fh_old','p0','20170101000000','20180101000000');


	  
 create table fm
  (
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by range(calltime) interval(1 units month)
    store in(userdbs) 
    partition p0 VALUES < to_date('20180101000000','%Y%m%d%H%M%S') in userdbs
  extent size 16 next size 16 lock mode page;


	insert into tlm_table(table_name,column_fragment,time_granularity,retention_num,fragment_type,is_interval,interval_type,initial_highvalue) 
      values('fm','calltime',1,10,'2','1','month','20180101000000');

	 
     insert into fm(calltime) values (to_date('20210107010000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20210207020000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20210307030000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20210407040000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20210507050000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20210607060000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20210707000000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20210807080000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20210907090000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20211007100000','%Y%m%d%H%M%S'));	 
	 insert into fm(calltime) values (to_date('20211107110000','%Y%m%d%H%M%S'));
	 insert into fm(calltime) values (to_date('20211207120000','%Y%m%d%H%M%S'));

	 
	 		 select count(*)
		 from  sysfragments a,systables b 
		 where a.tabid =b.tabid
		   and a.fragtype='T'
		   and a.evalpos >0
		   and b.tabname='fm';
		   
		   
	 execute procedure del_par_for_date_interval('fm');

		   
		   
		   
 create table fm_old
  (
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by expression 
      partition p0 ((calltime >=to_date('20170101000000','%Y%m%d%H%M%S')) AND (calltime < to_date('20180101000000','%Y%m%d%H%M%S') ) ) in userdbs,
      partition rmd remainder in userdbs;
	  
	  
 	  update tlm_table set bak_tabname='fm_old',bak_retention_num=15 where table_name='fm';	
	  insert into fragtabinfo values(current year to second,'fm_old','p0','20170101000000','20180101000000');
	  
	  
	  
	  
	  
	  
	  
	  
	   create table fy
  (
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by range(calltime) interval(1 units year)
    store in(userdbs) 
    partition p0 VALUES < to_date('19800101000000','%Y%m%d%H%M%S') in userdbs
  extent size 16 next size 16 lock mode page;


	insert into tlm_table(table_name,column_fragment,time_granularity,retention_num,fragment_type,is_interval,interval_type,initial_highvalue) 
      values('fy','calltime',1,3,'2','1','year','19800101000000');

	 
     insert into fy(calltime) values (to_date('19900101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('19910101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('19920101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('19930101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('19940101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('1995101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('19960101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('19970101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('19980101000000','%Y%m%d%H%M%S'));
	 insert into fy(calltime) values (to_date('19990101000000','%Y%m%d%H%M%S'));	 


	 
	 	select count(*)
		 from  sysfragments a,systables b 
		 where a.tabid =b.tabid
		   and a.fragtype='T'
		   and a.evalpos >0
		   and b.tabname='fy';
		   
		   
	 execute procedure del_par_for_date_interval('fy');

		   
		   
		   
 create table fy_old
  (
    calltime datetime year to second,
    callingnumber_key integer,
    callednumber_key integer,
    callingattr_key integer,
    calledattr_key integer,
    call_result_key integer,
    ringtime integer,
    callduration integer,
    islanjie integer
  ) 
  fragment by expression 
      partition p0 ((calltime >=to_date('19700101000000','%Y%m%d%H%M%S')) AND (calltime < to_date('19700101000000','%Y%m%d%H%M%S') ) ) in userdbs,
      partition rmd remainder in userdbs;
	  
	  
 	  update tlm_table set bak_tabname='fy_old',bak_retention_num=6 where table_name='fy';	
	  insert into fragtabinfo values(current year to second,'fy_old','p0','19700101000000','19700101000000');