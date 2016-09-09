#!/bin/bash


time_per_day=$[60*60*24]

if [ $# -ne 2 ]
then
	echo "$0 time"
	exit 1
else
	time=$2
	time_begin=`date -d "$time" +%s`
	time_end=$[time_begin+time_per_day]
fi

uid=$1

mkdir $uid
while read line
do
	name=`echo $line|awk '{print $1}'`
	field=`echo $line|awk '{print $2}'`
	filename="./$uid/$name-$uid.csv"
	touch "$filename"
	echo "exporting collection: $name, fields: $field"
	mongoexport -d "texas_$time" -c $name -q "{uid:$uid, time_stamp:{\$gte:$time_begin,\$lte:$time_end}}" --csv -f $field>"$filename"
	echo "done."
done<collection_query

tar zcvf "_$uid.tar.gz" $uid
rm -rf $uid
