#!/bin/bash
 ##############################################################################
 #                               gmbootstrap                                  #
 #                                                                            #
 #    Copyright (C) 2016  Andreas Grapentin                                   #
 #                                                                            #
 #    This program is free software: you can redistribute it and/or modify    #
 #    it under the terms of the GNU General Public License as published by    #
 #    the Free Software Foundation, either version 3 of the License, or       #
 #    (at your option) any later version.                                     #
 #                                                                            #
 #    This program is distributed in the hope that it will be useful,         #
 #    but WITHOUT ANY WARRANTY; without even the implied warranty of          #
 #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
 #    GNU General Public License for more details.                            #
 #                                                                            #
 #    You should have received a copy of the GNU General Public License       #
 #    along with this program.  If not, see <http://www.gnu.org/licenses/>.   #
 ##############################################################################

 ##############################################################################
 # this script is invoked after the initial configuration is complete to make
 # the system bootable

set -e
set -u


export LFS=/mnt/lfs


mount -v /dev/sdb4 $LFS
mount -v /dev/sdb2 $LFS/boot
mount -v /dev/sdb5 $LFS/home
swapon -v /dev/sdb3

mount -v --bind /dev $LFS/dev

mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

mkdir -p $LFS/opt/lfs
mount --bind /opt/lfs $LFS/opt/lfs

chroot "$LFS" /usr/bin/env -i              \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin     \
    /bin/bash --login << 'OEOF'

set -e
set -u

cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda4      /            ext4     defaults            1     1
/dev/sda2      /boot        ext3     defaults            1     2
/dev/sda5      /home        ext4     defaults            1     2
/dev/sda3      swap         swap     pri=1               0     0

proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
tmpfs          /tmp         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF

cd /sources

tar -xf linux-4.7.2.tar.xz
cd linux-4.7.2

make mrproper

make defconfig

sed -i '/CONFIG_UEVENT_HELPER_PATH/d' .config
sed -i 's/CONFIG_UEVENT_HELPER=y/# CONFIG_UEVENT_HELPER is not set/' .config

make

make modules_install

cp -v arch/x86/boot/bzImage /boot/vmlinuz-4.7.2-lfs-7.10

cp -v System.map /boot/System.map-4.7.2

cp -v .config /boot/config-4.7.2

install -d /usr/share/doc/linux-4.7.2
cp -r Documentation/* /usr/share/doc/linux-4.7.2

install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

cd ..
rm -rf linux-4.7.2

grub-install /dev/sdb

cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5
insmod ext2
set root=(hd0,2)
menuentry "GNU/Linux, Linux 4.7.2-lfs-7.10" {
        linux   /vmlinuz-4.7.2-lfs-7.10 root=/dev/sda4 ro net.ifnames=0
}
EOF

echo 7.10 > /etc/lfs-release

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="7.10"
DISTRIB_CODENAME="lfs-construct"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

chpasswd << "EOF"
root:pass
EOF

OEOF

umount -R $LFS
zerofree -v /dev/sdb4

