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

SETPRIV_RE='setpriv from util-linux \([0-9][0-9]*\(\.[0-9][0-9]*\)*\)'

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort '%s: Assertion failed: %s\n' "$0" "$*"
}

clean_up() {
    eval rm -rf ${tmpdirs-}
    eval rm -f ${tmpfiles-}
}

compare_command_versions() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    compare_versions "$(get_command_version "$1" "$2")" \
		     "$3" "$(get_field_count "$3" '.')"
}

compare_versions() (
    assert [ $# -eq 3 ]
    m=$(printf '%s\n' ${1:-0} | cut -d. -f 1)
    n=$(printf '%s\n' ${2:-0} | cut -d. -f 1)
    delta=$((m - n))
    nfields=${3:-1}

    if [ $nfields -le 1 -o $delta -ne 0 ]; then
	printf '%s\n' $delta
	return 0
    fi

    compare_versions "${1#*.}" "${2#*.}" $((nfields - 1))
)

create_tmpdir() {
    trap clean_up EXIT INT QUIT TERM
    tmpdir=$(mktemp -d "$@")
    assert [ -n "${tmpdir}" ]
    tmpdirs="${tmpdirs+$tmpdirs }'$tmpdir'"
}

create_tmpfile() {
    trap clean_up EXIT INT QUIT TERM
    tmpfile=$(mktemp "$@")
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }'$tmpfile'"
}

get_bin_directory() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    dir=$1

    if [ $dir != . ]; then
	while [ "$(dirname "$dir")" != / ]; do
	    dir=$(dirname "$dir")

	    if [ -d "$dir/bin" ]; then
		printf '%s\n' "$dir/bin"
		return 0
	    fi
	done
    fi
)

get_command_version() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    expr "$("$1" --version 2>/dev/null)" : "$2"
}

get_ds_entry() {
    assert [ $# -ge 1 -a $# -le 2 ]
    assert [ -n "$1" ]

    case "${uname_kernel=$(uname -s)}" in
	(Darwin)
	    get_ds_entry_macos "$@"
	    ;;
	(MINGW64_NT-*)
	    get_ds_entry_mingw "$@"
	    ;;
	(*)
	    get_ds_entry_posix "$@"
	    ;;
    esac
}

get_ds_entry_macos() (
    case "$1" in
	(group)
	    category=group
	    ;;
	(passwd)
	    category=user
	    ;;
	(*)
	    category=
    esac

    if [ -n "$category" ]; then
	dscacheutil -q $category -a name "$2"
    fi
)

get_ds_entry_mingw() {
    if /usr/bin/which getent >/dev/null 2>&1; then
	if [ -n "${2-}" ]; then
	    getent $1 | awk -F: '$1 ~ /(^|+)'"${2#*+}"'$/ {print}'
	else
	    getent $1
	fi
    fi
}

get_ds_entry_posix() {
    if /usr/bin/which getent >/dev/null 2>&1; then
	getent $1 ${2-}
    elif [ -r /etc/$1 ]; then
	if [ -n "${2-}" ]; then
	    awk -F: '$1 == "'"$2"'" {print}' /etc/$1
	else
	    cat /etc/$1
	fi
    fi
}

get_ds_field() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]

    case "${uname_kernel=$(uname -s)}" in
	(Darwin)
	    get_ds_field_macos "$@"
	    ;;
	(*)
	    get_ds_field_posix "$@"
	    ;;
    esac
}

get_ds_field_macos() (
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    field=$(get_ds_field_name "$1" "$3")

    if [ -n "$field" ]; then
	get_ds_entry_macos $1 "$2" | awk -F': ' '$1 == "'$field'" {print $2}'
    fi
)

get_ds_field_name() (
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    field=

    case "$1" in
	(group)
	    case "$2" in
		(1)
		    field=name
		    ;;
		(2)
		    field=password
		    ;;
		(3)
		    field=gid
		    ;;
		(4)
		    field=users
		    ;;
	    esac
	    ;;
	(passwd)
	    case "$2" in
		(1)
		    field=name
		    ;;
		(2)
		    field=password
		    ;;
		(3)
		    field=uid
		    ;;
		(4)
		    field=gid
		    ;;
		(5)
		    field=gecos
		    ;;
		(6)
		    field=dir
		    ;;
		(7)
		    field=shell
		    ;;
	    esac
	    ;;
    esac

    printf '%s\n' "$field"
)

get_ds_field_posix() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    get_ds_entry $1 "$2" | cut -d: -f $3
}

get_effective_user() {
    get_user_name ${LOGNAME-${USER-${USERNAME}}}
}

get_field_count() {
    printf '%s\n' "${1-}" | awk ${2:+-F$2 }'{print NF}'
}

