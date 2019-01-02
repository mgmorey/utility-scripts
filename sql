#!/bin/sh -eu

# sql: wrapper for invoking SQL database client command line
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

: ${DATABASE_DIALECT:=sqlite}
: ${DATABASE_FILENAME:=${DATABASE_SCHEMA:+/tmp/$DATABASE_SCHEMA.sqlite}}

abort() {
    printf "$@" >&2
    exit 1
}

exec_sql_cli() {
    case "$DATABASE_DIALECT" in
	(mysql)
	    ${1-} "$DATABASE_DIALECT" \
		-h"${DATABASE_HOST:-$localhost}" \
		-u"${DATABASE_USER:-$USER}" \
		-p"${DATABASE_PASSWORD:-}"
	    ;;
	(sqlite)
	    ${1-} sqlite3 $DATABASE_FILENAME
	    ;;
    esac
}

parse_script() {
    if [ -r "$1" ]; then
	script="$1"
    elif [ -r "$sql_dir/$1-$DATABASE_DIALECT.sql" ]; then
	script="$sql_dir/$1-$DATABASE_DIALECT.sql"
    else
	abort "%s: No such script file\n" "$1"
    fi

    scripts="${scripts:+$scripts }$script"
}

realpath() {
    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$@"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..
sql_dir=$source_dir/sql

scripts=

if [ -r .env ]; then
    . ./.env
elif [ -r "$source_dir/.env" ]; then
    . "$source_dir/.env"
elif [ -r "$HOME/.env" ]; then
    . "$HOME/.env"
fi

if [ $# -gt 0 ]; then
    for script; do
	parse_script $script
    done
fi

if [ -n "$scripts" ]; then
    for script in $scripts; do
	if [ -r $script ]; then
	    exec <"$script"
	    exec_sql_cli
	else
	    abort "%s: No read permissions\n" "$script"
	fi
    done
else
    exec_sql_cli exec
fi
