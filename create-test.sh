#!/bin/bash

testdir="test"
year_str=2015

for month in `seq 1 12`; do
	mon_str=$month
	if [ $month -lt 10 ]; then
		mon_str="0$mon_str"
	fi

	for day in `seq 1 28`; do
		day_str=$day

		if [ $day -lt 10 ]; then
			day_str="0$day_str"
		fi

		mkdir -p $testdir/$year_str-$mon_str-$day_str

	done
done
