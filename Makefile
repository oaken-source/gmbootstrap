
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

IMAGE ?= gnuminix.qcow2

ARCH = i386
SIZE = 64G

HOSTKEYS = rsa dsa ecdsa ed25519

LFS_VERSION = 7.10
LFS_MIRROR = http://www.linuxfromscratch.org/lfs/downloads/$(LFS_VERSION)

srcdir = src
builddir = build
sshdir = ssh

 ##############################################################################
 # toplevel targets - all, clean, veryclean, book

.PHONY: all
all: $(builddir) $(sshdir) $(IMAGE)

.PHONY: clean
clean:
	rm -rf $(builddir) $(IMAGE)

.PHONY: veryclean
veryclean: clean
	rm -rf $(sshdir) LFS-BOOK-*.pdf

.PHONY: book
book: LFS-BOOK-$(LFS_VERSION).pdf

LFS-BOOK-%.pdf:
	wget $(LFS_MIRROR)/$@

 ##############################################################################
 # here be dragons - rules to build the final image

$(IMAGE): $(builddir)/stage_0.qcow2
	cp $< $@

$(builddir)/stage_0.qcow2:
	sudo vmdebootstrap --image $@ --arch $(ARCH) --size $(SIZE) --sparse \
		--distribution jessie --grub --verbose --convert-qcow2 \
		--owner $$USER --package openssh-server --customize=$<
	rm -f $@.raw

 ##############################################################################
 # list dependencies of above build steps

$(builddir)/stage_0.qcow2: $(srcdir)/stage_0_customize.sh \
	$(sshdir)/id_rsa.pub \
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


