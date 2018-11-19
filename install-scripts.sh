#!/bin/sh -eu

# install-scripts: install scripts
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

if [ $(basename "$PWD") == bin ]; then
    abort "Change to source directory"
fi

mkdir -p "$HOME/Documents/bin"

scripts=$(find "$PWD" -name .git -type d -prune -o ! -name '*~' ! -name $(basename $0) -perm 755 -type f -print)

for script in $scripts; do
    if [ ! -e "$HOME/Documents/bin/$(basename $script)" ]; then
	ln -s $script "$HOME/Documents/bin"
    fi
done

if [ ! -e "$HOME/bin" ]; then
    ln -s "$HOME/Documents/bin" "$HOME/bin"
fi
