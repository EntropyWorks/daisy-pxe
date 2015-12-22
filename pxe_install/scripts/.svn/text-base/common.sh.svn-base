#!/bin/bash

#######################
# 记录日志到/var/log/pxe_install.log
# $1:要记录的日志
# $2:如果值为console，那么同时又在屏幕上打印此记录
# 这个函数的功能：记录一条检查日志，并在这个日志前面加上记录的时间
#######################
function pxelog
{
    local LOGFILE=/var/log/pxe_install.log
    
    if [ ! -f $LOGFILE ]; then
        touch $LOGFILE
    fi
    #记录日志
    LANG=en_US.ISO8859-1
    echo -n `date '+%b %d %T'` >> $LOGFILE
    echo -e " $1" >> $LOGFILE
    [[ $2 = "console" ]] && echo -e $1
    return 0
}

#######################
#从json配置文件读取参数
#######################
function get_config
{
    local file=$1
    local key=$2

    [ ! -e $file ] && { pxelog "file ${file} not exit!!" "console"; return; }
    config_answer=$(jq ".$key" $file | sed "s/\"//g" )
    pxelog "${key}=$config_answer"
    [[ "null" == ${config_answer} ]] && config_answer=""
    #config_answer=$(echo $config_answer | sed "s/\"//g")
    #忽略井号开头的注释行以及空行之后再grep过滤"key"所在的行
    #local line=`sed '/^[[:space:]]*#/d' $file | sed /^[[:space:]]*$/d | grep -w "$key"| grep "$key[[:space:]]*="`
    #if [ -z "$line" ]; then
    #    config_answer=""
    #else
        #将第一个=号替换为空格，再删除第一个单词得到value
    #    config_answer=`echo $line | sed 's/=/ /' | sed -e 's/^\w*\ *//'`
    #fi
    
}

#######################
#设置参数到conf配置文件
#######################
function set_config
{
    local file=$1
    local key=$2
    local value=$3

    [ ! -e $file ] && return

    #echo update key $key to value $value in file $file ...
    local exist=`grep "^[[:space:]]*[^#]" $file | grep -c "$key[[:space:]]*=[[:space:]]*.*"`
    #注意：如果某行是注释，开头第一个字符必须是#号!!!
    local comment=`grep -c "^[[:space:]]*#[[:space:]]*$key[[:space:]]*=[[:space:]]*.*"  $file`
    
    if [[ $value == "#" ]];then
        if [ $exist -gt 0 ];then
            sed  -i "/^[^#]/s/$key[[:space:]]*=/\#$key=/" $file       
        fi
        return
    fi

    if [ $exist -gt 0 ];then
        #如果已经存在未注释的有效配置行，直接更新value
        sed  -i "/^[^#]/s#$key[[:space:]]*=.*#$key=$value#" $file
        
    elif [ $comment -gt 0 ];then
        #如果存在已经注释掉的对应配置行，则去掉注释，更新value
        sed -i "s@^[[:space:]]*#[[:space:]]*$key[[:space:]]*=[[:space:]]*.*@$key=$value@" $file
    else
        #否则在末尾追加有效配置行
        #local timestamp=`env LANG=en_US.UTF-8 date`
        #local writer=`basename $0`
        echo "" >> $file
        #echo "# added by $writer at $timestamp" >> $file
        echo "$key=$value" >> $file
    fi
}

function convert_mac_to_ip
{
    local dhcp_mac=$1
    local lease_file=/var/lib/dhcpd/dhcpd.leases
    local line
    local ip_addr
    local log_postfix
    install_log=""
    
    #获取lease文件中最后出现这个mac地址的行号
    line=`grep -n -wi "${dhcp_mac}" ${lease_file} |tail -n 1 |awk -F':' '{print $1}'`
    
    [[ ${line} == "" ]] && { pxelog "pxe server did not assign an ip to this target machine";return 1; }
    
    #找到这个行号之前最后一次出现的ip
    ip_addr=`head -n ${line} ${lease_file} | grep -o '\<[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\>' |tail -n 1`
    
    #用ip地址得到log日志文件名
    install_log=/var/log/${ip_addr}
    log_postfix=".log"
    install_log=${install_log}${log_postfix}
    pxelog "dhcp_mac=${dhcp_mac} MACADDR=${MACADDR} install_log=${install_log}!"
    
    return 0
}

function clean_os_files
{
    local MACADDR=$1
    #删除/linuxinstall、/home/install_share、/tftpboot下和目标机相关的东西
    rm /linuxinstall/${MACADDR} -rf
    rm /home/install_share/${MACADDR} -rf
    rm /tftpboot/${MACADDR} -rf
    rm /tftpboot/pxelinux.cfg/01-${MACADDR} -rf
}

function clean_all_os_files
{
    #删除/linuxinstall、/home/install_share、/tftpboot下所有目标机相关的东西
    rm /linuxinstall/* -rf
    rm /home/install_share/* -rf
    
    mkdir -p /tftpboot_bak
    cp -rf /tftpboot/* /tftpboot_bak/
    rm -rf /tftpboot/*
    cp /tftpboot_bak/initrd.img /tftpboot/
    cp /tftpboot_bak/pxelinux.0 /tftpboot/
    cp /tftpboot_bak/vmlinuz /tftpboot/
    cp -rf /tftpboot_bak/pxelinux.cfg /tftpboot/
    rm -rf /tftpboot/pxelinux.cfg/01-*
    rm -rf /tftpboot_bak    
}

function clean_os_table
{
    local MACADDR=$1
    local OS_TABLE=$2
    
    if [ -f ${OS_TABLE} ]; then
        [[ `cat ${OS_TABLE} |grep "${MACADDR}"` != "" ]] &&  sed -i "/${MACADDR}/d" ${OS_TABLE}
    fi    
}

