# -*- coding: UTF-8 -*- 
import sqlite3;
import sys;


dodir=sys.argv[1];
dbname=dodir+"/test.db"
conn = sqlite3.connect(dbname)
c = conn.cursor()
c.execute("create table seqfx(timenow text,lockid  integer,partnum integer,tabname1 text,tabname2 text,dbsname text,flags integer,nrows integer,seqscans integer);")
conn.commit()
c.execute(".import ?/table.old seqfx",(dodir));
conn.commit()
c.execute(".import ?/table.new seqfx",(dodir));
conn.commit()
c.execute("create index idx_seqfx on seqfx(partnum);");
conn.commit()
result=c.execute("select b.timenow,b.lockid,b.partnum,b.tabname1,b.tabname2,b.dbsname,b.flags,b.nrows,b.seqscans-a.seqscans from seqfx a,seqfx b where a.partnum=b.partnum and a.timenow<b.timenow;");
print result;
conn.close()