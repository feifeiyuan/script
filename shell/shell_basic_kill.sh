#!usr/bin/bash

# 截取字符串
str="you)can/get% a better life"
echo ${str}
str_get=${str:2:10}
echo $str_get

# 定义\遍历数组\获取数组的长度
echo "this is the first arry"
arr=(1 2 3 4 5)
for x in ${arr[@]}
do
	echo ${x}
done

len=${#arr[*]}
echo "the len of arr:"$len

echo "this is another arry"
for j in 6 7 8 9
do
	echo ${j}
done
# 将字符串转换成数组
str2="y o u a r y"
str2_arr=(${str2})
echo "the arr len:"${#str2_arr[*]}

# 定义和使用函数,传入参数，函数名称和｛之间一定需要空格
function my_func {
	echo "this is the first argu"
	echo ${1}
}

my_func "honey"

#将执行命令的结果赋值给某局部变量
#shell 未申明本地变量均为全局变量
local value=`cat /sys/etc/power_total`

# if条件语句
arg1="you"
if [ "${arg1}" = "you love me" ] ; then
	echo "you will not leave me"
elif [ "${arg1}" = "you" ] ; then
	echo "what you love is youself"
else
	echo "by youself"
fi

# 数值计算
local i=0
let i++
echo "i is "${i}
