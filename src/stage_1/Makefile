
export LFS = /mnt/lfs

LFS_VERSION = 7.10
LFS_MIRROR = http://www.linuxfromscratch.org/lfs/downloads/$(LFS_VERSION)


.PHONY: all
all:
	$(MAKE) mount
	$(MAKE) download

.PHONY: mount
mount:
	mkdir -pv $(LFS)
	if ! mount | grep /dev/sdb4; then mount -v /dev/sdb4 $(LFS); fi
	mkdir -pv $(LFS)/{boot,home}
	if ! mount | grep /dev/sdb2; then mount -v /dev/sdb2 $(LFS)/boot; fi
	if ! mount | grep /dev/sdb5; then mount -v /dev/sdb5 $(LFS)/home; fi
	if ! swap | grep /dev/sdb3; then swapon -v /dev/sdb3; fi

.PHONY: download
download:
	mkdir -pv $(LFS)/sources
	chmod -v a+wt $(LFS)/sources
	wget -c -P $(LFS)/sources $(LFS_MIRROR)/wget-list
	wget -i $(LFS)/sources/wget-list -c -P $(LFS)/sources
	wget -c -P $(LFS)/sources $(LFS_MIRROR)/md5sums
	cd $(LFS)/sources && md5sum -c md5sums

