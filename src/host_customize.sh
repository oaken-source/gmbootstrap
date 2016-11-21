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
 # this script is passed to vmdebootstrap to finalize preparation of the
 # virtual host environment.

set -e
set -u


# install ssh authorized_keys
mkdir -vp $1/root/.ssh
chmod -v 0700 $1/root/.ssh
cp -v _ssh/id_rsa.pub $1/root/.ssh/authorized_keys
chmod -v 0644 $1/root/.ssh/authorized_keys

# install ssh host keys
cp -v _ssh/ssh_host_* $1/etc/ssh/
chmod -v 0600 $1/etc/ssh/ssh_host_*_key
chmod -v 0644 $1/etc/ssh/ssh_host_*_key.pub

# prepare scripts directory
mkdir -vp $1/opt/lfs
chmod -v a+wt $1/opt/lfs

# create lfs user
chroot $1 << EOF
  ln -vsf bash /bin/sh

  groupadd lfs
  useradd -s /bin/bash -g lfs -m -k /dev/null lfs
EOF
