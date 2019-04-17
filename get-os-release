#!/bin/sh -eu

# get-os-release: print OS distro/release information
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

FILE=/etc/release
OS_FILE=/etc/os-release

print_id() {
    if [ -n "${ID:-}" ]; then
	case "$kernel_name" in
	    (SunOS)
		printf "%s\n" "$ID" | tr '[:upper:]' '[:lower:]'
		;;
	    (*)
		printf "%s\n" "$ID"
		;;
	esac
    fi
}

print_name() {
    if [ -n "${NAME:-}" ]; then
	printf "%s\n" "$NAME"
    fi
}

print_kernel_name() {
    if [ -n "${kernel_name:-}" ]; then
	printf "%s\n" "$kernel_name"
    fi
}

print_kernel_release() {
    if [ -n "${kernel_release:-}" ]; then
	printf "%s\n" "$kernel_release"
    fi
}

print_pretty_name() {
    if [ -n "${PRETTY_NAME:-}" ]; then
	printf "%s\n" "$PRETTY_NAME"
    fi
}

print_version_id() {
    if [ -n "${VERSION_ID:-}" ]; then
	printf "%s\n" "$VERSION_ID"
    fi
}

usage() {
    printf "Usage: %s: [-h|-i|-k|-n|-p|-r]\n" $(basename "$0")
}

sys_info=$(uname -sr)
kernel_name=${sys_info% *}
kernel_release=${sys_info#* }

case "$kernel_name" in
    (Linux)
	. $OS_FILE
	;;
    (SunOS)
	data=$(awk 'NR == 1 {printf("%s %s:%s\n", $1, $2, $3)}' $FILE)
	name=${data%:*}
	version_id=${data#*:}
	ID=${name% *}
	NAME=$name
	PRETTY_NAME="$name $version_id"
	VERSION_ID=$version_id
	;;
    (*)
	ID=
	NAME=$kernel_name
	PRETTY_NAME=$sys_info
	VERSION_ID=$kernel_release
	;;
esac

if [ $# -eq 0 ]; then
    print_id
    exit 0
fi

while getopts hiknprv opt
do
     case $opt in
	 (h)
	     usage
	     ;;
	 (i)
	     print_id
	     ;;
	 (k)
	     print_kernel_name
	     ;;
	 (n)
	     print_name
	     ;;
	 (p)
	     print_pretty_name
	     ;;
	 (r)
	     print_kernel_release
	     ;;
	 (v)
	     print_version_id
	     ;;
	 (?)
	     usage
	     exit 2
	     ;;
     esac
done
