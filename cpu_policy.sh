#!/usr/bin/bash

function del_file {
	if [ -e $1 ] ; then
		rm $1
	fi
}

function determine_exit {
	if [ ! -e $1 ] ; then
		echo "we do not find correct node: "$1
		show_exit_note
	fi
}

function determine_echo {
	if [ ! -e $1 ] ; then
		echo "we do not find correct node: "$1
	else
		local data=`cat $1`
		echo ${data}
	fi
}

function show_policy {
	local temp=`determine_echo ${1}${2}`
	echo ${2} ${temp} | busybox awk '{printf("%20s: %s\n"), $1, $2}'
}

function cpu_policy()
{
	echo "**************************  CPU  *****************************" 
	echo "DVFS parameters:" 
	local i=0
	for i in `ls -d /sys/devices/system/cpu/cpufreq/policy*/interactive/` ; do
		echo ${i} | grep -o -E "policy."
		show_policy ${i} "above_hispeed_delay"
		show_policy ${i} "boost"
		show_policy ${i} "boostpulse_duration"
		show_policy ${i} "go_hispeed_load"
		show_policy ${i} "hispeed_freq"
		show_policy ${i} "io_is_busy"
		show_policy ${i} "min_sample_time"
		show_policy ${i} "target_loads"
		show_policy ${i} "timer_rate"
		show_policy ${i} "timer_slack"
		show_policy ${i} "above_hispeed_delay" 
		echo ""
	done
}

cpu_policy