#!/usr/bin/env python3

# test-python-version: test Python interpreter version string
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

"""Check given Python version string against Pipfile requirement."""

from __future__ import print_function
import argparse
import re
import sys

try:
    from configparser import ConfigParser, NoOptionError, NoSectionError
except ImportError:
    from ConfigParser import ConfigParser, NoOptionError, NoSectionError

INPUT = 'Pipfile'

PYTHON_VERSION_LEN = 3
PYTHON_VERSION_PATH = ['requires', 'python_version']
PYTHON_VERSION_REGEX = r'^(\d{1,3}(\.\d{1,3}){0,2})(\+|rc\d)?$'

QUOTED_REGEX = r'^"([^"]+)"$'


class ParseError(Exception):
    """Represent error parsing text."""


def get_difference(str_1, str_2):
    """Compute difference between Python semantic version strings."""
    return get_scalar_version(str_1) - get_scalar_version(str_2)


def get_minimum_version():
    """Return the minimum Python version requirement."""
    config = ConfigParser()
    config.read(INPUT)

    try:
        return parse_version(unquote(config.get(PYTHON_VERSION_PATH[0],
                                                PYTHON_VERSION_PATH[1])))
    except (NoOptionError, NoSectionError, ParseError) as exception:
        raise ParseError("{}: Unable to parse: {}".format(INPUT, exception))


def get_scalar_version(version_str):
    """Return the integer equivalent of a semantic version string."""
    result = 0
    version_ints = version_str.split('.')

    for i in range(PYTHON_VERSION_LEN):
        result *= 1000
        result += int(version_ints[i]) if i < len(version_ints) else 0

    return result


def get_versions(version, delimiter):
    """Return version numbers in order of increasing generality."""
    parts = version.split('.')
    return [delimiter.join(parts[:n]) for n in range(len(parts), 0, -1)]


def parse_args():
    """Parse script arguments."""
    description = 'Check Python interpreter version against Pipfile'
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('--delimiter',
                        const='_',
                        default='.',
                        metavar='TEXT',
                        nargs='?',
                        help='use TEXT to delimit parts of version in output')
    parser.add_argument('version',
                        metavar='VERSION',
                        nargs='?',
                        help='check Python version VERSION')
    return parser.parse_args()


def parse_version(version_str):
    """Parse quoted Python semantic version string."""
    try:
        return re.search(PYTHON_VERSION_REGEX, version_str).group(1)
    except AttributeError as exception:
        raise ParseError("Invalid quoted string '{}': {}".format(version_str,
                                                                 exception))


def print_difference(difference, actual, minimum):
    """Print difference between Python semantic version strings."""
    message = "Python {} interpreter {} {} requirement (>= {})"
    output = sys.stdout if difference >= 0 else sys.stderr
    verb = "meets" if difference >= 0 else "does not meet"
    print(message.format(actual, verb, INPUT, minimum), file=output)


def print_versions(version_str, delimiter):
    """Print Python semantic version strings using a given delimiter."""
    print(' '.join(get_versions(version_str, delimiter)))


def unquote(version_str):
    """Parse a quoted string, stripping quotation marks."""
    try:
        return re.search(QUOTED_REGEX, version_str).group(1)
    except AttributeError as exception:
        raise ParseError("Invalid quoted string '{}': {}".format(version_str,
                                                                 exception))


def main():
    """Main program of script."""
    args = parse_args()

    try:
        actual = parse_version(args.version) if args.version else None
        minimum = get_minimum_version()
    except ParseError as exception:
        print("{}: {}".format(sys.argv[0], exception), file=sys.stderr)
        sys.exit(2)
    else:
        if actual:
            difference = get_difference(actual, minimum)
            print_difference(difference, actual, minimum)
            sys.exit(0 if difference >= 0 else 1)
        else:
            print_versions(minimum, args.delimiter)
            sys.exit(0)


if __name__ == '__main__':
    main()
