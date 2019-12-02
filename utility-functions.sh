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
    assert [ $# -ge 1 ]

    if [ "$1" = -c ]; then
	sh_opts="$1"
	shift
    else
	sh_opts=
    fi

    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	su="$(get_su_command $SUDO_USER) $sh_opts"
    elif [ -n "$sh_opts" ]; then
	su="sh $sh_opts"
    else
	su=
    fi

    $su "$@"
)
