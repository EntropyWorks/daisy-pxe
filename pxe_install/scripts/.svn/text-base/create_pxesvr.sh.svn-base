#! /bin/bash

WORKDIR=/etc/pxe_install
source $WORKDIR/scripts/common.sh
source $WORKDIR/scripts/interface.sh
PXE_CFG=$2

#准备工作，安装json文件解析工具jq包
rpm -qi jq >/dev/null 
[ $? -ne 0 ] && rpm -ivh ${WORKDIR}/pxe/jq-1.3-2.el7.x86_64.rpm

# 拷贝用户数据到/home/usrdata目录
mkdir -p /home/install_share

# 设置dhcp服务端ip地址
echo "set dhcp ip..."
#set_svrip $WORKDIR/pxe/pxe_env.conf

set_svrip $PXE_CFG


# 安装pxe服务器组件
echo "install pxe..."
PXE_FILE_PATH=$WORKDIR/pxe
install_pxe $PXE_FILE_PATH

# 网络文件共享
echo "nfs..."
systemctl stop nfs

systemctl list-unit-files |grep linuxinstall.mount
if [ $? -eq 0 ]; then
systemctl stop linuxinstall.mount 
systemctl disable linuxinstall.mount 
fi

umount -l /linuxinstall 2>/dev/null
rm -rf /linuxinstall 2>/dev/null
mkdir /linuxinstall


# 查看是否有#注释标记，如果有的话，则进行清理
install_share_dir=`cat /etc/exports | grep /home/install_share | grep \#`
[ -n "$install_share_dir" ] && sed -i "\/home\/install_share/d" /etc/exports

tftpboot_dir=`cat /etc/exports | grep /tftpboot | grep \#`
[ -n "$tftpboot_dir" ] && sed -i "\/tftpboot/d" /etc/exports

linuxinstall_dir=`cat /etc/exports | grep /linuxinstall | grep \#`
[ -n "$linuxinstall_dir" ] && sed -i "\/linuxinstall/d" /etc/exports


#/* 启动文件共享 */
[ `cat /etc/exports | grep -c /home/install_share` -eq 0 ] && { echo "/home/install_share *(rw,no_root_squash)">> /etc/exports; } \
             || { sed -i "s%/home/install_share.*%/home/install_share *(rw,no_root_squash)%g" /etc/exports; }
[ `cat /etc/exports | grep -c /tftpboot` -eq 0 ]           && { echo "/tftpboot *(ro)"      >> /etc/exports; } \
             || { sed -i "s%/tftpboot.*%/tftpboot *(ro)%g" /etc/exports; }
[ `cat /etc/exports | grep -c /linuxinstall` -eq 0 ]       && { echo "/linuxinstall *(ro)"  >> /etc/exports; } \
             || { sed -i "s%/linuxinstall.*%/linuxinstall *(ro)%g" /etc/exports; }


# 拷贝ISO中的引导程序到根目录
if [  -f "$WORKDIR/ramdisk/initrd.img" ]; then 
cp -f $WORKDIR/ramdisk/initrd.img        /tftpboot/
fi 

if [  -f "$WORKDIR/ramdisk/vmlinuz"  ]; then 
cp -f $WORKDIR/ramdisk/vmlinuz           /tftpboot/
fi 

cp -f /usr/share/syslinux/pxelinux.0           /tftpboot/



 
# 定制pxe配置文件，包括ks文件. 修改的文件路径：/home/install_share/pxe_kickstart.cfg
#custom_pxecfg $WORKDIR/pxe/pxe_env.conf
custom_pxecfg $PXE_CFG


#启动pxe服务器
start_pxesvr
 
