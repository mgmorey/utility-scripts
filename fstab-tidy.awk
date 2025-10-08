#!/usr/bin/gawk -f

# fstab-tidy.awk: align columns of filesytem entries in /etc/fstab
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

function abort(message) {
    printf("%s:%d: %s\n", FILENAME, FNR, message) > "/dev/stderr"
    exit(1)
}

function get_maximum_width(table, i_first, i_last, j) {
    maximum = 0

    for (i = i_first; i <= i_last; ++i) {
	l = length(table[i][j])

	if (l > maximum)
	    maximum = l
    }

    return maximum
}

BEGIN {
    header = 0
    i_first = 1
    i_last = 0
    j_first = 1
    j_integer = 5
    j_last = 6
}
/^#?$/
/^#[\t ]+[^<]/ {
    if (header == 1)
	comment[i_last] = $0
    else
	print
}
/^#([\t ]+<[^>]+>)+/ {
    header = 1
    i_first = 0
    table[0][1] = "# <file system>"
    table[0][2] = "<mount point>"
    table[0][3] = "<type>"
    table[0][4] = "<options>"
    table[0][5] = "<dump>"
    table[0][6] = "<pass>"
}
/^[^#]/ {
    if (NF != j_last)
	abort(sprintf("Column count is %d (should be %d)", NF, j_last))

    ++i_last

    for (j = j_first; j <= j_last; ++j)
	table[i_last][j] = $j
}
END {
    if (i_last == 0)
	abort("No filesystem entries found")

    for (j = j_first; j <= j_last; ++j) {
	width[j] = get_maximum_width(table, i_first, i_last, j)
    }

    for (i = i_first; i <= i_last; ++i) {
	for (j = j_first; j <= j_last; ++j) {
	    if (j < j_integer)
		printf("%-*s", width[j], table[i][j])
	    else
		printf("%*s", width[j], table[i][j])

	    if (j < j_last)
		printf(" ")
	    else
		printf("\n")
	}

	if (comment[i] != "")
	    print comment[i]
    }
}
