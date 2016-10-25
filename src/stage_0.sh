#!/bin/bash

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

losetup -d $loop
