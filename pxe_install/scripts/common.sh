#!/bin/bash

#######################
# ��¼��־��/var/log/pxe_install.log
# $1:Ҫ��¼����־
# $2:���ֵΪconsole����ôͬʱ������Ļ�ϴ�ӡ�˼�¼
# ��������Ĺ��ܣ���¼һ�������־�����������־ǰ����ϼ�¼��ʱ��
#######################
function pxelog
{
    local LOGFILE=/var/log/pxe_install.log
    
    if [ ! -f $LOGFILE ]; then
        touch $LOGFILE
    fi
    #��¼��־
    LANG=en_US.ISO8859-1
    echo -n `date '+%b %d %T'` >> $LOGFILE
    echo -e " $1" >> $LOGFILE
    [[ $2 = "console" ]] && echo -e $1
    return 0
}

#######################
#��json�����ļ���ȡ����
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
    #���Ծ��ſ�ͷ��ע�����Լ�����֮����grep����"key"���ڵ���
    #local line=`sed '/^[[:space:]]*#/d' $file | sed /^[[:space:]]*$/d | grep -w "$key"| grep "$key[[:space:]]*="`
    #if [ -z "$line" ]; then
    #    config_answer=""
    #else
        #����һ��=���滻Ϊ�ո���ɾ����һ�����ʵõ�value
    #    config_answer=`echo $line | sed 's/=/ /' | sed -e 's/^\w*\ *//'`
    #fi
    
}

#######################
#���ò�����conf�����ļ�
#######################
function set_config
{
    local file=$1
    local key=$2
    local value=$3

    [ ! -e $file ] && return

    #echo update key $key to value $value in file $file ...
    local exist=`grep "^[[:space:]]*[^#]" $file | grep -c "$key[[:space:]]*=[[:space:]]*.*"`
    #ע�⣺���ĳ����ע�ͣ���ͷ��һ���ַ�������#��!!!
    local comment=`grep -c "^[[:space:]]*#[[:space:]]*$key[[:space:]]*=[[:space:]]*.*"  $file`
    
    if [[ $value == "#" ]];then
        if [ $exist -gt 0 ];then
            sed  -i "/^[^#]/s/$key[[:space:]]*=/\#$key=/" $file       
        fi
        return
    fi

    if [ $exist -gt 0 ];then
        #����Ѿ�����δע�͵���Ч�����У�ֱ�Ӹ���value
        sed  -i "/^[^#]/s#$key[[:space:]]*=.*#$key=$value#" $file
        
    elif [ $comment -gt 0 ];then
        #��������Ѿ�ע�͵��Ķ�Ӧ�����У���ȥ��ע�ͣ�����value
        sed -i "s@^[[:space:]]*#[[:space:]]*$key[[:space:]]*=[[:space:]]*.*@$key=$value@" $file
    else
        #������ĩβ׷����Ч������
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
    
    #��ȡlease�ļ������������mac��ַ���к�
    line=`grep -n -wi "${dhcp_mac}" ${lease_file} |tail -n 1 |awk -F':' '{print $1}'`
    
    [[ ${line} == "" ]] && { pxelog "pxe server did not assign an ip to this target machine";return 1; }
    
    #�ҵ�����к�֮ǰ���һ�γ��ֵ�ip
    ip_addr=`head -n ${line} ${lease_file} | grep -o '\<[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\>' |tail -n 1`
    
    #��ip��ַ�õ�log��־�ļ���
    install_log=/var/log/${ip_addr}
    log_postfix=".log"
    install_log=${install_log}${log_postfix}
    pxelog "dhcp_mac=${dhcp_mac} MACADDR=${MACADDR} install_log=${install_log}!"
    
    return 0
}

function clean_os_files
{
    local MACADDR=$1
    #ɾ��/linuxinstall��/home/install_share��/tftpboot�º�Ŀ�����صĶ���
    rm /linuxinstall/${MACADDR} -rf
    rm /home/install_share/${MACADDR} -rf
    rm /tftpboot/${MACADDR} -rf
    rm /tftpboot/pxelinux.cfg/01-${MACADDR} -rf
}

function clean_all_os_files
{
    #ɾ��/linuxinstall��/home/install_share��/tftpboot������Ŀ�����صĶ���
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

