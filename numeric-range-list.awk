#!/usr/bin/awk -f

# numeric-range-list.awk: print numbers as a comma-separated list of ranges

BEGIN {
    earliest = "";
    latest = "";
}
{
    if (earliest != "" && latest != "" && $1 > latest + 1) {
        if (latest > earliest) {
            printf("%s - %s, ", earliest, latest);
            earliest = $1;
        }
        else {
            printf("%s, ", latest);
        }
    }
    else if (latest != "" && $1 == latest + 1) {
        printf("%s, ", latest);
    }

    if (latest == "") {
        latest = $1;
    }

    if (earliest == "") {
        earliest = latest;
    }
}
END {
}
