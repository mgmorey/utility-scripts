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

PKGSRC_PREFIXES=$(ls -d /opt/local /opt/pkg /usr/pkg 2>/dev/null || true)
SYSTEM_PREFIXES="$HOME/.local /usr/local $PKGSRC_PREFIXES /usr"

activate_virtualenv() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d $1/bin -a -r $1/bin/activate ]

    if [ "${VENV_VERBOSE-false}" = true ]; then
	printf "%s\n" "Activating virtual environment" >&2
    fi

    set +u
    . "$1/bin/activate"
    set -u
}

check_python() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    printf "Python %s interpreter found: %s\n" "$2" "$1" >&2

    if ! "$1" "$(which test-python-version.py)" $2 >&2; then
	return 1
    fi

    return 0
}

create_tmpfile() {
    tmpfile=$(mktemp)
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
}

create_virtualenv() (
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    python=${2-}

    if [ -z "${python-}" ]; then
	python=$(find_system_python | awk '{print $1}')

	if [ -z "${python-}" ]; then
	    abort "%s\n" "No suitable system Python interpreter found"
	fi

	python=$(find_user_python $python)

	if [ -z "${python-}" ]; then
	    abort "%s\n" "No suitable user Python interpreter found"
	fi

	version="$(get_python_version $python)"

	if ! check_python "$python" "$version"; then
	    abort "%s\n" "No suitable Python interpreter found"
	fi
    fi

    if [ "$VENV_VERBOSE" = true ]; then
	printf "Creating virtual environment in %s\n" "$1" >&2
    fi

    for utility in ${venv_utilities-$VENV_UTILITIES}; do
	case "$utility" in
	    (pyvenv)
		command=$(get_command -p $python $utility || true)
		options="$1"
		;;
	    (virtualenv)
		command=$(get_command $utility || true)
		options="-p $python $1"
		;;
	    (*)
		command=
		continue
		;;
	esac

	if [ -z "$command" ]; then
	    continue
	fi

	if [ "$VENV_VERBOSE" = true ]; then
	    pathname=$(printf "%s\n" "$command" | awk '{print $1}')
	    version=$($pathname --version)
	    printf "Using %s %s from %s\n" "$utility" \
		   "${version#Python }" \
		   "$(which $pathname)" >&2
	fi

	if $command $options; then
	    return 0
	fi
    done

    abort "%s: No virtualenv utility found\n" "$0"
)

find_python() (
    python=$(find_system_python | awk '{print $1}')
    python=$(find_user_python $python)
    version="$(get_python_version $python)"

    if ! check_python "$python" "$version" >&2; then
	abort "%s\n" "No suitable Python interpreter found"
    fi

    printf "%s\n" "$python"
)

find_system_python() (
    if [ -n "${SYSTEM_PYTHON-}" -a -n "${SYSTEM_PYTHON_VERSION-}" ]; then
	basename="$(basename "$SYSTEM_PYTHON")"
	python="$SYSTEM_PYTHON"
	suffix="${basename#python}"
	version="$SYSTEM_PYTHON_VERSION"
	printf "%s %s %s\n" "$python" "$suffix" "$version"
    else
	find_system_pythons | head -n 1
    fi
)

find_system_pythons() (
    for suffix in $PYTHON_VERSIONS; do
	for system_prefix in $SYSTEM_PREFIXES; do
	    if [ -x $system_prefix/bin/python$suffix ]; then
		python=$system_prefix/bin/python$suffix
		version="$(get_python_version $python 2>/dev/null || true)"

		if [ -n "$version" ]; then
		    printf "%s %s %s\n" "$python" "$suffix" "$version"
		fi
	    fi
	done
    done
)

