#!/bin/bash

i=1
while [ $i -le 513 ]
do
    idx=`printf %03d $i`
    #echo $idx >> tmp
    mysql -uximi -pximi auth -s -e "select * from t_auth_client_info_$idx"|sed "s/\t/,/g" >> tmp
    echo -n "."
    i=$[$i+1]
done
cat tmp > db_acc.csv
rm tmp
echo "db done."
