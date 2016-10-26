#!/bin/bash

set -e
set -u
set -x

loop=$(losetup -f --show $1)

parted $loop << EOF
mklabel gpt
mkpart primary 1MiB 2MiB
mkpart primary ext3 2MiB 250MiB
mkpart primary linux-swap 250MiB 2GiB
mkpart primary ext4 2GiB 24GiB
mkpart primary ext4 24GiB 100%
set 1 bios_grub on
EOF

mkfs.ext3 -v ${loop}p2
mkfs.ext4 -v ${loop}p4
mkfs.ext4 -v ${loop}p5

mkswap ${loop}p3

LFS=$builddir/mnt/lfs

mkdir -pv $LFS
mount -v ${loop}p4 $LFS
mkdir -pv $LFS/{boot,home}
mount -v ${loop}p2 $LFS/boot
mount -v ${loop}p5 $LFS/home
swapon -v ${loop}p3

mkdir -pv $LFS/sources
chmod -v a+wt $LFS/sources
wget -c -P $LFS/sources $LFS_MIRROR/wget-list
wget -i $LFS/sources/wget-list -c -P $LFS/sources
wget -c -P $LFS/sources $LFS_MIRROR/md5sums
pushd $LFS/sources
md5sum -c md5sums
popd

umount -vR $LFS
rm -r $LFS
losetup -d $loop
