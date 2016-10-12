#!/bin/bash

if [ $# -eq 1 ]
then
	mongoexport -d texas_$1 -c turntable -f time,time_stamp,uid,lottery_id,award_type,award_id,award_num,total_limit,single_limit --csv > turn_$1.csv
else
	echo "$0 time"
fi
