drop procedure del_par_for_date_interval;
create procedure del_par_for_date_interval(p_tabname varchar(50))
        DEFINE sql_err INTEGER;
        DEFINE isam_err INTEGER;
        DEFINE err_txt CHAR(200);
		define v_begintime,v_endtime datetime year to second;
        define v_begintime_c,v_endtime_c varchar(20);
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
		define v_interval_type varchar(10);
		define v_initial_highvalue datetime year to second;
		define v_evalpos int;
		define v_time_granularity int;

        set debug file to '/tmp/del_par_for_date_interval.dbg';
        trace on;
		let v_procname='del_par_for_date_interval';
		set lock mode to wait 5;
        for j in (1 to 4 step 1)		
            select column_fragment,time_granularity,retention_num,bak_tabname,bak_retention_num,interval_type,to_date(initial_highvalue,'%Y%m%d%H%M%S')
                  into v_column_fragment,v_time_granularity,v_retention_num,v_bak_tabname,v_bak_retention_num,v_interval_type,v_initial_highvalue 
			from tlm_table where table_name=p_tabname;
            
            select count(*) into v_fragnum
		     from  sysfragments a,systables b 
			 where a.tabid =b.tabid
			   and a.fragtype='T'
			   and a.evalpos >0
			   and b.tabname=p_tabname;	
           
            if v_fragnum > v_retention_num then
			 
			    select min(evalpos) into v_evalpos
		        from  sysfragments a,systables b 
			    where a.tabid =b.tabid
			     and a.fragtype='T'
			     and a.evalpos >0
			     and b.tabname=p_tabname;	
				
				if v_interval_type ='hour' then 
					let v_endtime = v_initial_highvalue + v_evalpos * v_time_granularity units hour ;
					let v_begintime = v_initial_highvalue + ( v_evalpos -1 ) * v_time_granularity units hour ;
				 elif v_interval_type ='day' then
				    let v_endtime = v_initial_highvalue + v_evalpos * v_time_granularity units day ;
					let v_begintime = v_initial_highvalue + ( v_evalpos -1 ) * v_time_granularity units day ;
				 elif v_interval_type='month' then
				    let v_endtime = v_initial_highvalue + v_evalpos * v_time_granularity units month ;
					let v_begintime = v_initial_highvalue + ( v_evalpos -1 ) * v_time_granularity units month ;
				 elif v_interval_type='year' then
				    let v_endtime = v_initial_highvalue + v_evalpos * v_time_granularity units year ;
					let v_begintime = v_initial_highvalue + ( v_evalpos -1 ) * v_time_granularity units year ;
				 else
				    insert into tlm_errlog
						 values
						 (v_procname,p_tabname,current year to second,-1, -1, 'please check tlm_table interval_type ',j);
				    exit for;
				end if;
				
				let v_endtime_c=to_char(v_endtime,'%Y%m%d%H%M%S'); 
				let v_begintime_c=to_char(v_begintime,'%Y%m%d%H%M%S');
				
				select partition into v_partition_info
		        from  sysfragments a,systables b 
			    where a.tabid =b.tabid
			     and a.fragtype='T'
			     and a.evalpos =v_evalpos
			     and b.tabname=p_tabname;
			    
						  
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
						let sql='alter fragment online on table '||p_tabname||' detach partition '||v_partition_info||' '||p_tabname||v_partition_info;
						execute immediate sql;
					else    
						 update TLM_table set last_date= current year to second where table_name = p_tabname;
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
						select count(*) into v_count from systables a,syscolumns b
                          where a.tabid=b.tabid and b.coltype=7 and a.tabname=p_tabname||v_partition_info;
						if v_count > 0 then
						    let sql='alter fragment on table  '||v_bak_tabname||' attach '||p_tabname||v_partition_info||' as partition '||v_partition_info||'('||v_column_fragment||'>='''||date(v_begintime)||''' and '||v_column_fragment||'<'''||date(v_endtime)||''' )';
						    execute immediate sql;
						end if;
						select count(*) into v_count from systables a,syscolumns b
                          where a.tabid=b.tabid and b.coltype=10 and a.tabname=p_tabname||v_partition_info;
						if v_count > 0 then
						   let sql='alter fragment on table  '||v_bak_tabname||' attach '||p_tabname||v_partition_info||' as partition '||v_partition_info||'('||v_column_fragment||'>='''||v_begintime||''' and '||v_column_fragment||'<'''||v_endtime||''' )';
						   execute immediate sql;
						end if;
					end if;	 
				end if;
				
				if  exists(select b.tabname from sysfragments a, systables b
                    where a.tabid=b.tabid and b.tabname=v_bak_tabname and a.partition=v_partition_info) 
				then 
					insert into fragtabinfo(optime,tabname,partition,begintime,endtime) values(current year to second,v_bak_tabname,v_partition_info,v_begintime_c,v_endtime_c);
				end if;
			end if;
			
			
			-- bak_tabname del_par_for_date
			if v_bak_tabname !='none' then	
                select count(*) into v_fragnum from fragtabinfo where tabname =v_bak_tabname;
                if v_fragnum > v_bak_retention_num then	
					
					select min(endtime) into v_endtime_c from fragtabinfo where tabname=v_bak_tabname;
					select min(begintime),min(endtime) into v_begintime_c,v_endtime_c from fragtabinfo where tabname=v_bak_tabname;
			        select partition into v_partition_info from fragtabinfo where tabname=v_bak_tabname and endtime=v_endtime_c;					  
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


--execute procedure del_par_for_date_interval('ft');