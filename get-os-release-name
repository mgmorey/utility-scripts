#!/bin/sh -eu

# get-os-release-name: print name of OS distribution release
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

KEYS="os centos fedora redhat system"

system_name="$(uname -s)"

case "$system_name" in
    (Linux)
	for key in $KEYS; do
	    file=/etc/$key-release

	    if [ -r $file ]; then
		case ${file#/etc/} in
		    (os-release)
			if . $file && [ -n "${VERSION_ID:-}" ]; then
			    printf "%s\n" "$VERSION_ID"
			    exit 0
			elif [ -x /usr/bin/lsb_release ]; then
			    /usr/bin/lsb_release -rs
			    exit 0
			else
			    exit 1
			fi
			;;
		    (*-release)
			awk '{print $4}' $file
			exit 0
			;;
		esac
	    fi
	done

	if [ -x /usr/bin/lsb_release ]; then
	    /usr/bin/lsb_release -rs
	fi
	;;
    (Darwin|FreeBSD|GNU|Minix)
	uname -r
	;;
    (SunOS)
	awk 'NR == 1 {print $3}' /etc/release
	;;
    (CYGWIN_NT-*)
	uname -r
	;;
esac
