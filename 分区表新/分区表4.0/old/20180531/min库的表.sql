create table "informix".mcn_contralogtemp 
  (
    streamnumber serial not null ,
    servicekey integer,
    calltype char(1),
    chargetype char(1),
    roamflag char(1),
    callingpartynumber char(16),
    calledpartynumber char(24),
    mcnnumber char(16),
    roamareanumber char(6),
    mscaddress char(16),
    callreferencenum char(16),
    msinfovlrnumber char(20),
    msinfolai char(10),
    msinfocellid char(14),
    msinfoimsi char(16),
    callbegintime char(14),
    callendtime char(14),
    callduration integer,
    chargepartyindicat char(1),
    extbearercapabilit char(27),
    teleservicecode char(10),
    bearerservicecode char(10),
    scfid char(10),
    callingvareanumber char(6),
    calledvareanumber char(6),
    callinghlrnumber char(6),
    calledhlrnumber char(6),
    callingpartyscateg smallint,
    redirectingpartyid char(16),
    redirectioninfor char(4),
    subscriberstate smallint,
    cause char(5),
    reason char(2),
    internumflag char(1) 
        default '0' not null 
  ) 
  fragment by expression 
    partition p2018032600 ((callbegintime >= '20180326000000' 
              ) AND (callbegintime < '20180402000000' ) ) in userdbs,
    partition p2018040200 ((callbegintime >= '20180402000000' 
              ) AND (callbegintime < '20180409000000' ) ) in userdbs,
    partition p2018040900 ((callbegintime >= '20180409000000' 
              ) AND (callbegintime < '20180416000000' ) ) in userdbs,
    partition p2018041600 ((callbegintime >= '20180416000000' 
              ) AND (callbegintime < '20180423000000' ) ) in userdbs,
    partition p2018042300 ((callbegintime >= '20180423000000' 
              ) AND (callbegintime < '20180430000000' ) ) in userdbs,
    partition p2018043000 ((callbegintime >= '20180430000000' 
              ) AND (callbegintime < '20180507000000' ) ) in userdbs,
    partition rmd remainder in userdbs
  extent size 64000 next size 64000 lock mode row;


revoke all on "informix".mcn_contralogtemp from "public" as "informix";


create index "informix".idx1204_contralog_callingpartynumberft1 
    on "informix".mcn_contralogtemp (callingpartynumber) using btree 
    ;
create index "informix".idx1204_contralog_streamnumberft1 on "informix"
    .mcn_contralogtemp (streamnumber) using btree ;
create index "informix".idx1204_mcnnumberft1 on "informix".mcn_contralogtemp 
    (mcnnumber) using btree ;


create table "informix".mcn_smslogtemp 
  (
    streamnumber serial not null ,
    smsseqno char(20),
    msgid varchar(50),
    chargetype smallint,
    phonenumber char(16),
    mcnnumber char(16),
    sendorrecenum char(24),
    orginalnum char(24),
    optime char(14),
    msgresult char(2),
    failreason char(10)
  ) 
  fragment by expression 
    partition p2018032600 ((optime >= '20180326000000' ) AND 
    (optime < '20180402000000' ) ) in userdbs,
    partition p2018040200 ((optime >= '20180402000000' ) AND 
    (optime < '20180409000000' ) ) in userdbs,
    partition p2018040900 ((optime >= '20180409000000' ) AND 
    (optime < '20180416000000' ) ) in userdbs,
    partition p2018041600 ((optime >= '20180416000000' ) AND 
    (optime < '20180423000000' ) ) in userdbs,
    partition p2018042300 ((optime >= '20180423000000' ) AND 
    (optime < '20180430000000' ) ) in userdbs,
    partition p2018043000 ((optime >= '20180430000000' ) AND 
    (optime < '20180507000000' ) ) in userdbs,
    partition rmd remainder in userdbs
  extent size 64000 next size 64000 lock mode page;


revoke all on "informix".mcn_smslogtemp from "public" as "informix";


create index "informix".idx1204_smslog_mcnnumber1_rebuildft1 on 
    "informix".mcn_smslogtemp (mcnnumber) using btree ;
create index "informix".idx1204_smslog_phonenumber1_rebuildft1 
    on "informix".mcn_smslogtemp (phonenumber) using btree ;
create index "informix".idx1204_smslog_sendorrecenumft1 on "informix"
    .mcn_smslogtemp (sendorrecenum) using btree ;
