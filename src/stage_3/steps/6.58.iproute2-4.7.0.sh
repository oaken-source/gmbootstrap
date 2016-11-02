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


tar -xf iproute2-4.7.0.tar.xz
cd iproute2-4.7.0

sed -i /ARPD/d Makefile
sed -i 's/arpd.8//' man/man8/Makefile
rm -v doc/arpd.sgml

sed -i 's/m_ipt.o//' tc/Makefile

make

make DOCDIR=/usr/share/doc/iproute2-4.7.0 install

cd ..
rm -rf iproute2-4.7.0
