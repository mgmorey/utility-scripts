#!/usr/bin/awk -f

# numeric-list.awk: print numbers as a comma-separated list

{
    printf("%s, ", $1);
}
