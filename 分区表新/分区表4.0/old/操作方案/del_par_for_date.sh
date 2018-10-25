date >>/home/informix/frag/del_par_for_date.log 
for i in {1..5} 
do
(time dbaccess $1 <<!
 execute procedure del_par_for_date();
!
)  1>> /home/informix/frag/del_par_for_date.log 2>&1
echo $i
done
date >>/home/informix/frag/del_par_for_date.log

