drop procedure getmaxvalue;
create procedure getmaxvalue(p_tab varchar(20),p_col varchar(20))
returning int;
        DEFINE sql_err INTEGER;
        DEFINE isam_err INTEGER;
        DEFINE err_txt varchar(200);
        define v_maxvalue int;
		define v_procname varchar(50);
		define v_sql varchar(200);
        set debug file to '/tmp/getmaxvalue.dbg';
        trace on;
		let v_procname ='getmaxvalue';
		let v_sql = 'select max('||p_col||') as m from '||p_tab|| ' into temp tmp';
        execute immediate v_sql;
		select m into v_maxvalue from tmp;
		drop table tmp;
		return v_maxvalue;
end procedure;

--execute procedure getmaxvalue('txcy_deliverinfo','streamnumber')