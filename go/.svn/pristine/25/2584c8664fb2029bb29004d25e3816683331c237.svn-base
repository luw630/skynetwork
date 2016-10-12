#!/bin/bash
source db.env

TABNUM=513

i=1
while [ $i -le $TABNUM ]
do
	if [ $i -lt 10 ]
	then
		tabid="00"$i
	elif [ $i -lt 100 ]
	then
		tabid="0"$i
	else
		tabid=$i
	fi


	mysql -h$DBIP -u$DBUSER -p$DBPASS -e "use auth;delete from t_account_info_$tabid;"

	i=$[$i+1]

	echo -n "."
done
