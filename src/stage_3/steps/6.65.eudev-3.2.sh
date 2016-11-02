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


tar -xf eudev-3.2.tar.gz
cd eudev-3.2

sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl

cat > config.cache << "EOF"
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include"
EOF

./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-manpages       \
            --disable-static        \
            --config-cache

LIBRARY_PATH=/tools/lib make

mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d

make LD_LIBRARY_PATH=/tools/lib check

make LD_LIBRARY_PATH=/tools/lib install

tar -xvf ../udev-lfs-20140408.tar.bz2
make -f udev-lfs-20140408/Makefile.lfs install

LD_LIBRARY_PATH=/tools/lib udevadm hwdb --update

cd ..
rm -rf eudev-3.2
