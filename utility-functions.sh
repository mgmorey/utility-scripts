# -*- Mode: Shell-script -*-

# utility-functions.sh: define commonly used shell functions
# Copyright (C) 2019  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

create_tmpfile() {
    tmpfile=$(mktemp)
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
}

get_setpriv_command() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    version="$(setpriv --version 2>/dev/null)"

    case "${version##* }" in
	('')
	    return 1
	    ;;
	([01].*)
	    return 1
	    ;;
	(2.[0-9].*)
	    return 1
	    ;;
	(2.[12][0-9].*)
	    return 1
	    ;;
	(2.3[012].*)
	    return 1
	    ;;
	(*)
	    options="--init-groups --reset-env"
	    ;;
    esac

    regid="$(id -g $1)"
    reuid="$(id -u $1)"
    printf "setpriv --reuid %s --regid %s %s\n" "$reuid" "$regid" "$options"
)

get_su_command() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "${kernel_name=$(uname -s)}" in
	(GNU|Linux)
	    if get_setpriv_command $1; then
		return 0
	    else
		options=-l
	    fi
	    ;;
	(Darwin|FreeBSD)
	    options=-l
	    ;;
	(*)
	    options=-
	    ;;
    esac

    printf "su %s %s\n" "$options" "$1"
)

run_unpriv() (
    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	su="$(get_su_command $SUDO_USER)"
    else
	su=
    fi

    case "${kernel_name=$(uname -s)}" in
	(SunOS)
	    if expr "$su" : 'su ' >/dev/null; then
		case "$(basename $1)" in
		    (sh)
			case "$2" in
			    (-c)
				shift
				;;
			esac
			;;
		esac
	    fi
	    ;;
    esac

    ${su+$su }"$@"
)
