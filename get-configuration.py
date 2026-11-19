#!/usr/bin/env run-python
# -*- Mode: Python -*-

# get-configuration.py: print application configuration parameters
# Copyright (C) 2020  "Michael G. Morey" <mgmorey@gmail.com>

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

"""Print application configuration parameters."""

import argparse
import configparser
import os
import sys
from configparser import *

TO_UNDERSCORES = str.maketrans(' .-', '___')
TO_SPACES = str.maketrans('\n', ' ')


def format_key(key: str, prefix: str) -> str:
    """Format application configuration parameter key."""
    return '_'.join([prefix, key]).translate(TO_UNDERSCORES).upper()


def format_pair(key: str, value: str, prefix: str) -> str:
    """Format application configuration parameter key and value."""
    return "{0}='{1}'".format(format_key(key, prefix), format_value(value))


def format_value(value: str) -> str:
    """Format a value as the contents of a single-quoted shell word."""
    return value.translate(TO_SPACES).replace("'", "'\\''")


def get_pairs(args, config):
    """Get the variable names and values of the selected sections."""
    names = {}
    pairs = []

    for section in (args.sections if args.sections else config.sections()):
        prefix = args.prefix if args.prefix else section

        for key, value in config[section].items():
            name = format_key(key, prefix)
            origin = (section, key)

            if not args.prefix and names.setdefault(name, origin) != origin:
                raise ValueError('{0}: [{1}] {2} and [{3}] {4} are both {0}'
                                 .format(name, *names[name], *origin))

            pairs.append(format_pair(key, value, prefix))

    return pairs


def main():
    """Print configuration parameters."""
    args = parse_args()
    config = ConfigParser(interpolation=ExtendedInterpolation()
                          if args.extended else BasicInterpolation())

    try:
        config.read(args.files)
        pairs = get_pairs(args, config)
    except (configparser.Error, ValueError) as error:
        sys.exit('{0}: {1}: {2}'.format(os.path.basename(sys.argv[0]),
                                        ' '.join(args.files),
                                        ' '.join(str(error).split())))

    for pair in pairs:
        print(pair)


def parse_args():
    """Parse script arguments."""
    description = 'Print application configuration parameters'
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('--extended',
                        action='store_true')
    parser.add_argument('files',
                        metavar='FILES',
                        nargs='*',
                        help='read from files FILES')
    parser.add_argument('--prefix',
                        metavar='PREFIX',
                        nargs='?',
                        help='prepend string PREFIX')
    parser.add_argument('--sections',
                        metavar='SECTIONS',
                        nargs='*',
                        help='read sections SECTIONS')
    return parser.parse_args()


if __name__ == '__main__':
    main()
