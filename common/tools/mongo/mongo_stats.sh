#!/bin/bash

#g++ ProcessData.cpp -o ProcessData

time_per_day=$[60*60*24]

if [ $# -gt 2 ]
then
	echo "..."
	exit 1
elif [ $# -eq 0 ]
then
	time_end=`date -d "$time" +%s`
	time_begin=$[time_end-time_per_day]
	time=`date -d @$time_begin '+%Y-%m-%d'`
elif [ $# -eq 1 ]
then
	time=$1
	time_begin=`date -d "$time" +%s`
	time_end=$[time_begin+time_per_day]
elif [ $# -eq 2 ]
then
	time=$1
	time_begin=`date -d "$1" +%s`
	time_end=`date -d "$2" +%s`
fi

mkdir $time
while read line
do
	name=`echo $line|awk '{print $1}'`
	field=`echo $line|awk '{print $2}'`
	filename="./$time/$name-$time.csv"
	touch "$filename"
	echo "exporting collection: $name, fields: $field"
	if [ "money_log" = "$name" ]
	then
		mongoexport -d test -c $name -q "{time_stamp:{\$gte:$time_begin,\$lte:$time_end},is_robot:1}" --csv -f $field>"$filename"
	else
		mongoexport -d test -c $name -q "{time_stamp:{\$gte:$time_begin,\$lte:$time_end}}" --csv -f $field>"$filename"
	fi
	echo "done."

	count=`echo $line|awk '{print $3}'`
	types=`echo $line|awk '{print $4}'`
	for((i=1;i<=$count;i++))
	do
		type=`echo $types|awk -F',' '{print $'$i'}'`
		./ProcessData $time $name $type
	done
	rm $filename
done<collection_stats

tar -zcvf "$time.tar.gz" $time
rm -rf $time 
