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
 # this script is invoked on the virtual host to prepare the environment and to
 # initiate the build steps of the preliminary toolchain as the lfs user

set -e
set -u


export LFS=/mnt/lfs


mount -v /dev/sdb4 $LFS
mount -v /dev/sdb2 $LFS/boot
mount -v /dev/sdb5 $LFS/home
swapon -v /dev/sdb3

su - lfs << 'EOF'
set -e
set -u
set -x

source ~/.bashrc
cd $LFS/sources

for step in /opt/lfs/stage_2/steps/5.{4..35}.*; do
  source $step
done
EOF

chown -R root:root $LFS/tools

umount -R $LFS
zerofree -v /dev/sdb4
