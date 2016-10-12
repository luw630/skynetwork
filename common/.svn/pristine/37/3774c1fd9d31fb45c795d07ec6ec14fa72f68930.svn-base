#!/bin/bash


time_per_day=$[60*60*24]
if [ $# -eq 0 ]
then
	echo "Usage: $0 uid [time]|[time_begin][time_end]"
	exit 0
elif [ $# -gt 3 ]
then
	echo "Usage: $0 uid [time]|[time_begin][time_end]"
	exit 0
elif [ $# -eq 1 ]
then
	time_begin=`date -d "$time" +%s`
	time_end=$[time_begin+time_per_day]
	time=`date -d @$time_begin '+%Y-%m-%d'`
elif [ $# -eq 2 ]
then
	time_begin=`date -d "$2" +%s`
	time_end=$[time_begin+time_per_day]
	time=$2
	echo "$time_begin"
	echo "$time_end"

elif [ $# -eq 3 ]
then
	time_begin=`date -d "$2" +%s`
	time_end=`date -d "$3" +%s`
	time=$2
fi

uid=$1

mkdir $uid
#exporting
while read line
do
	name=`echo $line|awk '{print $1}'`
	field=`echo $line|awk '{print $2}'`
	filename="./$uid/$name-$uid.csv"
	touch "$filename"
	echo "exporting collection: $name, fields: $field"
	mongoexport -d test -c $name -q "{uid:$uid, time_stamp:{\$gte:$time_begin,\$lte:$time_end}}" --csv -f $field>"$filename"
	echo "done."
	#rm $filename
done<collection_query

tar zcvf $uid.tar.gz $uid
rm -rf $uid