create index "informix".idx1204_smslog_streamnumberft1 on "informix"
    .mcn_smslogtemp (streamnumber) using btree ;


create table "informix".mcn_mid_voicelogtemp 
  (
    streamnumber serial not null ,
    servicekey integer,
    midgroupid char(20),
    calltype integer,
    oroamareanum integer,
    callingmsisdn char(20),
    callingnumtype char(1),
    mcnnumber char(16),
    calledmsisdn char(20),
    callednumtype char(1),
    maxallowtime char(5),
    mscaddress char(40),
    callreferencenum char(16),
    startdatetime char(14),
    enddatetime char(14),
    callduration integer,
    chargepartyindicat integer,
    scfid char(10),
    redirectingpartyid char(16),
    rccause char(10),
    callresult char(2),
    bindid char(32),
    midcallid char(40),
    cityid integer,
    realcallduration integer,
    record char(1) 
        default '0',
    gxbgroupid char(22),
    mcnnumbery char(16),
    startcalltime char(14),
    logtype char(1) 
        default '0',
    recordresult char(1),
    recordmsip char(30),
    callout char(1) 
        default '0'
  ) 
  fragment by expression 
    partition p2018032600 ((startdatetime >= '20180326000000' 
              ) AND (startdatetime < '20180402000000' ) ) in userdbs,
    partition p2018040200 ((startdatetime >= '20180402000000' 
              ) AND (startdatetime < '20180409000000' ) ) in userdbs,
    partition p2018040900 ((startdatetime >= '20180409000000' 
              ) AND (startdatetime < '20180416000000' ) ) in userdbs,
    partition p2018041600 ((startdatetime >= '20180416000000' 
              ) AND (startdatetime < '20180423000000' ) ) in userdbs,
    partition p2018042300 ((startdatetime >= '20180423000000' 
              ) AND (startdatetime < '20180430000000' ) ) in userdbs,
    partition p2018043000 ((startdatetime >= '20180430000000' 
              ) AND (startdatetime < '20180507000000' ) ) in userdbs,
    partition rmd remainder in userdbs
  extent size 64000 next size 64000 lock mode row;


revoke all on "informix".mcn_mid_voicelogtemp from "public" as "informix";


create index "informix".idx1204_midvlog_grpidft1 on "informix".mcn_mid_voicelogtemp 
    (midgroupid) using btree ;
create index "informix".idx1204_midvlog_mcnnumft1 on "informix"
    .mcn_mid_voicelogtemp (mcnnumber) using btree ;
create index "informix".idx1204_midvlog_streamnumberft1 on "informix"
    .mcn_mid_voicelogtemp (streamnumber) using btree ;




create table "informix".mcn_oplogtemp 
  (
    streamnumber serial not null ,
    phonenumber char(16),
    optype char(2),
    optime char(14),
    qmcnnumber char(16),
    hmcnnumber char(16),
    blacknumber char(16),
    whitenumber char(16),
    qphonenumber char(16),
    opmanner smallint,
    locationid char(10),
    provinceid smallint,
    mcnnature char(1),
    servid char(10),
    activityid char(20),
    adsource char(10),
    media char(10)
  ) 
  fragment by expression 
    partition p2018021600 ((optime >= '20180216000000' ) AND 
    (optime < '20180318000000' ) ) in userdbs,
    partition p2018031800 ((optime >= '20180318000000' ) AND 
    (optime < '20180417000000' ) ) in userdbs,
    partition p2018041700 ((optime >= '20180417000000' ) AND 
    (optime < '20180517000000' ) ) in userdbs,
    partition p2018051700 ((optime >= '20180517000000' ) AND 
    (optime < '20180616000000' ) ) in userdbs,
    partition p2018061600 ((optime >= '20180616000000' ) AND 
    (optime < '20180716000000' ) ) in userdbs,
    partition p2018071600 ((optime >= '20180716000000' ) AND 
    (optime < '20180815000000' ) ) in userdbs,
    partition rmd remainder in userdbs
  extent size 64000 next size 64000 lock mode row;


revoke all on "informix".mcn_oplogtemp from "public" as "informix";


create index "informix".idx_oplog_hmcnnumberft1 on "informix".mcn_oplogtemp 
    (hmcnnumber) using btree ;
create index "informix".idx_oplog_phonenumber_locationidft1 on 
    "informix".mcn_oplogtemp (phonenumber) using btree ;
create index "informix".idx_oplog_streamft1 on "informix".mcn_oplogtemp 
    (streamnumber) using btree ;