get_gecos() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    get_ds_field passwd $1 5
}

get_gnu_diff_command() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (solaris)
		printf '%s\n' gdiff
		return 0
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
		return 0
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
		return 0
		;;
	esac
    done

    printf '%s\n' install
}

get_group() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if /usr/bin/which id >/dev/null 2>&1; then
	id -ng $1
    fi
}

get_group_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if /usr/bin/which id >/dev/null 2>&1; then
	id -g $1
    else
	get_ds_field passwd $1 4
    fi
}

get_home() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    get_ds_field passwd $1 6
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

get_setpriv_command() {
    assert [ $# -eq 3 ]

    if [ -n "${1-}" ] && is_valid_command_version "$1" "${2-}" "${3-}"; then
	printf '%s\n' setpriv
	return 0
    fi

    return 1
}

get_setpriv_options() (
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    printf '%s\n' --init-groups
    delta=$(compare_versions $2 2.33 2)

    if [ "$delta" -ge 0 ]; then
	printf '%s\n' --reset-env
    fi

    printf '%s\n' \
	   --reuid $(get_user_id $1) \
	   --regid $(get_group_id $1)
)

get_shell() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    get_ds_field passwd $1 7
}

get_su_command() (
    assert [ $# -eq 3 ]

    if ! get_setpriv_command "${1-}" "${2-}" "${3-}"; then
	printf '%s\n' su
    fi
)

get_user_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if /usr/bin/which id >/dev/null 2>&1; then
	id -u $1
    else
	get_ds_field passwd $1 3
    fi
}

get_user_name() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    get_ds_field passwd $1 1
}

is_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    printf '%s\n' "${2-}" | grep -Eq '(^|:)'"$1"'(:|$)'
}

is_to_be_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    test -d $1 && ! is_included $1 "$2"
}

is_valid_command_version() (
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    delta=$(compare_versions $1 $2 ${3:-$(get_field_count $2 '.')})

    if [ -n "$delta" ] && [ "$delta" -ge 0 ]; then
	return 0
    fi

    return 1
)

run_unpriv() (
    assert [ $# -ge 1 ]

    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	version=$(get_command_version setpriv "$SETPRIV_RE" || true)
	command=$(get_su_command "$version" 2.32 2)

	case "$command" in
	    (setpriv)
		options=$(get_setpriv_options $SUDO_USER "$version")
		command="$command $options"
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
	    printf 'Changing HOME from: %s\n' "$HOME" >&2
	    printf 'Changing HOME to: %s\n' "$home" >&2
	fi

	export HOME=$home
    fi

    shell=$(get_shell "$user")

    if [ -n "$shell" -a $(basename ${SHELL%.exe}) != $(basename $shell) ]; then
	if [ "${ENV_VERBOSE-false}" = true ]; then
	    printf 'Changing SHELL from: %s\n' "$SHELL" >&2
	    printf 'Changing SHELL to: %s\n' "$shell" >&2
	fi

	export SHELL=$shell
    fi

    case "$(basename ${shell:-/bin/sh})" in
	(bash)
	    profiles=".bash_profile .profile"
	    ;;
	(ksh|sh)
	    profiles=".profile"
	    ;;
	(zsh)
	    profiles=".zprofile"
	    ;;
	(*)
	    profiles=
	    ;;
    esac

    for profile in $profiles; do
	if [ -r "$HOME/$profile" ]; then
	    shell_state=$(set +o)
	    set +euvx
	    . "$HOME/$profile"
	    eval "$shell_state"
	    return 0
	fi
    done

    params=$("${1:+$1/}set-profile-parameters" -s ${shell:-/bin/sh})

    if [ -n "$params" ]; then
	eval "$params"
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

    if /usr/bin/which id >/dev/null 2>&1; then
	if [ "$(id -g)" != $1 ]; then
	    abort '%s: Please try again with group GID %s\n' "$0" "$1"
	fi
    fi
}

validate_group_name() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if /usr/bin/which id >/dev/null 2>&1; then
	if [ "$(id -ng)" != $1 ]; then
	    abort '%s: Please try again with group %s\n' "$0" "$1"
	fi
    fi
}

validate_user_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if /usr/bin/which id >/dev/null 2>&1; then
	if [ "$(id -u)" != $1 ]; then
	    abort '%s: Please try again as user UID %s\n' "$0" "$1"
	fi
    fi
}

validate_user_name() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if /usr/bin/which id >/dev/null 2>&1; then
	user_name=$(id -nu)

	if [ ${user_name#*+} != ${1#*+} ]; then
	    abort '%s: Please try again as user %s\n' "$0" "$1"
	fi
    fi
)
