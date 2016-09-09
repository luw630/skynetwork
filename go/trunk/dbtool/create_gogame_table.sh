#!/bin/bash
source gogamedb.env

IN_FILE=create_gogame.sql
OUT_FILE=/tmp/create_gogame.sql.outs
echo -n "start "
for dbname in $DBNAMES; do
	echo -n "do $dbname task "
	mysql -h$DBIP -u$DBUSER -p$DBPASS -e "set names utf8;"
	cat $IN_FILE|sed "s/\#DB\#/$dbname/g" >$OUT_FILE
	mysql -h$DBIP -u$DBUSER -p$DBPASS -e "source $OUT_FILE;"
	echo -n "do $dbname success "
done
echo -n "end"