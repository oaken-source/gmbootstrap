#!/bin/bash

set -e
set -u


mkdir -pv $LFS
mount -v /dev/sdb4 $LFS
mkdir -pv $LFS/{boot,home}
mount -v /dev/sdb2 $LFS/boot
mount -v /dev/sdb5 $LFS/home
swapon -v /dev/sdb3

