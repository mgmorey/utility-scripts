#!/usr/bin/gawk -f

# reformat-fstab.awk: align columns of configuration file /etc/fstab
# Copyright (C) 2025  "Michael G. Morey" <mgmorey@gmail.com>

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

function get_maximum_length(column, nrow) {
    maximum = 6

    for (i = 1; i <= nrow; ++i)
	if (length(column[i]) > maximum)
	    maximum = length(column[i])

    return maximum
}

BEGIN {
    ncol = 6
    nrow = 0
    table[1][0] = "# <file system>"
    table[2][0] = "<mount point>"
    table[3][0] = "<type>"
    table[4][0] = "<options>"
    table[5][0] = "<dump>"
    table[6][0] = "<pass>"
}
/^$/ {
    print $0
}
/^#$/ {
    print $0
}
/^# [^<]/ {
    if (nrow > 0)
	comment[nrow] = $0
    else
	print $0
}
/^# </ {
}
/^[^#]/ {
    if (NF != ncol) {
	exit(1)
    }

    ++nrow

    for (j = 1; j <= ncol; ++j)
	table[j][nrow] = $j
}
END {
    if (nrow == 0)
	exit(1)

    for (j = 1; j <= ncol; ++j)
	width[j] = get_maximum_length(table[j], nrow)

    for (i = 0; i <= nrow; ++i) {
	for (j = 1; j <= ncol; ++j) {
	    if (j < ncol)
		printf("%-*.*s ", width[j], width[j], table[j][i])
	    else
		printf("%-.*s\n", width[j], table[j][i])
	}

	if (comment[i] != "")
	    print comment[i]
    }
}
