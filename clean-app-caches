#!/bin/sh -eu

# clean-app-caches: clean Python 3 caches
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

abort() {
    printf "$@" >&2
    exit 1
}

find_caches() {
    find . -type d \( -name "$VENV_DIRECTORY" -prune -o \
	 -name .pytest_cache -print -o \
	 -name __pycache__ -print \)
}

if [ "$(id -u)" -eq 0 ]; then
    abort "%s: Must be run as a non-privileged user\n" "$0"
fi

eval $(get-app-configuration --input app.ini)

/bin/rm -rf $(find_caches)
