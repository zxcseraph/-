create table "informix".mcn_smlogtemp 
  (
    streamnumber serial not null ,
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
    partition p2018030100 ((recvtime >= '20180301000000' 
              ) AND (recvtime < '20180310000000' ) ) in userdbs, 			  
    partition p2018031000 ((optime >= '20180310000000' 
              ) AND (recvtime < '20180320000000' ) ) in userdbs,
    partition rmd remainder in userdbs
  extent size 4096 next size 2048 lock mode row;

revoke all on "informix".mcn_smlogtemp from "public" as "informix";


create index "informix".idx_smlog_mcnnumber1ft on "informix".mcn_smlogtemp 
    (mcnnumber) using btree  in userdbs;
create index "informix".idx_smlog_usernumber1ft on "informix".mcn_smlogtemp 
    (usernumber) using btree  in userdbs;
create index "informix".idx_smlog_streamnumber1ft on "informix".mcn_smlogtemp 
    (usernumber) using btree  in userdbs;
