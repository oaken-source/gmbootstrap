
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

LFS_VERSION = 7.10
LFS_MIRROR = http://www.linuxfromscratch.org/lfs/downloads/$(LFS_VERSION)

DEBIAN_ARCH = i386
QEMU_ARCH = i386
SSH_PORT = 2222

SSHFLAGS = -p $(SSH_PORT) -i $(sshdir)/id_rsa
SCPFLAGS = -P $(SSH_PORT) -i $(sshdir)/id_rsa

HOSTKEYS = rsa dsa ecdsa ed25519
HOSTPACKAGES = openssh-server build-essential bison gawk texinfo ca-certificates

srcdir = src
builddir = _build
sshdir = _ssh

 ##############################################################################
 # toplevel targets - all, clean, veryclean

.PHONY: all
all: $(builddir) $(sshdir) $(IMAGE)

.PHONY: clean
clean:
	$(RM) -r $(builddir) $(IMAGE) debootstrap.log

.PHONY: veryclean
veryclean: clean
	$(RM) -r $(sshdir) LFS-BOOK-*.pdf

.PHONY: ssh
ssh:
	ssh root@localhost $(SSHFLAGS)

.PHONY: book
book: LFS-BOOK-$(LFS_VERSION).pdf

LFS-BOOK-%.pdf:
	wget $(LFS_MIRROR)/$@

 ##############################################################################
 # rules to build the final image

$(IMAGE): $(builddir)/host.qcow2 $(builddir)/stage_1.qcow2
	cp $< $@

$(builddir)/stage_1.qcow2: $(builddir)/stage_0.qcow2
	cp $< $@~
	qemu-system-$(QEMU_ARCH) -net user,hostfwd=tcp::$(SSH_PORT)-:22 -net nic \
		--enable-kvm --nographic -hda $(builddir)/host.qcow2 -hdb $@~ &
	while ! ssh root@localhost $(SSHFLAGS) 'exit'; do sleep 1; done
	scp -r $(SCPFLAGS) $(srcdir)/stage_1/ root@localhost:
	ssh root@localhost $(SSHFLAGS) 'make -C stage_1'
	ssh root@localhost $(SSHFLAGS) 'shutdown -h now'
	mv $@~ $@

$(builddir)/stage_0.qcow2: $(srcdir)/stage_0/prepare.sh
	qemu-img create $@~ $(SIZE)
	sudo ./$< $@~
	qemu-img convert -O qcow2 $@~ $@
	$(RM) $@~

$(builddir)/host.qcow2: $(srcdir)/stage_0/host_customize.sh
	sudo vmdebootstrap --image $@~ --arch $(DEBIAN_ARCH) --size $(SIZE) \
		--distribution jessie --grub --verbose --sparse --owner $$USER \
		$(patsubst %,--package %,$(HOSTPACKAGES)) --customize=$<
	qemu-img convert -O qcow2 $@~ $@
	$(RM) $@~

 ##############################################################################
 # list additional dependencies of above build steps

$(builddir)/stage_1.qcow2: $(shell find $(srcdir)/stage_1 -type f -not -iname '.*')

$(builddir)/host.qcow2: $(sshdir)/id_rsa\
	$(patsubst %,$(sshdir)/ssh_host_%_key,$(HOSTKEYS))

 ##############################################################################
 # rules to generate ssh host and user keys

$(sshdir)/id_rsa:
	ssh-keygen -N '' -f $@

$(sshdir)/ssh_host_%_key:
	ssh-keygen -N '' -f $@ -t $*

 ##############################################################################
 # rules to create directories

$(builddir) $(sshdir):
	mkdir -p $@