find_user_python() (
    assert [ $# -eq 1 ]
    python_versions=$($1 "$(which test-python-version.py)")

    if pyenv --version >/dev/null 2>&1; then
	pyenv_root="$(pyenv root)"
	which="pyenv which"
    else
	pyenv_root=
	which=which
    fi

    if [ -n "$pyenv_root" ]; then
	for version in $python_versions; do
	    python=$(find_user_python_installed $pyenv_root $version || true)

	    if [ -z "$python" -a -n "${SYSTEM_PYTHON-}" ]; then
		basename="$(basename "$SYSTEM_PYTHON")"
		suffix="${basename#python}"

		if [ "$suffix" = "$version" ]; then
		    python="$SYSTEM_PYTHON"
		fi
	    fi

	    if [ -z "$python" ]; then
		if install_python_version >&2; then
		    python=$(find_user_python_installed $pyenv_root $version)
		else
		    break
		fi
	    fi

	    if [ -n "$python" ]; then
		printf "%s\n" "$python"
		return 0
	    fi
	done
    fi

    for version in $python_versions; do
	python=$($which python$version 2>/dev/null || true)

	if [ -n "$python" ]; then
	    printf "%s\n" "$python"
	    return 0
	fi
    done

    return 1
)

find_user_python_installed() (
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    sort_versions=$(get_sort_command)
    pythons="$(ls $1/versions/$2.*/bin/python 2>/dev/null | $sort_versions)"

    for python in $pythons; do
	if $python --version >/dev/null 2>&1; then
	    printf "%s\n" "$python"
	    return 0
	fi
    done

    return 1
)

get_command() (
    assert [ $# -ge 1 ]

    if [ $# -ge 1 ] && [ "$1" = -p ]; then
	dirname="$(dirname "$2")"
	versions="${2#*python}"
	shift 2
    else
	dirname=
	versions=
    fi

    if [ $# -ge 1 ] && [ "$1" = -v ]; then
	if [ -z "${versions}" ]; then
	    versions="$2"
	fi

	shift 2
    fi

    assert [ $# -eq 1 ]
    basename="$1"

    case "$basename" in
	(pyvenv)
	    module=venv
	    option=--help
	    ;;
	(*)
	    module=$basename
	    option=--version
	    ;;
    esac

    if [ -n "${versions-}" ]; then
	for version in $versions; do
	    if get_command_helper "$dirname" "$basename" $version; then
		return 0
	    fi
	done
    elif get_command_helper "$dirname" "$basename"; then
	return 0
    fi

    return 1
)

get_command_helper() (
    if ! expr "$2" : pyvenv >/dev/null; then
	scripts="${1:+$1/}$2${3-}${3+ ${1:+$1/}$2-$3}"
    else
	scripts=
    fi

    for command in $scripts "${1:+$1/}python${3-} -m $module"; do
	if $command $option >/dev/null 2>&1; then
	    printf "%s\n" "$command"
	    return 0
	fi
    done

    return 1
)

get_file_metadata() {
    assert [ $# -eq 2 ]

    case "${kernel_name=$(uname -s)}" in
	(GNU|Linux|SunOS)
	    /usr/bin/stat -Lc "$@"
	    ;;
	(Darwin|FreeBSD)
	    /usr/bin/stat -Lf "$@"
	    ;;
    esac
}

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

get_pip_command() {
    if [ -n "${1-}" ]; then
	get_command -p $1 pip
    elif [ -x $HOME/.local/bin/pip ]; then
	printf "%s\n" "$HOME/.local/bin/pip"
    else
	get_command -v "$PYTHON_VERSIONS" pip
    fi
}

get_pip_requirements() {
    printf -- "--requirement %s\n" ${pip_requirements:-$PIP_REQUIREMENTS}
}

get_python_version() (
    output="$($1 --version)"

    if [ -n "$output" ]; then
	printf "%s\n" "${output#Python }"
    fi
)

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

get_sort_command() {
    case "${kernel_name=$(uname -s)}" in
	(NetBSD)
	    printf "%s\n" "sort -r"
	    ;;
	(SunOS)
	    printf "%s\n" "gsort -Vr"
	    ;;
	(*)
	    printf "%s\n" "sort -Vr"
	    ;;
    esac
}

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

get_user_name() {
    printf "%s\n" "${SUDO_USER-${USER-${LOGNAME}}}"
}

get_versions_all() {
    set_path
    pyenv install --list | awk 'NR > 1 {print $1}' | grep_version ${1-}
}

get_versions_passed() (
    python=$(find_system_python | awk '{print $1}')
    python_versions=$($python "$(which test-python-version.py)" --delim '\.')

    for python_version in ${python_versions-$PYTHON_VERSIONS}; do
	if get_versions_all $python_version; then
	    return 0
	fi
    done

    return 1
)

grep_path() {
    printf "%s\n" "$1" | awk 'BEGIN {RS=":"} {print $0}' | grep "$2" >/dev/null
}

grep_version() {
    assert [ $# -le 1 ]

    if [ $# -eq 1 ]; then
	egrep '^'"$1"'(\.[0-9]+){0,2}$'
    else
	cat
    fi
}

have_same_device_and_inode() (
    stats_1="$(get_file_metadata %d:%i "$1")"
    stats_2="$(get_file_metadata %d:%i "$2")"

    if [ "$stats_1" = "$stats_2" ]; then
	return 0
    else
	return 1
    fi
)

install_python_version() (
    case "$ID" in
	(solaris)
	    return 1
	    ;;
	(windows)
	    return 1
	    ;;
    esac

    python=${1-$(get_versions_passed | $(get_sort_command) | head -n 1)}

    if [ -z "$python" ]; then
	return 1
    fi

    set_compiler
    set_flags
    set_path

    if [ "${pyenv_install_verbose-$PYENV_INSTALL_VERBOSE}" = true ]; then
	printenv | egrep '^(CC|CFLAGS|CPPFLAGS|LDFLAGS|PATH)=' | sort
    fi

    pyenv install -s $python
)

install_requirements_via_pip() (
    pip=$(get_pip_command ${1-${VENV_DIRECTORY-venv}}/bin/python)

    if [ -z "$pip" ]; then
	abort "%s: No pip command found in PATH\n" "$0"
    fi

    if [ "$PIP_UPGRADE_VENV" = true ]; then
	printf "%s\n" "Upgrading virtual environment packages via pip" >&2
	install_via_pip "$pip" --upgrade pip || true
    fi

    printf "%s\n" "Installing virtual environment packages via pip" >&2
    install_via_pip "$pip" $(get_pip_requirements)
)

install_via_pip() (
    assert [ $# -ge 1 ]
    pip=$1
    shift
    id="$(id -u)"

    if [ "$PIP_INSTALL_VERBOSE" = true ]; then
	printf "Using %s\n" "$($pip --version)" >&2
    fi

    if [ "$id" -eq 0 ]; then
	options=--no-cache-dir
    else
	options=
    fi

    if [ "$PIP_INSTALL_QUIET" = true ]; then
	options="${options+$options }--quiet"
    fi

    if [ "$id" -eq 0 -a -z "${VIRTUAL_ENV:-}" ]; then
	export PATH=$HOME/.local/bin:$PATH
    fi

    if [ "${pip_install_verbose-$PIP_INSTALL_VERBOSE}" = true ]; then
	printenv | egrep '^(CC|CFLAGS|CPPFLAGS|LDFLAGS|PATH)=' | sort
    fi

    $pip install $options "$@" >&2
)

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

refresh_via_pip() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]

    if [ -n "${VIRTUAL_ENV:-}" -a -d "$1" ]; then
	if have_same_device_and_inode "$VIRTUAL_ENV" "$1"; then
	    abort "%s: %s: Virtual environment activated\n" "$0" "$VIRTUAL_ENV"
	fi
    fi

    if [ -d $1 ]; then
	sync=false
    else
	sync=true
    fi

    if [ $sync = true ]; then
	if [ "$PIP_UPGRADE_USER" = true ]; then
	    if upgrade_via_pip pip virtualenv; then
		if [ -n "${BASH:-}" -o -n "${ZSH_VERSION:-}" ] ; then
		    hash -r
		fi
	    fi
	fi

	create_virtualenv "$@"
    fi

    if [ -r $1/bin/activate ]; then
	activate_virtualenv $1
	assert [ -n "${VIRTUAL_ENV-}" ]

	if [ "${venv_force_sync:-$sync}" = true ]; then
	    install_requirements_via_pip $1
	fi
    elif [ -d $1 ]; then
	abort "%s: Unable to activate environment\n" "$0"
    else
	abort "%s: No virtual environment\n" "$0"
    fi
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

set_compiler() {
    case "$ID" in
	(freebsd)
	    export CC=/usr/bin/clang
	    ;;
	(illumos)
	    export CC=/usr/bin/gcc
	    ;;
	(macos)
	    export CC=/usr/bin/clang
	    ;;
	(solaris)
	    export CC=/opt/developerstudio12.6/bin/cc
	    ;;
    esac
}

set_flags() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (solaris)
		export CFLAGS=-m64
		break
		;;
	esac
    done
}

set_path() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (solaris)
		if ! expr "$PATH" : /usr/gnu/bin >/dev/null; then
		    export PATH=/usr/gnu/bin:$PATH
		fi

		break
		;;
	esac
    done
}

set_unpriv_environment() {
    home="$(get_home_directory $(get_user_name))"
    path="$(get_profile_path "$home")"

    if [ "$HOME" != "$home" ]; then
	if [ "${ENV_VERBOSE-false}" = true ]; then
	    printf "Changing HOME from: %s\n" "$HOME" >&2
	    printf "Changing HOME to: %s\n" "$home" >&2
	fi

	export HOME="$home"
    fi

    if [ "$PATH" != "$path" ]; then
	if [ "${ENV_VERBOSE-false}" = true ]; then
	    printf "Changing PATH from: %s\n" "$PATH" >&2
	    printf "Changing PATH to: %s\n" "$path" >&2
	fi

	export PATH="$path"
    fi
}

upgrade_via_pip() (
    pip=$(get_pip_command)

    if [ -z "$pip" ]; then
	abort "%s: No pip command found in PATH\n" "$0"
    fi

    printf "%s\n" "Upgrading user packages via pip" >&2
    install_via_pip "$pip" --upgrade --user "$@"
)
