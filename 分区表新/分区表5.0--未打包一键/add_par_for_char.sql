drop procedure add_par_for_char;
create procedure add_par_for_char(p_tabname varchar(50))
        DEFINE sql_err INTEGER;
        DEFINE isam_err INTEGER;
        DEFINE err_txt varchar(200);
        define v_column_fragment varchar(50);
        define v_time_granularity int;
        define v_dbs_name varchar(50);
        define v_highvalue varchar(20);
		define v_partition_info varchar(50);
        define i,j int;
        define v_datetime datetime year to second;
        define v_chartime,v_addpartname varchar(20);
        define sql varchar(255);
		define v_procname varchar(50);
        set debug file to '/tmp/add_par_for_char.dbg';
        trace on;
		let v_procname ='add_par_for_char';
		for j in (1 to 4 step 1)
				select column_fragment,time_granularity,dbs_name
				  into v_column_fragment,v_time_granularity,v_dbs_name from tlm_table where table_name=p_tabname; 
				select max(partition) into v_partition_info from fragtabinfo where tabname=p_tabname;
				select max(endtime) into v_highvalue from fragtabinfo where tabname=p_tabname;
				if to_date(v_highvalue,'%Y%m%d%H%M%S') > current year to second + interval(1) hour to hour * v_time_granularity * 4 then 
					  exit for;
				end if;
				let v_datetime=to_date(v_highvalue,'%Y%m%d%H%M%S')+ interval(1) hour to hour * v_time_granularity;
				let v_chartime=to_char(v_datetime,'%Y%m%d%H%M%S'); 
				let v_addpartname='p'||substr(v_highvalue,0,10);
				  
				set lock mode to wait 5;    
				for i in (1 to 100 step 1)        
				  ON EXCEPTION SET sql_err, isam_err, err_txt
				  END EXCEPTION WITH RESUME;       
				  if not exists (select b.tabname from sysfragments a, systables b
						  where a.tabid=b.tabid and b.tabname=p_tabname and a.partition=v_addpartname)
				  then
					  let sql='alter fragment on table '||p_tabname||' add partition '||v_addpartname||'('||v_column_fragment||'>='''||v_highvalue||''' and '||v_column_fragment||'<'''||v_chartime||''' )in '||v_dbs_name;
					  execute immediate sql;
				  else
					  update TLM_table set last_date= current year to second where table_name = p_tabname;
					  insert into fragtabinfo(optime,tabname,partition,begintime,endtime) 
						 values(current year to second,p_tabname,v_addpartname,v_highvalue,v_chartime);
					  exit for;
				  end if;
				end for;
				if i > 2 then
							 insert into tlm_errlog
							 values
							 (v_procname,p_tabname,current year to second,sql_err, isam_err, err_txt,i - 1);
				end if;
		end for;
end procedure;