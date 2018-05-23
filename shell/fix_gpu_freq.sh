#gpu主要有三大厂家，高通的adreno，其余一般用mali
#!/bin/sh

function show_note {
	echo "if you have any questions Please read readme(In the same directory) Priority!!!"
	echo "exit ...."
	# exit 直接退出脚本程序
	exit
}

function enter_diff_dir {
	# -d表示目录是否存在
	if [ -d "/sys/module/pvrsrvkm" ] ; then
		cd /sys/module/pvrsrvkm/drivers/platform:pvrsrvkm/*.gpu/devfreq/*.gpu/
	elif [ -d "/sys/module/mali" ] ; then
		cd /sys/module/mali/drivers/platform:mali/*.gpu/devfreq/*.gpu/
	elif [ -d "/sys/module/mali_kbase" ] ; then
		cd /sys/module/mali_kbase/drivers/platform:mali/*.gpu/devfreq/*.gpu/
	else
		echo "we do not find correct path for GPU info"
		show_note
	fi
}

function cal_gpu_aval_freq {
	# -e 判断文件或者目录是否存在
	if [ -e "available_frequencies" ] ; then
		local freq=`cat available_frequencies`
		# shell脚本默认是全局变量，除非申明为local
		IFS=' '
		#($变量)转换成数组
		arr=($freq)
		# for循环遍历数组
		for x in ${arr[@]} ; do
			echo $x | busybox awk '{printf("%d\t", $1/1000000)}'       
		done
	else
		echo "we do not find available_frequencies node"
		show_note
	fi

}

function get_input_data {
	echo ""
	echo -n "Please select:"
	#read 获取命令行参数，赋予变量choose
	read choose
	#let做数值运算
	let choose=choose*1000000
	local input_aval_flag=0;
	for x in ${arr[@]} ; do
		if [ $x == ${choose} ] ; then
			input_aval_flag=1
			break
		fi
	done
	#等号两边一定需要空格
	if [ ${input_aval_flag} != 1 ] ; then
		echo "you do not input correct freq"
		show_note
	fi
}

function set_gpu_freq {
	# -a 表示&
	if [ -e "min_freq" -a -e "max_freq" ] ; then
		local min=`cat min_freq`
		if [ $choose -gt $min ]; then
			#通过设定最大最小来固定频率
			echo $choose > max_freq
			echo $choose > min_freq
		else
			echo $choose > min_freq
			echo $choose > max_freq
		fi
	else
		echo "we do not find min_freq or max_freq node"
		show_note
	fi
}

function get_cur_freq {
	if [ -e "cur_freq" ] ; then
		echo -e "cur_freq:\c"
		cat cur_freq
	else
		echo "we do not find cur_freq node"
		show_note
	fi
}

enter_diff_dir

cal_gpu_aval_freq

get_input_data

set_gpu_freq

get_cur_freq






