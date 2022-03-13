# -*- Mode: Shell-script -*-

# parameter-functions.sh: define parameter shell functions
# Copyright (C) 2022  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

is_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    printf '%s\n' "$2" | grep -Eq '(^|[: ])'"$1"'([: ]|$)'
}

is_to_be_included() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    test -d "$(get_directory "$1")" && ! is_included "$1" "$2"
}

parse_shell() {
    case $(basename "${1%.exe}") in
	(*bash|ksh*|zsh)
	    shell=${1%.exe}
	    ;;
	(csh|tcsh)
	    shell=${1%.exe}
	    ;;
	(fish)
	    shell=${1%.exe}
	    ;;
	(sh)
	    shell=${1%.exe}
	    ;;
	(*)
	    usage_error '%s: %s: Unsupported shell\n' "$script" "$1"
	    ;;
    esac
}

print_parameter() {
    assert [ $# -gt 0 ]
    assert [ -n "$1" ]

    if [ -z "${2-}" ]; then
	continue
    elif [ "$no_export" = true ]; then
	printf '%s=%s\n' "$1" "$2"
    else
	case "$(basename ${shell%.exe})" in
	    (*bash|ksh*|zsh)
		printf 'export %s="%s"\n' "$1" "$2"
		;;
	    (csh|tcsh)
		printf 'setenv %s "%s";\n' "$1" "$2"
		;;
	    (fish)
		printf 'set -x %s "%s";\n' "$1" "$2"
		;;
	    (*)
		printf '%s="%s"\n' "$1" "$2"
		printf 'export %s\n' "$1"
		;;
	esac
    fi
}

print_parameters() {
    assert [ $# -gt 0 ]

    for var; do
	eval $(printf 'value="${%s-}"\n' "$var")
	print_parameter "$var" "$value"
    done
}

remove_directory() {
    assert [ $# -eq 2 ]
    printf '%s\n' "$2" | sed '
s|:'"$1"':|:|g
s|^'"$1"':||
s|:'"$1"'$||
s|^'"$1"'$||
'
}

usage_error() {
    if [ $# -gt 0 ]; then
	printf "$@" >&2
    fi

    printf '%s\n' '' >&2
    usage
    exit 2
}
