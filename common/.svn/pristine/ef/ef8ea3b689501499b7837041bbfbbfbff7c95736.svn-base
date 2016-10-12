#!/bin/bash

i=1
while [ $i -le 512 ]
do
    idx=`printf %03d $i`
    mysql -uximi -pximi texas -s -e "select * from t_acc_order_info_$idx"|sed "s/\t/,/g" >> tmp
    echo -n "."
    i=$[$i+1]
done
cat tmp > db_shop.csv
rm tmp
echo "db done."
