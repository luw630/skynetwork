#!/bin/bash

#g++ ProcessData.cpp -o ProcessData

time_per_day=$[60*60*24]

start_time=0
end_time=0
time_begin=0
time_end=0

if [ $# -ne 2 ]
then
	echo "$0 time"
	exit 1
else
	start_time=`date -d "$1" +%s`
	end_time=`date -d "$2" +%s`
fi

while [ $start_time -le $end_time ]
do
	time_begin=$start_time
  	time=`date -d @$start_time "+%Y-%m-%d"`
	time_end=$[time_begin+time_per_day]
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
			mongoexport -d `echo $time|sed "s/-/_/g"` -c $name -q "{time_stamp:{\$gte:$time_begin,\$lte:$time_end}}" --csv -f $field>"$filename"
		else
			mongoexport -d `echo $time|sed "s/-/_/g"` -c $name -q "{time_stamp:{\$gte:$time_begin,\$lte:$time_end}}" --csv -f $field>"$filename"
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
	tar -zcvf "_$time.tar.gz" $time
	rm -rf $time 
	start_time=$time_end
done
