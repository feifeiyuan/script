#!bin/bash
#接收命令行的默认参数
ddr_times=$1
counts=0

function show_exit_note {
	echo "if you have any questions Please read readme(In the same directory) Priority!!!"
	echo "exit ...."
	exit	
}

#设置默认值
function set_default_times {
	if [ "${ddr_times}" = "" -o "${ddr_times}" = "0" ] ; then
		ddr_times=500
	fi
}

#判断文件是否存在
function determine_node_exist {
	if [ ! -e "$1" ] ; then
		echo "we do not find node: ""$1"
		show_exit_note
	fi
}

#对生成的dic的打印输出
function print_freq_table {
	#遍历dic
	for key in ${!freq_table[@]}; do
		echo $key" "${freq_table[$key]}
	done
}

function get_ddr_freq_aval {
	determine_node_exist "node_freq_table"
	ddr_freq=(`cat node_freq_table`)
	local x=0
	for x in ${ddr_freq[@]}
	do	
		#获取有效的dic table，-z是判断字符串的长度是否为0
		if [ -z "${freq_table[$x]}" -a "$x" != "0" ] ; then 
			freq_table[$x]=0
		fi
	done
	
	#print_freq_table
}

function cal_loading {
	local cur_freq=0
	local key=0
	determine_node_exist "node_timer"
	local timer=`cat node_timer`
	while [ $counts -lt $ddr_times ] ; do
		let counts++
		determine_node_exist "node_cur_freq"
		cur_freq=`cat node_cur_freq`
		for key in ${!freq_table[@]} ; do
			if [ $key == $cur_freq ] ; then
				let freq_table[$key]++
			fi
		done
		sleep 0.0027
	done
	
	echo "timer = ${timer}, counter = ${counts}, "
	#print_freq_table
}

function show_loading {
	local key=0;
	local per_key=0;
	for key in ${!freq_table[@]} ; do
		echo -n $key": "${freq_table[$key]}"        ";
	done
	
	echo "\n"
	for per_key in ${!freq_table[@]} ; do
		echo $per_key ${freq_table[$per_key]} ${counts} | busybox awk '{printf("%d = %.2f%%  ", $1, $2*100/$3)}'
	done
	echo ""
}

function show_bm {
	local key=0
	echo "unit: B/10ms"
	echo -n "theory_bw = "
	determine_node_exist "node_overflow"
	determine_node_exist "node_underflow"
	for key in ${!freq_table[@]} ; do
		echo ${key} | busybox awk '{printf("%d ",$1*8000)}'
	done
	echo ""
	local overflow=`cat node_overflow`
	local underflow=`cat node_underflow`
	echo -e "overflow  = $overflow"
	echo -n "underflow = $underflow\n"
}

set_default_times

get_ddr_freq_aval

cal_loading

show_loading

show_bm