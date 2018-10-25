create table inms_pm_data 
  (
    jobid char(6) not null ,
    host varchar(64) not null ,
    account varchar(64) not null ,
    pid varchar(20),
    tid varchar(20),
    endtime char(19) not null ,
    seqno integer not null ,
    inserttime char(19) not null ,
    statnum integer not null ,
    stat01 varchar(64),
    stat02 varchar(64),
    stat03 varchar(64),
    stat04 varchar(64),
    stat05 varchar(64),
    stat06 varchar(64),
    stat07 varchar(64),
    stat08 varchar(64),
    stat09 varchar(64),
    stat10 varchar(64),
    stat11 varchar(64),
    stat12 varchar(64),
    stat13 varchar(64),
    stat14 varchar(64),
    stat15 varchar(64),
    stat16 varchar(64),
    stat17 varchar(64),
    stat18 varchar(64),
    stat19 varchar(64),
    stat20 varchar(64),
    stat21 varchar(64),
    stat22 varchar(64),
    stat23 varchar(64),
    stat24 varchar(64),
    stat25 varchar(64),
    stat26 varchar(64),
    stat27 varchar(64),
    stat28 varchar(64),
    stat29 varchar(64)
  ) extent size 128 next size 128 lock mode page;


create index idx_inms_pm_data_inserttime on inms_pm_data 
    (inserttime) using btree  in userdbs;

create index idx_inms_pm_data_endtime on inms_pm_data 
    (endtime) using btree  in userdbs;

create table inms_pm_datamgr 
  (
    jobid char(6),
    host varchar(64),
    account varchar(64),
    pid varchar(20),
    tid varchar(20),
    endtime char(19),
    datanum integer
  ) ;