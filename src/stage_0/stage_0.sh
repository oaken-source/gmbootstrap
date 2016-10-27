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
 # this script is invoked on the build host to prepare the structure of the
 # bootstrapped image

set -e
set -u


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

LFS=$(mktemp -d)

mkdir -pv $LFS
mount -v ${loop}p4 $LFS
mkdir -pv $LFS/{boot,home}
mount -v ${loop}p2 $LFS/boot
mount -v ${loop}p5 $LFS/home

mkdir -pv $LFS/sources
chmod -v a+wt $LFS/sources
wget -c -P $LFS/sources $LFS_MIRROR/wget-list
wget -i $LFS/sources/wget-list -c -P $LFS/sources
wget -c -P $LFS/sources $LFS_MIRROR/md5sums
pushd $LFS/sources
md5sum -c md5sums
popd

umount -vR $LFS
losetup -d $loop

rm -r $LFS
