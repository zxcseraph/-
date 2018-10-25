create procedure add_par_for_date()
        DEFINE sql_err INTEGER;
        DEFINE isam_err INTEGER;
        DEFINE err_txt varchar(200);
        define v_tabname varchar(50);
        define v_column_fragment varchar(50);
        define v_time_granularity int;
        define v_dbs_name varchar(50);
        define v_highvalue varchar(20);
		define v_partition_sys,v_partition_info varchar(50);
        define i int;
        define v_datetime datetime year to second;
        define v_chartime,v_addpartname varchar(20);
        define sql varchar(255);
        set debug file to '/home/informix/frag/add_par_for_date.dbg';
        trace on;
        foreach select table_name,column_fragment,time_granularity,dbs_name
                  into v_tabname,v_column_fragment,v_time_granularity,v_dbs_name from tlm_table  

		    select max(partition) into v_partition_info from fragtabinfo where tabname=v_tabname;
		    select max(b.partition) into v_partition_sys
	        from systables a,sysfragments b
	        where a.tabname=v_tabname and a.tabid = b.tabid
	        and b.fragtype='T' and b.partition like 'p%'; 
            if v_partition_info != v_partition_sys then
				insert into tlm_errlog
                     values
                     ('add_par_for_date',v_tabname,current year to second,-1, -1,'fragtabinfo is not consistent with sysfragments',1);
				continue foreach;
			end if;
			select max(endtime) into v_highvalue from fragtabinfo where tabname=v_tabname;

	        if to_date(v_highvalue,'%Y%m%d%H%M%S') > current year to second + interval(1) hour to hour * v_time_granularity * 4 then 
	          continue foreach;
	        end if;
	        let v_datetime=to_date(v_highvalue,'%Y%m%d%H%M%S')+ interval(1) hour to hour * v_time_granularity;
	        let v_chartime=to_char(v_datetime,'%Y%m%d%H%M%S'); 
            let v_addpartname='p'||substr(v_highvalue,0,10);
          
	      	set lock mode to wait 5;    
       	 for i in (1 to 100 step 1)        
          ON EXCEPTION SET sql_err, isam_err, err_txt
          END EXCEPTION WITH RESUME;       
          if not exists (select b.tabname from sysfragments a, systables b
                  where a.tabid=b.tabid and b.tabname=v_tabname and a.partition=v_addpartname)
         then
              let sql='alter fragment on table '||v_tabname||' add partition '||v_addpartname||'('||v_column_fragment||'>='''||v_highvalue||''' and '||v_column_fragment||'<'''||v_chartime||''' )in '||v_dbs_name;
              execute immediate sql;
         else
               exit for;
         end if;
        end for;
        if i > 2 then
                     insert into tlm_errlog
                     values
                     ('add_par_for_date',v_tabname,current year to second,sql_err, isam_err, err_txt,i - 1);
        end if;
        if  exists (select b.tabname from sysfragments a, systables b
                    where a.tabid=b.tabid and b.tabname=v_tabname and a.partition=v_addpartname)
          then 
              update TLM_table set last_date= current year to second where table_name = v_tabname;
			  insert into fragtabinfo(optime,tabname,partition,begintime,endtime) 
			     values(current year to second,v_tabname,v_addpartname,v_highvalue,v_chartime);
        end if;
      end foreach;
end procedure;