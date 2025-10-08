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

function get_maximum_length(column, i_first, i_last) {
    maximum = 0

    for (i = i_first; i <= i_last; ++i)
	if (length(column[i]) > maximum)
	    maximum = length(column[i])

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
/^#?$/ {
    print $0
}
/^#[ ]+[^<]/ {
    if (header == 1)
	comment[i_last] = $0
    else
	print $0
}
/^#([ ]+<[^>]+>)+/ {
    header = 1
    i_first = 0
    table[1][0] = "# <file system>"
    table[2][0] = "<mount point>"
    table[3][0] = "<type>"
    table[4][0] = "<options>"
    table[5][0] = "<dump>"
    table[6][0] = "<pass>"
}
/^[^#]/ {
    if (NF != j_last) {
	exit(1)
    }

    ++i_last

    for (j = j_first; j <= j_last; ++j)
	table[j][i_last] = $j
}
END {
    if (i_last == 0)
	exit(1)

    for (j = j_first; j <= j_last; ++j) {
	width[j] = get_maximum_length(table[j], i_first, i_last)
    }

    for (i = i_first; i <= i_last; ++i) {
	for (j = j_first; j <= j_last; ++j) {
	    if (j < j_integer)
		printf("%-*s", width[j], table[j][i])
	    else
		printf("%*s", width[j], table[j][i])

	    if (j < j_last)
		printf(" ")
	    else
		printf("\n")
	}

	if (comment[i] != "")
	    print comment[i]
    }
}
