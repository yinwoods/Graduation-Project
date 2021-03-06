#!/bin/bash

#预处理
function preprocess()
{

    #清理内核信息
    echo "yinhua" | sudo -S dmesg --clear

    #清理屏幕信息
    clear

    #进入毕设代码目录
    cd ~/bs/exec
}

#卸载驱动设备函数
function unmnt()
{
    #设备名
    devices=devices

    #驱动名
    drivers=drivers

    #将lsmod信息读入modInfo
    lsmod > tmp
    modInfo=$(cat tmp)
    rm tmp

    result=$(echo ${modInfo} | grep ${devices})
    #如果当前挂载了设备，卸载
    if [ "$result" != "" ]; then
    	echo '正在卸载devices'
        sudo rmmod ${devices}
    fi

    result=$(echo ${modInfo} | grep ${drivers})
    #如果当前挂载了驱动，卸载
    if [ "$result" != "" ]; then
    	echo '正在卸载drivers'
        sudo rmmod ${drivers}
    fi
}

#挂载驱动设备函数
function mnt()
{
    #清理中间文件
    make clean > /dev/null 2>&1

    #编译
    make -s > /dev/null 2>&1

    echo "共有${device_num}个设备"
    echo "状态位依次为${global_status}"

    #挂载驱动、设备
    sudo insmod drivers.ko
    sudo insmod devices.ko device_num=${device_num} global_status=${global_status}

    #清理中间文件
    make clean > /dev/null 2>&1
}

#控制逻辑
function controlMod()
{
	OLD_IFS="$IFS"
	IFS=','
	arr=(${global_status})
	IFS="$OLD_IFS"

	#依次读取设备对应字符文件中的内容
	for((i=0; i<${device_num}; i++)); do
	    echo "设备${i}中的内容为："
	    echo '---------------------------------'

	    lineNum=0
	    cat /dev/memdev$i | while read line; do
	        #对设备类型进行判断
	        if [ $lineNum = 1 ]; then
	            status=${line##*：}
	            if [ $status = 0 ]; then
	                echo '该设备为：主型'
	            elif [ $status = 1 ]; then
	                echo '该设备为：热型'
	            elif [ $status = 2 ]; then
	                echo '该设备为：冷型'
	            elif [ $status = 3 ]; then
	            	echo '该设备为：损坏'
	            fi
	        else
	            echo ${line}
	        fi
	        let lineNum=$[lineNum+1]
	    done
	    echo -e "\n\n\n"
	done
}

function main()
{
	#预处理
	preprocess;

	#卸载驱动设备
	unmnt;

	cpuUsage=$(echo $$)

	echo "进程号：$cpuUsage"

	
	if [[ $1 = '' ]]; then
		echo -n '请输入创建设备个数:'
		read device_num
	else
		device_num=$1	
	fi
	

	if [[ $2 = '' ]]; then
		echo -n '请依次输入各个设备的状态位:(以逗号隔开)'
		read global_status
	else
		global_status=$2
	fi

	#挂载驱动设备
	mnt;

	#控制逻辑
	controlMod;

	#卸载
	unmnt;
	
}

main $1 $2;
