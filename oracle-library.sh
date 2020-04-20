# oracle-library.sh: define shell functions for common logic

_get_date_iso_8601() {
    date --iso-8601=seconds | sed 's/\([0-9][0-9]\)-:\([0-9][0-9]\)$/\1\2/'
}

_print() {
    level=$1; shift
    timestamp=$(_get_date_iso_8601)
    printf '%s [%s] [%s] %s\n' "$timestamp" "$level" "$script_basename" "$*"
}

abort() {
    print_error "$@"
    exit 1
}

assert() {
    "$@" || abort "Assertion failed: $*"
}

check_dirs() {
    for dir in ${ORACLE_BASE-} ${ORACLE_HOME-}; do
	if [ ! -d $dir ]; then
	    abort '%s: %s: No such directory\n' "$0" "$dir"
	fi
    done
}

create_tmpfile() {
    tmpfile=$(mktemp)
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
}

filter_db_name() {
    cut -c 1-8
}

filter_sid() {
    tr -cd '[:alnum:]_' | uppercase | cut -c 1-12
}

get_db_name() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    printf '%s\n' "$1" | filter_db_name
}

get_system_id() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    printf '%s\n' "$1" | filter_sid
}

print_debug() {
    _print DEBUG "$@"
}

print_error() {
    _print ERROR "$@" >&2
}

print_info() {
    _print INFO "$@"
}

print_warn() {
    _print WARNING "$@" >&2
}

uppercase() {
    tr '[:lower:]' '[:upper:]'
}
