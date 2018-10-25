drop procedure del_par_for_date;
create procedure del_par_for_date()
        DEFINE sql_err INTEGER;
        DEFINE isam_err INTEGER;
        DEFINE err_txt CHAR(200);
        define v_begintime,v_endtime varchar(20);
        define i int;
        define sql varchar(255);
        define v_tabname,v_bak_tabname varchar(50);
        define v_retention_days int;
		define v_bak_retention_days int;
		define v_partition_info varchar(50);
		define v_procname varchar(50);
		define v_count int;
		define v_colname varchar(50);

		define v_column_fragment varchar(50);

        set debug file to '/home/informix/frag/del_par_for_date.dbg';
        trace on;
		let v_procname='del_par_for_date';
        foreach select table_name,column_fragment,retention_days,bak_tabname,bak_retention_days
                  into v_tabname,v_column_fragment,v_retention_days,v_bak_tabname,v_bak_retention_days from tlm_table 
		   
            select min(partition) into v_partition_info from fragtabinfo where tabname=v_tabname;
			select begintime,endtime into v_begintime,v_endtime from fragtabinfo where tabname=v_tabname and partition = v_partition_info;
			set lock mode to wait 5;
		    -- table_name del_par_for_date 
			if to_date(v_endtime,'%Y%m%d%H%M%S') + interval(1) day to day * v_retention_days <= current year to second  then 
				  
				-- detach partition
				for i in (1 to 100 step 1) 
				   ON EXCEPTION SET sql_err, isam_err, err_txt
					   if i > 2 then
						 insert into tlm_errlog
						 values
						 (v_procname,v_tabname,current year to second,sql_err, isam_err, err_txt,i - 1);
					   end if;
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
			    -- attach partiton into baktab
				if exists (select a.tabname from systables a where a.tabname=v_tabname||v_partition_info) then
				    
					if v_bak_tabname = 'none' then
						let sql='drop table '||' '||v_tabname||v_partition_info;
						execute immediate sql;
					else
						
						select count(*) into v_count from systables a,syscolumns b
                          where a.tabid=b.tabid and b.coltype=6 and a.tabname=v_tabname||v_partition_info;
						if v_count > 0 then
							select b.colname into v_colname from systables a,syscolumns b
									   where a.tabid=b.tabid and b.coltype=6 and a.tabname=v_tabname||v_partition_info;
							let sql = 'alter table ' ||v_tabname||v_partition_info||' modify '||v_colname||' int';
							execute immediate sql;
						end if;
						let sql='alter fragment on table  '||v_bak_tabname||' attach '||v_tabname||v_partition_info||' as partition '||v_partition_info||'('||v_column_fragment||'>='''||v_begintime||''' and '||v_column_fragment||'<'''||v_endtime||''' )';
						execute immediate sql;
					end if;	 
				end if;
				
				if  not exists (select b.tabname from sysfragments a, systables b
                    where a.tabid=b.tabid and b.tabname=v_tabname and a.partition=v_partition_info) 
				then 
					update TLM_table set last_date= current year to second where table_name = v_tabname;
					delete from fragtabinfo where tabname=v_tabname and partition = v_partition_info;
				end if;
				if  exists(select b.tabname from sysfragments a, systables b
                    where a.tabid=b.tabid and b.tabname=v_bak_tabname and a.partition=v_partition_info) 
				then 
					insert into fragtabinfo(optime,tabname,partition,begintime,endtime) values(current year to second,v_bak_tabname,v_partition_info,v_begintime,v_endtime);
				end if;
			end if;
			
			
			-- bak_tabname del_par_for_date
			if v_bak_tabname !='none' then
				select min(partition) into v_partition_info from fragtabinfo where tabname=v_bak_tabname;
				select begintime,endtime into v_begintime,v_endtime from fragtabinfo where tabname=v_bak_tabname and partition = v_partition_info;
				if to_date(v_endtime,'%Y%m%d%H%M%S') + interval(1) day to day * v_bak_retention_days <= current year to second  then 
				  
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
							 exit for;
						end if;   
					end for;
			    -- drop 
					if exists (select a.tabname from systables a where a.tabname=v_bak_tabname||v_partition_info) then
							let sql='drop table '||' '||v_bak_tabname||v_partition_info;
							execute immediate sql; 
					end if;

					
					if  not exists(select b.tabname from sysfragments a, systables b
                         where a.tabid=b.tabid and b.tabname=v_bak_tabname and a.partition=v_partition_info) 
			        then 
						delete from fragtabinfo where tabname=v_bak_tabname and partition = v_partition_info;
				    end if;
				end if;
			end if;
		  
        end foreach;  
end procedure; 
