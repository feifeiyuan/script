#gpu��Ҫ�����󳧼ң���ͨ��adreno������һ����mali
#!/bin/sh

function show_note {
	echo "if you have any questions Please read readme(In the same directory) Priority!!!"
	echo "exit ...."
	# exit ֱ���˳��ű�����
	exit
}

function enter_diff_dir {
	# -d��ʾĿ¼�Ƿ����
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
	# -e �ж��ļ�����Ŀ¼�Ƿ����
	if [ -e "available_frequencies" ] ; then
		local freq=`cat available_frequencies`
		# shell�ű�Ĭ����ȫ�ֱ�������������Ϊlocal
		IFS=' '
		#($����)ת��������
		arr=($freq)
		# forѭ����������
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
	#read ��ȡ�����в������������choose
	read choose
	#let����ֵ����
	let choose=choose*1000000
	local input_aval_flag=0;
	for x in ${arr[@]} ; do
		if [ $x == ${choose} ] ; then
			input_aval_flag=1
			break
		fi
	done
	#�Ⱥ�����һ����Ҫ�ո�
	if [ ${input_aval_flag} != 1 ] ; then
		echo "you do not input correct freq"
		show_note
	fi
}

function set_gpu_freq {
	# -a ��ʾ&
	if [ -e "min_freq" -a -e "max_freq" ] ; then
		local min=`cat min_freq`
		if [ $choose -gt $min ]; then
			#ͨ���趨�����С���̶�Ƶ��
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






