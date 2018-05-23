#该基本基于CPU最多分为两个cluster，其中cpu0属于cluster1，cpu4属于cluster2
#!/bin/sh

function show_exit_note {
	echo "if you have any questions Please read readme(In the same directory) Priority!!!"
	echo "exit ...."
	exit
}

function enter_cpu_dir {
	#基于arm架构的一般都在该目录下
	if [ -d "/sys/devices/system/cpu/" ] ; then
		cd /sys/devices/system/cpu/
	else
		echo "we do not find correct path for CPU info"
		show_exit_note
	fi
}

function get_aval_freq {
	if [ -e "$1" ] ; then
		local cpu_freq=`cat $1`
		#对于for循环中使用的x请优先申明为local，否则容易导致全局变量重名
		local x=0
		if [ "$2" == "cpu0" ] ; then
			cpu0_freq_arry=($cpu_freq)
			for x in ${cpu0_freq_arry[@]} ; do
				echo $x | busybox awk '{printf("%d\t", $1/1000)}'
			done
		elif [ "$2" == "cpu4" ] ; then
			cpu4_freq_arry=($cpu_freq)
			for x in ${cpu4_freq_arry[@]} ; do
				echo $x | busybox awk '{printf("%d\t", $1/1000)}'
			done
		fi
		echo ""
	else
		echo "we do not find correct node: "$1
		show_exit_note
	fi
}

function determine_exit {
	if [ ! -e $1 ] ; then
		echo "we do not find correct node: "$1
		show_exit_note
	fi
}

function determine_correct {
	local flag=0
	
	# $2是传入的数组
	local arry=$2
	for x in ${arry[*]} ; do
		if [ $1 == ${x} ] ; then
			flag=1
			break;
		fi
	done
	# echo输出流作为函数的返回值
	echo $flag
}

function get_input_data {
	local cpu0_flag=0
	local cpu4_flag=0
	if [ "$2" == "cpu0" ] ; then
		# 传入数组作为参数，直接传入数组名将只能获取第一个参数
		#··执行函数并获取输出流，作为返回值
		cpu0_flag=`determine_correct $1 "${cpu0_freq_arry[*]}"`
		if [ $cpu0_flag != 1 ] ; then
			echo "you do not input correct freq"
			show_exit_note
		fi
	elif [ "$2" == "cpu4" ] ; then
		cpu4_flag=`determine_correct $1 "${cpu4_freq_arry[*]}"`
		if [ $cpu4_flag != 1 ] ; then
			echo "you do not input correct freq"
			show_exit_note
		fi
	fi
}

function set_fix_freq {
	local module0_freq=0
	get_aval_freq ${1}"/cpufreq/scaling_available_frequencies" ${1}
	determine_exit ${1}"/cpufreq/scaling_governor"
	
	#切换策略为userspace
	echo userspace >${1}"/cpufreq/scaling_governor"
	
	echo -n "Please select freq:"
	read module0_freq
	# 进行数值运算
	let module0_freq=module0_freq*1000
	get_input_data $module0_freq ${1}
	
	determine_exit ${1}"/cpufreq/scaling_setspeed"
	echo $module0_freq > ${1}"/cpufreq/scaling_setspeed"
	
	determine_exit ${1}"/cpufreq/scaling_cur_freq"
	echo -e ${1}"_cur_freq: \c"
	cat ${1}"/cpufreq/scaling_cur_freq"
}
function find_cpu_core {
	if [ -d "cpu0" ] ; then
		# ls -d表示目录
		# cpu[]后面匹配的是可选项
		local cpu_core=`ls -d cpu[0,1,2,3,4,5,6,7]`	
		cpu_core_arr=($cpu_core)
		local x=0
		for x in ${cpu_core_arr[@]} ; do
			if [ "$x" == "cpu0" ] ; then
				echo "little core:"
				set_fix_freq ${x}
			elif [ "$x" == "cpu4" ] ; then
				echo "big core:"
				set_fix_freq ${x}
			fi
		done
	else
		echo "we do not find correct path for CPU info"
		show_exit_note
	fi
}

enter_cpu_dir

find_cpu_core


