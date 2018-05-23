#!/usr/bin/bash

result_dir="/sdcard/interrupts/"
function show_exit_note ()
{
	echo "if you have any questions Please read readme(In the same directory) Priority!!!"
	echo "exit ...."
	exit
}

function determine_exit () 
{
	if [ ! -e $1 ] ; then
		echo "we do not find correct node: "$1
		show_exit_note
	fi
}

function set_test_time ()
{
	test_time=$1
	if [ "$test_time" = "" -o "$test_time" = "0" ] ; then
		test_time=3
	fi
}

function set_display()
{
	zero_dis=$2
	if [ "$zero_dis" = "" -o "$zero_dis" = "0" ] ; then
		zero_dis=0
	else
		zero_dis=1
	fi
}

function clear_eviroment {
	if [ -e ${result_dir} ] ; then
		rm -rf ${result_dir}
	fi
	mkdir ${result_dir}
}


function deal_data ()
{
	local data_temp1=${result_dir}$2"_data_temp1.txt"
	cp ${1} ${data_temp1}
	local data_temp2=${result_dir}$2"_data_temp2.txt"
	local first_cpu=`sed -n '1p' ${data_temp1}`
	#去掉了文件的首行
	sed '1d' ${data_temp1} > ${data_temp2}
	first_cpu_arr=(${first_cpu})
	local cpu=0
	for cpu in ${first_cpu_arr[@]} ;  do
		busybox awk '{printf("%s\t %s\n", $1, $2)}' ${data_temp2} > ${result_dir}"interrupts_"$2"_tmp_"${cpu}".txt"
		#删除第二列的数据
		busybox awk '{$2=null;print $0}' ${data_temp2} > ${data_temp1}
		cp ${data_temp1} ${data_temp2}
	done

	for cpu in ${first_cpu_arr[@]} ;  do
		busybox awk 'BEGIN{i=0;k=0;id[]="";num[]="";}
					NR==FNR{
						id[i]=$1;
						num[i]=$2;
						i++;
					}
					NR>FNR{
						printf("%-10s\t%-10s\t",id[k],num[k]);
						for(i=2;i<=NF;i++){
							if(i==NF){
								printf("%-40s\t", $i);
								break;
							}
							printf("%-15s\t", $i);
						}
						printf("\n");
						k++;
					}
		' ${result_dir}"interrupts_"$2"_tmp_"${cpu}".txt" ${data_temp2} >${result_dir}"interrupts_"$2"_"${cpu}".txt"
	done
	rm ${data_temp1} ${data_temp2}
}

function deal_convergress_data ()
{
	busybox awk '{printf("%s\n"),$1}' ${result_dir}"interrupts_start_"${1}".txt" > ${result_dir}"interrupts_start_"${1}"_id.txt"
	cat ${result_dir}"interrupts_start_"${1}".txt" >> ${result_dir}"interrupts_end_"${1}".txt"
	busybox awk 'BEGIN{i=0;j=0;count=0;id[]="";num[]="";request_irq[]="";priority[]="";acpi_sci[]="";dev_name[]="";info_total[]="";}
			NR==FNR{
				count=NR;
			}
			NR>FNR{
				id[i]=$1;
				request_irq[i]=$3;
				priority[i]=$4;
				acpi_sci[i]=$5;
				for(j=6;j<=NF;j++){
					if(j==6){
						dev_name[i]=$j;
					}else{
						dev_name[i]=dev_name[i]$j;
					}
				}
				tag=sprintf("%-10s%-20s%-15s%-15s%-40s",id[i],request_irq[i],priority[i],acpi_sci[i],dev_name[i]);
				if(info_total[tag]){
					num[tag]=num[tag]-$2;
				}else{
					num[tag]=$2;
					info_total[tag]=tag;
				}
				if(num[tag]<0){
					num[tag]*=-1;
				}
				i++;
			}
			END{
				for(i in info_total){
					printf("%-10s%s\n",num[i],info_total[i])
				}
			}' ${result_dir}"interrupts_start_"${1}".txt" ${result_dir}"interrupts_end_"${1}".txt" > ${result_dir}"result_commond_data.txt"
	local line=0
	
	echo ${1} "ID"  "request_irq" "unknown" "acpi_sci" "dev_name" | busybox awk '{printf("%-10s%-10s%-20s%-15s%-15s%-40s\n",$1,$2,$3,$4,$5,$6)}' >> ${result_dir}"result_commond_data_sort.txt"
	for line in `cat ${result_dir}"interrupts_start_"${1}"_id.txt"` ; do
		cat ${result_dir}"result_commond_data.txt" | grep $line >> ${result_dir}"result_commond_data_sort.txt"
	done
	busybox awk '{printf("%-10s\n", $1)}
	' ${result_dir}"result_commond_data_sort.txt" >  ${result_dir}"result_"$1"_data.txt"
}

