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
    esac

    printf "%s\n" setpriv
)

get_setpriv_options() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    regid="$(id -g $1)"
    reuid="$(id -u $1)"
    printf -- "%s\n" "--init-groups --reset-env --reuid $reuid --regid $regid"
)

get_su_command() (
    case "${kernel_name=$(uname -s)}" in
	(GNU|Linux)
	    if get_setpriv_command; then
		return
	    fi
	    ;;
    esac

    printf "%s\n" su
)

get_su_options() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "${kernel_name=$(uname -s)}" in
	(GNU|Linux)
	    options="-l $1"
	    ;;
	(Darwin|FreeBSD)
	    options="-l $1"
	    ;;
	(*)
	    options="- $1"
	    ;;
    esac

    printf -- "%s\n" "$options"
)

run_unpriv() (
    assert [ $# -ge 1 ]

    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	command="$(get_su_command $SUDO_USER)"

	case "$command" in
	    (setpriv)
		command="$command $(get_setpriv_options $SUDO_USER)"
		;;
	    (su)
		command="$command $(get_su_options $SUDO_USER)"

		if [ "${1-}${2+ $2}" = "/bin/sh -c" ]; then
		    shift
		else
		    command="$command -c"
		fi
		;;
	esac
    else
	command=
    fi

    ${command+$command }"$@"
)
