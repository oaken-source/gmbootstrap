
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
QEMU_ARGS = --enable-kvm -net user,hostfwd=tcp::$(SSH_PORT)-:22 -net nic --nographic

HOSTKEYS = rsa dsa ecdsa ed25519

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

.PHONY: book
book: LFS-BOOK-$(LFS_VERSION).pdf

LFS-BOOK-%.pdf:
	wget $(LFS_MIRROR)/$@

 ##############################################################################
 # convenience targets for quick start and ssh access

.PHONY: stop
stop:
	ssh root@localhost -p $(SSH_PORT) -i $(sshdir)/id_rsa 'shutdown -h now'

.PHONY: start
start:
	qemu-system-$(QEMU_ARCH) $(QEMU_ARGS) $(IMAGE) &
	while ! ssh root@localhost -p $(SSH_PORT) -i $(sshdir)/id_rsa 'exit'; do sleep 1; done

 ##############################################################################
 # rules to build the final image

$(IMAGE): $(builddir)/stage_0.qcow2
	cp $< $@

$(builddir)/stage_0.qcow2: $(srcdir)/stage_0.sh
	qemu-img create $@.raw $(SIZE)
	sudo ./$< $@.raw
	qemu-img convert -O qcow2 $@.raw $@
	$(RM) $@.raw

$(builddir)/host.qcow2: $(srcdir)/host_customize.sh
	sudo vmdebootstrap --image $@ --arch $(DEBIAN_ARCH) --size $(SIZE) \
		--distribution jessie --grub --verbose --convert-qcow2 \
		--package 'openssh-server build-essential bison gawk texinfo' \
		--customize=$< --sparse --owner $$USER
	$(RM) $@.raw

 ##############################################################################
 # list dependencies of above build steps

$(builddir)/host.qcow2: $(sshdir)/id_rsa.pub \
	$(patsubst %,$(sshdir)/ssh_host_%_key,$(HOSTKEYS)) \
	$(patsubst %,$(sshdir)/ssh_host_%_key.pub,$(HOSTKEYS)) \

 ##############################################################################
 # rules to generate ssh host and user keys

$(sshdir)/id_rsa.pub: $(sshdir)/id_rsa
$(sshdir)/id_rsa:
	ssh-keygen -N '' -f $@

$(sshdir)/ssh_host_%_key.pub: $(sshdir)/ssh_host_%_key
$(sshdir)/ssh_host_%_key:
	ssh-keygen -N '' -f $@ -t $$(echo $@ | rev | cut -d_ -f2 | rev)

 ##############################################################################
 # rules to create directories

$(builddir):
	mkdir -p $@

$(sshdir):
	mkdir -p $@
