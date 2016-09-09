#!/bin/bash
source texasgamedb.env

IN_FILE=altertable.sql
OUT_FILE=/tmp/altertable.sql.out
cat $IN_FILE|sed "s/\#DB\#/$DBNAME/g" >$OUT_FILE
mysql -h$DBIP -p$DBPORT -u$DBUSER -p$DBPASS -e "source $OUT_FILE;"
