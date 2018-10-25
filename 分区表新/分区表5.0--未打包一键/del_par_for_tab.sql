drop procedure del_par_for_tab;
create procedure del_par_for_tab()
        DEFINE sql_err INTEGER;
        DEFINE isam_err INTEGER;
        DEFINE err_txt varchar(200);
        define v_tabname varchar(50);
        define v_fragment_type char(1);
		define v_is_interval char(1);
		define v_procname varchar(50);
        set debug file to '/tmp/del_par_for_tab.dbg';
        trace on;
		let v_procname ='del_par_for_tab';
        foreach select table_name,fragment_type,is_interval
                  into v_tabname,v_fragment_type,v_is_interval from tlm_table  
			 if v_fragment_type ='0' then
				 call del_par_for_char(v_tabname);
			 end if;
			 if v_fragment_type ='1' and v_is_interval = '0' then
				 call del_par_for_int(v_tabname);
			 end if;
			 if v_fragment_type ='1' and v_is_interval = '1' then
				 call del_par_for_int_interval(v_tabname);
			 end if;			 
			 if v_fragment_type='2' and v_is_interval ='0'then
				 call del_par_for_date(v_tabname);
			 end if;
			 if v_fragment_type='2' and v_is_interval ='1'then
				 call del_par_for_date_interval(v_tabname);
			 end if;
         end foreach;
end procedure;

--execute procedure del_par_for_tab();