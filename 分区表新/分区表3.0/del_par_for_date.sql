create procedure del_par_for_date()
        DEFINE sql_err INTEGER;
        DEFINE isam_err INTEGER;
        DEFINE err_txt CHAR(200);
        define v_highvalue varchar(20);
        define i int;
        define sql varchar(255);
        define v_tabname varchar(50);
        define v_retention_days int;
		define v_partition_sys,v_partition_info varchar(50);
        set debug file to '/home/informix/frag/del_par_for_date.dbg';
        trace on;
        foreach select table_name,retention_days 
                  into v_tabname,v_retention_days from tlm_table 
		   
			select min(partition) into v_partition_info from fragtabinfo where tabname=v_tabname;
		    select min(b.partition) into v_partition_sys
			 from systables a,sysfragments b
			 where a.tabname=v_tabname and a.tabid = b.tabid
			 and b.fragtype='T' and b.evalpos = 0; 
			
            if v_partition_info != v_partition_sys then
				insert into tlm_errlog
                     values
                     ('del_par_for_date',v_tabname,current year to second,-1, -1,'fragtabinfo is not consistent with sysfragments',1);
				continue foreach;
			end if;
			select min(endtime) into v_highvalue from fragtabinfo where tabname=v_tabname;
			
			if to_date(v_highvalue,'%Y%m%d%H%M%S') + interval(1) day to day * v_retention_days > current year to second  then 
				  continue foreach;
			   end if;
        set lock mode to wait 5;
        for i in (1 to 100 step 1) 
            ON EXCEPTION SET sql_err, isam_err, err_txt
            END EXCEPTION WITH RESUME;        
            if exists (select b.tabname from sysfragments a, systables b
             where a.tabid=b.tabid and b.tabname=v_tabname and a.partition=v_partition_info )
            then
                let sql='alter fragment on table '||v_tabname||' detach '||v_partition_info||' '||v_tabname||v_partition_info;
                execute immediate sql;
            else    
                 exit for;
            end if;   
         end for;
          if exists (select a.tabname from systables a where a.tabname=v_tabname||v_partition_info)
                 then
                 let sql='drop table '||' '||v_tabname||v_partition_info;
                 execute immediate sql;
          end if;
          if i > 2 then
                     insert into tlm_errlog
                     values
                     ('del_par_for_date',v_tabname,current year to second,sql_err, isam_err, err_txt,i - 1);
          end if;
          if  not exists (select b.tabname from sysfragments a, systables b
                    where a.tabid=b.tabid and b.tabname=v_tabname and a.partition=v_partition_info) 
                    and not exists (select a.tabname from systables a where a.tabname=v_tabname||v_partition_info)
          then 
              update TLM_table set last_date= current year to second where table_name = v_tabname;
			  delete from fragtabinfo where tabname=v_tabname and partition = v_partition_info;
          end if;
        end foreach;  
end procedure; 