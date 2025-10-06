#!/usr/bin/gawk -f

function get_maximum_length(column, nrow) {
    maximum = 6;

    for (i = 1; i <= nrow; ++i)
	if (length(column[i]) > maximum)
	    maximum = length(column[i]);

    return maximum;
}

BEGIN {
    ncol = 6;
    nrow = 0;
    table[1][0] = "# <file system>"
    table[2][0] = "<mount point>"
    table[3][0] = "<type>"
    table[4][0] = "<options>"
    table[5][0] = "<dump>"
    table[6][0] = "<pass>"
}
/^$/ {
    print $0;
}
/^#$/ {
    print $0;
}
/^# [^<]/ {
    if (nrow > 0)
	comment[nrow] = $0;
    else
	print $0;
}
/^# </ {
}
/^[^#]+/ {
    if (NF != ncol) {
	exit(1);
    }

    ++nrow;

    for (j = 1; j <= ncol; ++j)
	table[j][nrow] = $j;
}
END {
    for (j = 1; j <= ncol; ++j) {
	width[j] = get_maximum_length(table[j], nrow);
    }

    for (i = 0; i <= nrow; ++i) {
	for (j = 1; j <= ncol; ++j) {
	    if (j < ncol)
		printf("%-*.*s ", width[j], width[j], table[j][i]);
	    else
		printf("%-.*s\n", width[j], table[j][i]);
	}

	if (comment[i] != "")
	    print comment[i];
    }
}
