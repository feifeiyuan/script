#!/bin/sh

function show_note {
	echo "if you have any questions Please read readme(In the same directory) Priority!!!"
	echo "exit ...."
	# exit 直接退出脚本程序
	exit
}

function enter_diff_dir {
	# -d表示目录是否存在
	if [ -d "dic1" ] ; then
		cd /dic1/drivers/*.file1/devfreq/*.file1/
	elif [ -d "dic2" ] ; then
		cd /dic2/drivers/platform:mali/*.file2/devfreq/*.file2/
	elif [ -d "dic3" ] ; then
		cd /dic3/drivers/platform:mali/*.file3/devfreq/*.file3/
	else
		echo "we do not find correct path for *** info"
		show_note
	fi
}

function cal_aval_data {
	# -e 判断文件或者目录是否存在
	if [ -e "node1" ] ; then
		# shell脚本默认是全局变量，除非申明为local
		local data=`cat node1`
		IFS=' '
		#($变量)转换成数组
		arr=($data)
		# for循环遍历数组
		for x in ${arr[@]} ; do
			echo $x | busybox awk '{printf("%d\t", $1/1000000)}'       
		done
	else
		echo "we do not find node1 node"
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
	if [ ${input_aval_flag} != 1 ] ; then
		echo "you do not input correct data"
		show_note
	fi
}

function set_correct_data {
	# -a 表示&
	if [ -e "min" -a -e "max" ] ; then
		local min_data=`cat min`
		if [ $choose -gt $min_data ]; then
			echo $choose > max
			echo $choose > min
		else
			echo $choose > min
			echo $choose > max
		fi
	else
		echo "we do not find min or max node"
		show_note
	fi
}

function get_cur_data {
	if [ -e "node2" ] ; then
		echo -e "node2:\c"
		cat node2
	else
		echo "we do not find node2 node"
		show_note
	fi
}

enter_diff_dir

cal_aval_data

get_input_data

set_correct_data

get_cur_data






