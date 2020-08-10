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

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

create_tmpfile() {
    tmpfile=$(mktemp)
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
}

get_bin_directory() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    dir="$1"

    while [ "$(dirname "$dir")" != / ]; do
	dir=$(dirname "$dir")

	if [ -d "$dir/bin" ]; then
	    printf "$dir/bin"
	    return
	fi
    done
)

get_entry() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    if which getent >/dev/null 2>&1; then
	getent $1 "$2"
    elif [ -r /etc/$1 ]; then
	cat /etc/$1 | grep "^$2:"
    fi
}

get_field() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    get_entry $1 "$2" | cut -d: -f $3
}

get_profile_path() (
    path=$PATH

    for dir in /usr/gnu/bin "$1/bin" "$1/.local/bin" "$1/.pyenv/bin" "$2"; do
	if is_to_be_included "$dir" "$path"; then
	   path="$dir:$path"
	fi
    done

    printf "%s\n" "$path"
)

get_setpriv_command() (
    version=$(setpriv --version 2>/dev/null)

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
    regid=$(id -g $1)
    reuid=$(id -u $1)
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

get_user_home() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "${kernel_name=$(uname -s)}" in
	(MINGW64_NT-*)
	    printf "/c/Users/%s\n" $1
	    ;;
	(Darwin)
	    printf "/Users/%s\n" $1
	    ;;
	(*)
	    get_field passwd $1 6
	    ;;
    esac
}

get_user_name() {
    printf "%s\n" "${SUDO_USER-${USER-${USERNAME-${LOGNAME-$(id -nu)}}}}"
}

get_user_shell() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "${kernel_name=$(uname -s)}" in
	(MINGW64_NT-*)
	    printf "%s\n" /bin/bash
	    ;;
	(Darwin)
	    printf "%s\n" /bin/bash
	    ;;
	(*)
	    get_field passwd $1 7
	    ;;
    esac
}

is_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    printf "%s\n" "$2" | egrep '(^|:)'"$1"'(:|$)' >/dev/null
}

is_to_be_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    test -d $1 && ! is_included $1 "$2"
}

run_unpriv() (
    assert [ $# -ge 1 ]

    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	command=$(get_su_command $SUDO_USER)

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

set_user_profile() {
    user=$(get_user_name)
    home=$(get_user_home "$user")

    if [ -n "$home" -a "$HOME" != "$home" ]; then
	if [ "${ENV_VERBOSE-false}" = true ]; then
	    printf "Changing HOME from: %s\n" "$HOME" >&2
	    printf "Changing HOME to: %s\n" "$home" >&2
	fi

	export HOME="$home"
    fi

    shell=$(get_user_shell "$user")

    if [ -n "$shell" -a "$SHELL" != "$shell" ]; then
	if [ "${ENV_VERBOSE-false}" = true ]; then
	    printf "Changing SHELL from: %s\n" "$SHELL" >&2
	    printf "Changing SHELL to: %s\n" "$shell" >&2
	fi

	export SHELL="$shell"
    fi

    if [ -n "${HOME-}" ]; then
	if [ -x "$HOME/bin/set-parameters" ]; then
	    eval "$($HOME/bin/set-parameters -s /bin/sh)"
	else
	    export PATH=$(get_profile_path "$home" "$1")
	fi
    fi
}

validate_group_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ "$(id -g)" != $1 ]; then
	abort "%s: Please try again with group GID %s\n" "$0" "$1"
    fi
}

validate_group_name() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ "$(id -ng)" != $1 ]; then
	abort "%s: Please try again with group %s\n" "$0" "$1"
    fi
}

validate_user_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ "$(id -u)" != $1 ]; then
	abort "%s: Please try again as user UID %s\n" "$0" "$1"
    fi
}

validate_user_name() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ "$(id -nu)" != $1 ]; then
	abort "%s: Please try again as user %s\n" "$0" "$1"
    fi
}
