drop procedure del_par_for_int;
create procedure del_par_for_int(p_tabname varchar(50))
        DEFINE sql_err INTEGER;
        DEFINE isam_err INTEGER;
        DEFINE err_txt CHAR(200);
        define v_begintime,v_endtime,v_maxvalue int;
        define i,j int;
        define sql varchar(255);
        define v_tabname,v_bak_tabname varchar(50);
        define v_retention_num int;
		define v_bak_retention_num int;
		define v_partition_info varchar(50);
		define v_procname varchar(50);
		define v_count,v_fragnum int;
		define v_colname varchar(50);
		define v_column_fragment varchar(50);

        set debug file to '/tmp/del_par_for_int.dbg';
        trace on;
		let v_procname='del_par_for_int';
		set lock mode to wait 5;
        for j in (1 to 4 step 1)		
            select column_fragment,retention_num,bak_tabname,bak_retention_num
                  into v_column_fragment,v_retention_num,v_bak_tabname,v_bak_retention_num from tlm_table where table_name=p_tabname;
            
            let v_maxvalue =getmaxvalue(p_tabname,v_column_fragment);	
            select count(*) into v_fragnum from fragtabinfo where tabname =p_tabname and endtime::int < v_maxvalue;	
            if v_fragnum > v_retention_num then
			
			    select min(begintime::int),min(endtime::int) into v_begintime,v_endtime from fragtabinfo where tabname=p_tabname;
			    select partition into v_partition_info from fragtabinfo where tabname=p_tabname and begintime=v_begintime;
			    
						  
				-- detach partition
				for i in (1 to 100 step 1) 
				   ON EXCEPTION SET sql_err, isam_err, err_txt
					   if i > 2 then
						 insert into tlm_errlog
						 values
						 (v_procname,p_tabname,current year to second,sql_err, isam_err, err_txt,i - 1);
					   end if;
                   END EXCEPTION WITH RESUME; 
					if exists (select b.tabname from sysfragments a, systables b
					 where a.tabid=b.tabid and b.tabname=p_tabname and a.partition=v_partition_info )
					then
						let sql='alter fragment on table '||p_tabname||' detach '||v_partition_info||' '||p_tabname||v_partition_info;
						execute immediate sql;
					else    
						 update TLM_table set last_date= current year to second where table_name = p_tabname;
					     delete from fragtabinfo where tabname=p_tabname and partition = v_partition_info;
						 exit for;
					end if;   
				end for;
			    -- attach partiton into baktab
				if exists (select a.tabname from systables a where a.tabname=p_tabname||v_partition_info) then
				    
					if v_bak_tabname = 'none' then
						let sql='drop table '||' '||p_tabname||v_partition_info;
						execute immediate sql;
					else
						select count(*) into v_count from systables a,syscolumns b
                          where a.tabid=b.tabid and b.coltype=6 and a.tabname=p_tabname||v_partition_info;
						if v_count > 0 then
							select b.colname into v_colname from systables a,syscolumns b
									   where a.tabid=b.tabid and b.coltype=6 and a.tabname=p_tabname||v_partition_info;
							let sql = 'alter table ' ||p_tabname||v_partition_info||' modify '||v_colname||' int';
							execute immediate sql;
						end if;
						let sql='alter fragment on table  '||v_bak_tabname||' attach '||p_tabname||v_partition_info||' as partition '||v_partition_info||'('||v_column_fragment||'>='''||v_begintime||''' and '||v_column_fragment||'<'''||v_endtime||''' )';
						execute immediate sql;
					end if;	 
				end if;
				
				if  exists(select b.tabname from sysfragments a, systables b
                    where a.tabid=b.tabid and b.tabname=v_bak_tabname and a.partition=v_partition_info) 
				then 
					insert into fragtabinfo(optime,tabname,partition,begintime,endtime) values(current year to second,v_bak_tabname,v_partition_info,v_begintime,v_endtime);
				end if;
			end if;
			
			
			-- bak_tabname del_par_for_date
			if v_bak_tabname !='none' then	
                select count(*) into v_fragnum from fragtabinfo where tabname =v_bak_tabname;
                if v_fragnum > v_bak_retention_num then	
					select min(begintime::int),min(endtime::int) into v_begintime,v_endtime from fragtabinfo where tabname=v_bak_tabname;
			        select partition into v_partition_info from fragtabinfo where tabname=v_bak_tabname and begintime=v_begintime;					  
					-- detach partition
					for i in (1 to 100 step 1) 
					    ON EXCEPTION SET sql_err, isam_err, err_txt
							if i > 2 then
							insert into tlm_errlog values
						       (v_procname,v_bak_tabname,current year to second,sql_err, isam_err, err_txt,i - 1);
					        end if;
                        END EXCEPTION WITH RESUME; 
						if exists (select b.tabname from sysfragments a, systables b
						 where a.tabid=b.tabid and b.tabname=v_bak_tabname and a.partition=v_partition_info )
						then
							let sql='alter fragment on table '||v_bak_tabname||' detach '||v_partition_info||' '||v_bak_tabname||v_partition_info;
							execute immediate sql;
						else    
							 delete from fragtabinfo where tabname=v_bak_tabname and partition = v_partition_info;
							 exit for;
						end if;   
					end for;
			    -- drop 
					if exists (select a.tabname from systables a where a.tabname=v_bak_tabname||v_partition_info) then
							let sql='drop table '||' '||v_bak_tabname||v_partition_info;
							execute immediate sql; 
					end if;
				end if;
			end if;
	    end for;	  
end procedure; 


--execute procedure del_par_for_int('txcy_deliverinfo');