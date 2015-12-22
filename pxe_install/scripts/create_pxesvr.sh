#! /bin/bash

WORKDIR=/etc/pxe_install
source $WORKDIR/scripts/common.sh
source $WORKDIR/scripts/interface.sh
PXE_CFG=$2

#׼����������װjson�ļ���������jq��
rpm -qi jq >/dev/null 
[ $? -ne 0 ] && rpm -ivh ${WORKDIR}/pxe/jq-1.3-2.el7.x86_64.rpm

# �����û����ݵ�/home/usrdataĿ¼
mkdir -p /home/install_share

# ����dhcp�����ip��ַ
echo "set dhcp ip..."
#set_svrip $WORKDIR/pxe/pxe_env.conf

set_svrip $PXE_CFG


# ��װpxe���������
echo "install pxe..."
PXE_FILE_PATH=$WORKDIR/pxe
install_pxe $PXE_FILE_PATH

# �����ļ�����
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


# �鿴�Ƿ���#ע�ͱ�ǣ�����еĻ������������
install_share_dir=`cat /etc/exports | grep /home/install_share | grep \#`
[ -n "$install_share_dir" ] && sed -i "\/home\/install_share/d" /etc/exports

tftpboot_dir=`cat /etc/exports | grep /tftpboot | grep \#`
[ -n "$tftpboot_dir" ] && sed -i "\/tftpboot/d" /etc/exports

linuxinstall_dir=`cat /etc/exports | grep /linuxinstall | grep \#`
[ -n "$linuxinstall_dir" ] && sed -i "\/linuxinstall/d" /etc/exports


#/* �����ļ����� */
[ `cat /etc/exports | grep -c /home/install_share` -eq 0 ] && { echo "/home/install_share *(rw,no_root_squash)">> /etc/exports; } \
             || { sed -i "s%/home/install_share.*%/home/install_share *(rw,no_root_squash)%g" /etc/exports; }
[ `cat /etc/exports | grep -c /tftpboot` -eq 0 ]           && { echo "/tftpboot *(ro)"      >> /etc/exports; } \
             || { sed -i "s%/tftpboot.*%/tftpboot *(ro)%g" /etc/exports; }
[ `cat /etc/exports | grep -c /linuxinstall` -eq 0 ]       && { echo "/linuxinstall *(ro)"  >> /etc/exports; } \
             || { sed -i "s%/linuxinstall.*%/linuxinstall *(ro)%g" /etc/exports; }


# ����ISO�е��������򵽸�Ŀ¼
if [  -f "$WORKDIR/ramdisk/initrd.img" ]; then 
cp -f $WORKDIR/ramdisk/initrd.img        /tftpboot/
fi 

if [  -f "$WORKDIR/ramdisk/vmlinuz"  ]; then 
cp -f $WORKDIR/ramdisk/vmlinuz           /tftpboot/
fi 

cp -f /usr/share/syslinux/pxelinux.0           /tftpboot/



 
# ����pxe�����ļ�������ks�ļ�. �޸ĵ��ļ�·����/home/install_share/pxe_kickstart.cfg
#custom_pxecfg $WORKDIR/pxe/pxe_env.conf
custom_pxecfg $PXE_CFG


#����pxe������
start_pxesvr
 
