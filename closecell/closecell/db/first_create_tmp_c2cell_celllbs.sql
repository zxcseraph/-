--
--  Copyright(C) 2000 EASTCOM-BUPT Inc.
--
--  Created By          : $Author: scf $
--  Created At          : $Date: 2012/07/19 08:36:04 $
--  Last Revision       : $Revision: 1.1 $
--  Description         :
--
create table tmp_c2cell_celllbs
(  cellid char(5),
   celllac char(5),
   cellkind  char(1),
   Longitude1 char(5),
   Longitude2 char(2),
   Longitude3 char(5),
   Latitude1 char(2),
   Latitude2 char(2),
   Latitude3 char(5),
   Primary key (cellid,celllac)
);

