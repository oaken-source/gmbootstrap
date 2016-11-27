
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
 # variable definitions

IMAGE = gnuminix.qcow2
SIZE = 64G

DEBIAN_ARCH = i386
QEMU_ARCH = i386
SSH_PORT = 2222

SSHFLAGS = -p $(SSH_PORT) -i $(sshdir)/id_rsa
SCPFLAGS = -P $(SSH_PORT) -i $(sshdir)/id_rsa

HOSTKEYS = rsa dsa ecdsa ed25519
HOSTPACKAGES = openssh-server build-essential bison gawk sudo ca-certificates \
	       texinfo zerofree

LFS_VERSION = 7.10
LFS_MIRROR = http://www.linuxfromscratch.org/lfs/downloads/$(LFS_VERSION)

export srcdir = src
export builddir = _build
export sourcesdir = _sources
export sshdir = _ssh

 ##############################################################################
 # toplevel targets - all, clean, veryclean

.PHONY: all
all: $(builddir) $(sourcesdir) $(sshdir) $(builddir)/host.qcow2 $(IMAGE)

.PHONY: clean
clean:
	$(RM) -r $(builddir) $(IMAGE) debootstrap.log

.PHONY: veryclean
veryclean: clean
	$(RM) -r $(sshdir) $(sourcesdir) LFS-BOOK-*.pdf

.PHONY: start
start:
	qemu-system-$(QEMU_ARCH) -net user,hostfwd=tcp::$(SSH_PORT)-:22 -net nic \
		--enable-kvm --nographic -hda $(builddir)/host.qcow2 -hdb $(IMAGE) \
		-m 1024 &

.PHONY: stop
stop:
	ssh root@localhost $(SSHFLAGS) 'shutdown -h now'

.PHONY: ssh
ssh:
	ssh root@localhost $(SSHFLAGS)

.PHONY: book
book: LFS-BOOK-$(LFS_VERSION).pdf

LFS-BOOK-%.pdf:
	wget $(LFS_MIRROR)/$@

 ##############################################################################
 # rules to build the final image

$(IMAGE): $(builddir)/stage_5.qcow2
	cp $< $@

$(builddir)/stage_%.qcow2:
	cp $< $@~
	qemu-system-$(QEMU_ARCH) -net user,hostfwd=tcp::$(SSH_PORT)-:22 -net nic \
		--enable-kvm --nographic -hda $(builddir)/host.qcow2 -hdb $@~ \
		-m 1024 &
	while ! ssh root@localhost $(SSHFLAGS) 'exit'; do sleep 1; done
	scp -r $(SCPFLAGS) $(srcdir)/stage_$*/ root@localhost:/opt/lfs/
	ssh root@localhost $(SSHFLAGS) 'cd /opt/lfs/stage_$* && bash stage_$*.sh'
	ssh root@localhost $(SSHFLAGS) 'shutdown -h now' || true
	qemu-img convert -O qcow2 $@~ $@
	$(RM) $@~

$(builddir)/stage_0.qcow2: $(sourcesdir)/wget-list $(sourcesdir)/md5sums
	qemu-img create $@~ $(SIZE)
	for url in $$(cat $(sourcesdir)/wget-list); do wget -c $$url -P $(sourcesdir); done
	cd $(sourcesdir) && md5sum -c md5sums
	sudo -E bash $(srcdir)/stage_0/stage_0.sh $@~
	qemu-img convert -O qcow2 $@~ $@
	$(RM) $@~

$(builddir)/host.qcow2: $(srcdir)/host_customize.sh
	sudo vmdebootstrap --image $@~ --arch $(DEBIAN_ARCH) --size $(SIZE) \
		--distribution jessie --grub --verbose --sparse --owner $$USER \
		$(patsubst %,--package %,$(HOSTPACKAGES)) --customize=$< \
		--enable-dhcp
	qemu-img convert -O qcow2 $@~ $@
	$(RM) $@~

 ##############################################################################
 # rules to generate wget-list and md5sums

$(sourcesdir)/wget-list: $(srcdir)/wget-list
	wget $(LFS_MIRROR)/wget-list -O $@
	cat $< >> $@

$(sourcesdir)/md5sums: $(srcdir)/md5sums
	wget $(LFS_MIRROR)/md5sums -O $@
	cat $< >> $@

 ##############################################################################
 # list additional dependencies of above build steps

$(builddir)/stage_5.qcow2: $(builddir)/stage_4.qcow2 $(srcdir)/stage_5/stage_5.sh

$(builddir)/stage_4.qcow2: $(builddir)/stage_3.qcow2 $(srcdir)/stage_4/stage_4.sh

$(builddir)/stage_3.qcow2: $(builddir)/stage_2.qcow2 $(srcdir)/stage_3/stage_3.sh \
	$(wildcard $(srcdir)/stage_3/steps/*.sh)

$(builddir)/stage_2.qcow2: $(builddir)/stage_1.qcow2 $(srcdir)/stage_2/stage_2.sh \
	$(wildcard $(srcdir)/stage_2/steps/*.sh)

$(builddir)/stage_1.qcow2: $(builddir)/stage_0.qcow2 $(srcdir)/stage_1/stage_1.sh

$(builddir)/stage_0.qcow2: $(srcdir)/stage_0/stage_0.sh

$(builddir)/host.qcow2: $(sshdir)/id_rsa \
	$(patsubst %,$(sshdir)/ssh_host_%_key,$(HOSTKEYS))

 ##############################################################################
 # rules to generate ssh host and user keys

$(sshdir)/id_rsa:
	ssh-keygen -N '' -f $@

$(sshdir)/ssh_host_%_key:
	ssh-keygen -N '' -f $@ -t $*

 ##############################################################################
 # rules to create directories

$(builddir) $(sshdir) $(sourcesdir):
	mkdir -p $@
