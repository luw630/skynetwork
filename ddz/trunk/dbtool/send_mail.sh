#!/bin/bash
source texasgamedb.env
echo -n "start "
for dbname in $DBNAMES; do
    echo -n "do $dbname task "
    for line in `cat db_mails`
    do
        rid=`echo $line|awk -F"T" '{print $1}'`
        create_time=`echo $line|awk -F"T" '{print $2}'`
        content=`echo $line|awk -F"T" '{print $3}'`
        mysql -h$DBIP -u$DBUSER -p$DBPASS $dbname -e "insert into role_mailinfo (rid, create_time, content) values($rid, $create_time, '$content')"
    done
    echo -n "do $dbname success "
done
echo -n "end"
