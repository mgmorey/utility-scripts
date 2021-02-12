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

clean_up() {
    cd
    rm -f ${tmpfiles-}
    rm -rf ${tmpdirs-}
}

create_tmpdir() {
    tmpdir=$(mktemp -d)
    assert [ -n "${tmpdir}" ]
    tmpdirs="${tmpdirs+$tmpdirs }$tmpdir"

    if [ $# -gt 0 ]; then
	trap "$@"
    else
	trap clean_up EXIT INT QUIT TERM
    fi
}

create_tmpfile() {
    tmpfile=$(mktemp)
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"

    if [ $# -gt 0 ]; then
	trap "$@"
    else
	trap clean_up EXIT INT QUIT TERM
    fi
}

get_bin_directory() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    dir="$1"

    if [ $dir != . ]; then
	while [ "$(dirname "$dir")" != / ]; do
	    dir=$(dirname "$dir")

	    if [ -d "$dir/bin" ]; then
		printf "$dir/bin"
		return
	    fi
	done
    fi
)

get_effective_user() (
    get_user_name ${LOGNAME-${USER-${USERNAME}}}
)

get_entry() {
    assert [ $# -ge 1 -a $# -le 2 ]
    assert [ -n "$1" ]

    case "${uname_kernel=$(uname -s)}" in
	(Darwin)
	    get_entry_macos "$@"
	    ;;
	(MINGW64_NT-*)
	    get_entry_mingw "$@"
	    ;;
	(*)
	    get_entry_posix "$@"
	    ;;
    esac
}

get_entry_macos() {
    if [ $1 = passwd -a -n "${2-}" ]; then
	printf '%s\n' $2
    fi
}

get_entry_mingw() {
    if which getent >/dev/null 2>&1; then
	if [ -n "${2-}" ]; then
	    getent $1 | awk -F: '$1 ~ /(^|+)'"${2#*+}"'$/ {print}'
	else
	    getent $1
	fi
    fi
}

get_entry_posix() {
    if which getent >/dev/null 2>&1; then
	getent $1 ${2-}
    elif [ -r /etc/$1 ]; then
	if [ -n "${2-}" ]; then
	    awk -F: '$1 == "'"$2"'" {print}' /etc/$1
	else
	    cat /etc/$1
	fi
    fi
}

get_field() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    get_entry $1 "$2" | cut -d: -f $3
}

get_gecos() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    get_field passwd $1 5
}

get_gnu_diff_command() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (solaris)
		printf '%s\n' gdiff
		return
		;;
	esac
    done

    printf '%s\n' diff
}

get_gnu_grep_command() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (solaris)
		printf '%s\n' ggrep
		return
		;;
	esac
    done

    printf '%s\n' grep
}

get_gnu_install_command() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (solaris)
		printf '%s\n' ginstall
		return
		;;
	esac
    done

    printf '%s\n' install
}

get_group() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if which id >/dev/null 2>&1; then
	id -ng $1
    fi
}

get_group_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if which id >/dev/null 2>&1; then
	id -g $1
    else
	get_field passwd $1 4
    fi
}

get_home() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "${uname_kernel=$(uname -s)}" in
	(Darwin)
	    printf "/Users/%s\n" $1
	    ;;
	(MINGW64_NT-*)
	    printf "/c/Users/%s\n" ${1#*+}
	    ;;
	(*)
	    get_field passwd $1 6
	    ;;
    esac
}

get_profile_path() (
    path=$PATH

    for dir in /usr/gnu/bin "$1/bin" "$1/.local/bin" "$1/.pyenv/bin" "$2"; do
	if is_to_be_included "$dir" "$path"; then
	   path="$dir:$path"
	fi
    done

    printf '%s\n' "$path"
)

get_real_user() {
    if [ -n "${SUDO_USER-}" ]; then
	get_user_name $SUDO_USER
    else
	get_effective_user
    fi
}

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

    printf '%s\n' setpriv
)

get_setpriv_options() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if which id >/dev/null 2>&1; then
	printf '%s\n' \
	       --init-groups \
	       --reset-env \
	       --reuid $(id -u $1) \
	       --regid $(id -g $1)
    fi
)

get_shell() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "${uname_kernel=$(uname -s)}" in
	(Darwin)
	    printf '%s\n' /bin/bash
	    ;;
	(MINGW64_NT-*)
	    printf '%s\n' /bin/bash
	    ;;
	(*)
	    get_field passwd $1 7
	    ;;
    esac
}

get_su_command() (
    case "${uname_kernel=$(uname -s)}" in
	(GNU|Linux)
	    if get_setpriv_command; then
		return
	    fi
	    ;;
    esac

    printf '%s\n' su
)

get_user_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if which id >/dev/null 2>&1; then
	id -u $1
    else
	get_field passwd $1 3
    fi
}

get_user_name() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    get_field passwd $1 1
}

is_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    printf '%s\n' "${2-}" | egrep '(^|:)'"$1"'(:|$)' >/dev/null
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
    case "${uname_kernel=$(uname -s)}" in
	(CYGWIN_NT-*)
	    return 0
	    ;;
	(MINGW64_NT-*)
	    return 0
	    ;;
    esac

    user=$(get_real_user)
    home=$(get_home "$user")

    if [ -n "$home" -a "$HOME" != "$home" ]; then
	if [ "${ENV_VERBOSE-false}" = true ]; then
	    printf "Changing HOME from: %s\n" "$HOME" >&2
	    printf "Changing HOME to: %s\n" "$home" >&2
	fi

	export HOME="$home"
    fi

    shell=$(get_shell "$user")

    if [ -n "$shell" -a $(basename ${SHELL%.exe}) != $(basename $shell) ]; then
	if [ "${ENV_VERBOSE-false}" = true ]; then
	    printf "Changing SHELL from: %s\n" "$SHELL" >&2
	    printf "Changing SHELL to: %s\n" "$shell" >&2
	fi

	export SHELL=$shell
    fi

    profile=$("${1:+$1/}set-profile-parameters" -s ${shell:-/bin/sh})

    if [ -n "$profile" ]; then
	eval "$profile"
    elif [ -n "$home" ]; then
	export PATH=$(get_profile_path "$home" "$1")
    fi

    params=$("${1:+$1/}set-proxy-parameters" -s ${shell:-/bin/sh})

    if [ -n "$params" ]; then
	eval "$params"
    fi
}

validate_group_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if which id >/dev/null 2>&1; then
	if [ "$(id -g)" != $1 ]; then
	    abort "%s: Please try again with group GID %s\n" "$0" "$1"
	fi
    fi
}

validate_group_name() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if which id >/dev/null 2>&1; then
	if [ "$(id -ng)" != $1 ]; then
	    abort "%s: Please try again with group %s\n" "$0" "$1"
	fi
    fi
}

validate_user_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if which id >/dev/null 2>&1; then
	if [ "$(id -u)" != $1 ]; then
	    abort "%s: Please try again as user UID %s\n" "$0" "$1"
	fi
    fi
}

validate_user_name() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if which id >/dev/null 2>&1; then
	user_name=$(id -nu)

	if [ ${user_name#*+} != ${1#*+} ]; then
	    abort "%s: Please try again as user %s\n" "$0" "$1"
	fi
    fi
)
