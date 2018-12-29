#!/bin/sh -eu

# pip-install: install PyPI packages via PIP utility
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

PIP=pip3
PYTHON=python3

abort() {
    printf "$@" >&2
    exit 1
}

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "This script must be run as a non-privileged user"
fi

printf "%s\n" "Upgrading pip"
pip="$(which $PYTHON) -m pip"
$pip install --upgrade --user pip
pip="$(which $PIP)"
printf "%s\n" "Installing PyPI packages"
$pip install --user "$@"
