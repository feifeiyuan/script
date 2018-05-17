 #!/bin/sh
test_time=$1
dis_all=$2

function close_selinux()
{
#关闭selinux权限设置
	setenforce 0
}
function set_test_time()
{
	if [ "$test_time" = "" -o "$test_time" = "0" ] ; then 
		test_time=4
	fi
}

function set_dis_whole()
{
	if [ "$dis_all" = "" -o "$dis_all" != "1" ] ; then 
		dis_all=0
	fi
}

function show_exit_note {
	echo "if you have any questions Please read readme(In the same directory) Priority!!!"
	echo "exit ...."
	exit
}

function determine_exit {
	if [ ! -e $1 ] ; then
		echo "we do not find correct node: "$1
		show_exit_note
	fi
}

function close_thermal_IPA()
{
#kernel thermal 中的IPA会动态的调节CPU、GPU的电压和频率，可能会导致带宽变化
#所以需要关闭
#thm_enable 表示的是
#mode 表示的是
	local zone_num=0
	while [ -d "/sys/devices/virtual/thermal/thermal_zone"${zone_num} ] ; do
		determine_exit "/sys/devices/virtual/thermal/thermal_zone"${zone_num}"/type"
		if [ "`cat "/sys/devices/virtual/thermal/thermal_zone"${zone_num}"/type" | grep "cpu"`" != "" \
		-o "`cat "/sys/devices/virtual/thermal/thermal_zone"${zone_num}"/type" | grep "bia"`" != "" ] ; then
			determine_exit "/sys/devices/virtual/thermal/thermal_zone"${zone_num}"/thm_enable"
			echo 0 > "/sys/devices/virtual/thermal/thermal_zone"${zone_num}"/thm_enable"
			determine_exit "/sys/devices/virtual/thermal/thermal_zone"${zone_num}"/mode"
			echo disabled > "/sys/devices/virtual/thermal/thermal_zone"${zone_num}"/mode"
			break
		fi
		let zone_num++
	done
}

function set_ddr_mode {
	set_test_time
#设置了/sys/bus/platform/devices/*.ptm/misc/sprd_ptm/mode为legacy模式之后
#在mnt/obb下面会产生对应的log文件，解析log文件使用的是C程序
	if [ -e "/mnt/obb/axi_per_log" ] ; then
		#清空原有的log文件
		rm /mnt/obb/axi_per_log
	fi
	cd /sys/bus/platform/devices/*.ptm/misc/sprd_ptm/
	#这里为什么要写一个循环呢？
	#第一次开机时mode为initial，直接更改为legacy就会动态生成bandwidth文件(类似第一次打开了一个开关)，后续直接将监控关掉
	if [ ! -e "bandwidth" ] ; then
		echo legacy > mode
	fi
	#设置窗口大小和使能带宽监控
	echo 10 > bandwidth
	sleep "${test_time}"
	#关闭监控
	echo 0 > bandwidth
}

function clear_evirment {
	local FIR="/mnt/obb/result/"
	if [ -e "${FIR}" ] ; then
		rm -rf ${FIR}
	fi
	mkdir ${FIR}
}

function log_to_csv()
{
	cd
	clear_evirment
	set_dis_whole
	#获取board信息
	local board=$(getprop | grep "ro.build.product" | grep -o -E ': \[.+]' | sed 's/\: \[//g' | sed 's/]//g')
	if [ -e "/mnt/obb/axi_per_log" -a "/mnt/obb/ddr_bm_log" ] ; then
		chmod 777 /mnt/obb -R
		#解析生成的log文件
		./mnt/obb/ddr_bm_log /mnt/obb/axi_per_log ${dis_all} > /mnt/obb/result/ddr_bm_${board}.csv
	fi
}

close_thermal_IPA
set_ddr_mode
log_to_csv




















   
