create table "informix".mcn_smlogtemp 
  (
    streamnumber integer ,
    usernumber char(16),
    mcnnumber char(16),
    mcnimsi char(16),
    callingnumber char(20),
    msgtype char(1),
    dcs integer,
    refernum integer,
    totalnum integer 
        default 1,
    sequencenum integer 
        default 0,
    shortmsgtext char(250),
    shortmeglen integer,
    recvtime char(14),
    ifsendflag char(1)
  ) 
  fragment by expression 
    partition p2000010100 ((optime >= '20000101000000' 
              ) AND (optime < '20000111000000' ) ) in userdbs, 			  
    partition rmd remainder in userdbs
  extent size 4096 next size 2048 lock mode row;

revoke all on "informix".mcn_smlogtemp_old from "public" as "informix";


create index "informix".idx_smlog_mcnnumber1ft_old on "informix".mcn_smlogtemp_old 
    (mcnnumber) using btree  in userdbs;
create index "informix".idx_smlog_usernumber1ft_old on "informix".mcn_smlogtemp_old 
    (usernumber) using btree  in userdbs;
create index "informix".idx_smlog_streamnumber1ft_old on "informix".mcn_smlogtemp_old 
    (usernumber) using btree  in userdbs;
