# -*- Mode: Shell-script -*-

# common-functions.sh: define commonly used shell functions
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
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
}

get_bin_directory() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    dir=$1

    while [ "$(dirname "$dir")" != / ]; do
	dir="$(dirname "$dir")"

	if [ -d "$dir/bin" ]; then
	    printf "$dir/bin"
	    return
	fi
    done
)

get_home_directory() {
    assert [ $# -eq 1 ]

    case "${kernel_name=$(uname -s)}" in
	(Darwin)
	    printf "/Users/%s\n" "$1"
	    ;;
	(*)
	    getent passwd "$1" | awk -F: '{print $6}'
	    ;;
    esac
}

get_profile_path() {
    path=$PATH

    for prefix in "$1" "$1/.local" "$1/.pyenv"; do
	if is_to_be_included "$prefix/bin" "$path"; then
	   path="$prefix/bin:$path"
	fi
    done

    printf "%s\n" "$path"
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

get_user_name() {
    printf "%s\n" "${SUDO_USER-${USER-${LOGNAME}}}"
}

is_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    printf "%s\n" "$2" | egrep '(^|:)'$1'(:|$)' >/dev/null
}

is_to_be_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    test -d $1 && ! is_included $1 "$2"
}

run_unpriv() (
    assert [ $# -ge 1 ]

    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	command="$(get_su_command $SUDO_USER)"

	case "$command" in
	    (setpriv)
		command="$command $(get_setpriv_options $SUDO_USER)"
		;;
	    (su)
		command="$command $SUDO_USER"

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