function look_interrupts ()
{
	local start_data=${result_dir}"interrupts_start.txt"
	local end_data=${result_dir}"interrupts_end.txt"
	clear_eviroment
	set_test_time
	set_display
    
	determine_exit "/proc/interrupts"
	cat proc/interrupts > ${start_data}
	sleep ${test_time}
	determine_exit "/proc/interrupts"
	cat proc/interrupts > ${end_data}
	
	# deal data
	deal_data ${start_data} "start"
	deal_data ${end_data} "end"
	
	local first_start_cpu=`sed -n '1p' ${start_data}`
	local first_end_cpu=`sed -n '1p' ${end_data}`
	first_start_cpu_arr=(${first_start_cpu})
	first_end_cpu_arr=(${first_end_cpu})
	first_commond_cpu_arr=()
	first_convergress_arr=()
	local start_key=0
	local end_key=0
	local commond_key=0
	local convergress_key=0
	local i=0
	for start_key in ${first_start_cpu_arr[@]}; do
		for end_key in ${first_end_cpu_arr[@]} ; do
			if [ "$start_key" = "${end_key}" ]  ; then
				first_commond_cpu_arr[$i]=$start_key
				first_convergress_arr[$i]=$start_key
				let i++
				break
			fi
		done
	done
	
	local flag=0
	for start_key in ${first_start_cpu_arr[@]}; do
		for commond_key in ${first_commond_cpu_arr[@]} ; do
			if [ "$start_key" == "$commond_key" ] ; then
				flag=1
				break
			fi
		done
		if [ "$flag" == "0" ] ; then
			busybox awk 'BEGIN{i=0;num=0;}
					NR==FNR{
						printf("%-10s\t%-10s\t",$1,num);
						for(i=3;i<=NF;i++){
							if(i==NF){
								printf("%-40s\t", $i);
								break;
							}
							printf("%-15s\t", $i);
						}
						printf("\n");
					}' ${result_dir}"interrupts_start_"${start_key}".txt" > ${result_dir}"interrupts_end_"${start_key}".txt"
			first_convergress_arr[$i]=$start_key
			let i++
		fi
		flag=0
	done
	
	i=0
	flag=0
	for end_key in ${first_end_cpu_arr[@]}; do
		for commond_key in ${first_commond_cpu_arr[@]} ; do
			if [ "$end_key" == "$commond_key" ] ; then
				flag=1
				break
			fi
		done
		if [ "$flag" == "0" ] ; then
			busybox awk 'BEGIN{i=0;num=0;}
					NR==FNR{
						printf("%-10s\t%-10s\t",$1,num);
						for(i=3;i<=NF;i++){
							if(i==NF){
								printf("%-40s\t", $i);
								break;
							}
							printf("%-15s\t", $i);
						}
						printf("\n");
					}' ${result_dir}"interrupts_end_"${end_key}".txt" > ${result_dir}"interrupts_start_"${end_key}".txt"
			first_convergress_arr[$i]=$end_key
			let i++
		fi
		flag=0
	done
	
	for convergress_key in ${first_convergress_arr[@]} ; do
		deal_convergress_data ${convergress_key}
		sed -e 's/[^ ]* //' ${result_dir}"result_commond_data_sort.txt" > ${result_dir}"result_commond_data_temp.txt"
		cp ${result_dir}"result_commond_data_temp.txt" ${result_dir}"result_commond_data_sort.txt"
		if [ -e ${result_dir}"result_data.txt" ] ; then
			cp ${result_dir}"result_data.txt" ${result_dir}"result_commond_data_sort.txt" 
		fi
		 
		busybox awk 'BEGIN{i=0;j=0;k=0;count=0;id[]="";num[]=""}
				ARGIND==1{
					count=NR
				}
				ARGIND==2{
					id[i]=$1;
					i++;
				}
				ARGIND==3{
					num[j]=$1;
					j++;
				}
				END{
				for(i=0;i<count;i++){printf("%-10s%s\n",id[i],num[i])}
				printf("count is %d\n",count);
			}' ${result_dir}"result_commond_data_temp.txt" ${result_dir}"result_commond_data_sort.txt" ${result_dir}"result_"${convergress_key}"_data.txt" > ${result_dir}"result_data_only_ahead.txt"
		busybox awk 'BEGIN{i=0;j=0;k=0;count=0;id[]="";num[]="";}
				ARGIND==1{
					id[i]=$1
					num[i]=$2
					i++
				}
				ARGIND==2{
					printf("%-10s\t%-10s\t",id[k],num[k]);
						for(j=2;j<=NF;j++){
							if(j==NF){
								printf("%-40s\t", $j);
								break;
							}
							printf("%-15s\t", $j);
						}
						printf("\n");
					k++;
				}'  ${result_dir}"result_data_only_ahead.txt" ${result_dir}"result_commond_data_sort.txt" > ${result_dir}"result_data.txt"
		rm ${result_dir}"result_commond_data_sort.txt"
	done
	local len=${#first_convergress_arr[@]}
	busybox awk 'BEGIN{i=0;j=0;k=0;n=0;flag=0;count=0;sum[]="";id[]="";num=0}
		ARGIND==1{
			if($1!="ID"){
				for(j=2;j<='$len';j++){
					if($(j)!=0){
						flag=1;
						count+=$(j)
					}
				}
				if(flag==1){
					sum[i]=count
					id[i]=$1
					i++;
				}
				flag=0
				count=0
			}
		}
		END{num=i
			temp_num=0
			temp_id=0
			for(k=1;k<num;k++){
				temp_num=sum[k]
				temp_id=id[k]
				for(n=k;n>0&&temp_num-sum[n-1]<0;n--){
					sum[n]=sum[n-1];
					id[n]=id[n-1];
				}
				sum[n]=temp_num
				id[n]=temp_id
			}
			for(k=num;k>=0;k--){
				printf("%-10s\n",id[k]);
			}
	}' ${result_dir}result_data.txt > ${result_dir}result_data_no_zero.txt
	
	if [ "$zero_dis" == "1" ] ; then
		busybox awk 'BEGIN{i=0;j=0;flag=0}
			ARGIND==1{
				for(j=1;j<='$len';j++){
					if($(j+1)!=0){
						flag=1;
					}
				}
				if(flag==0){
					printf("%-10s\n",$1);
				}
				flag=0
			
		}' ${result_dir}result_data.txt > ${result_dir}result_data_zero.txt
	fi
	
	sed -n '1p' ${result_dir}result_data.txt >> ${result_dir}"interrupts_result.txt"
	local line=0
	for line in `cat ${result_dir}result_data_no_zero.txt` ; do
		cat ${result_dir}result_data.txt | grep $line >> ${result_dir}"interrupts_result.txt"
	done
	
	if [ "$zero_dis" == "1" ] ; then
		for line in `cat ${result_dir}result_data_zero.txt` ; do
			cat ${result_dir}result_data.txt | grep $line >> ${result_dir}"interrupts_result.txt"
		done
	fi
	cp ${result_dir}interrupts_result.txt "/sdcard/interrupts_result.txt"
}

look_interrupts




