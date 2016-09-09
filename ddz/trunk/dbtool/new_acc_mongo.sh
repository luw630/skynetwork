#!/bin/bash

g++ hash.cpp -o hash

echo "mongo"
pre_uid=999999999
cat reg_map.csv|sed "s/,/\t/g"|sed "s/\"//g" > mongo_acc
while read line
do
    name=`echo $line|awk '{print $1}'`
    uid=`echo $line|awk '{print $2}'`
    dev_id=`echo $line|awk '{print $3}'`
    ret=`./hash $name`
    idx=`printf %03d $ret`
    #skip field line
    if [ $name != "new_id" ]
    then
        if  [[ $dev_id =~ 'win|' ]]
        then
            echo "invalid dev_id $dev_id"
        elif [ $uid -ne 0 ] && [ $pre_uid -gt $uid ]
        then
            mysql -uximi -pximi auth -e "insert into t_account_info_$idx (account_name, uid) values('$name', $uid)"
            if [ $? -eq 0 ]
            then
                pre_uid=$uid
            fi
        fi
    fi
done<mongo_acc
rm mongo_acc
echo "mongo done."
