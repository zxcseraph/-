--
--  Copyright(C) 2000 EASTCOM-BUPT Inc.
--
--  Created By          : $Author: scf $
--  Created At          : $Date: 2012/07/19 08:36:02 $
--  Last Revision       : $Revision: 1.1 $
--  Description         :
--
drop table c2cell_closecell;
create table c2cell_closecell
(   cellid char(5),
    lacid char(5),
    closecell char(5),
    closecellkind char(1)
    default '1',
    primary key (cellid,lacid,closecell,closecellkind)
)extent size 128000 next size 128000 lock mode page;
