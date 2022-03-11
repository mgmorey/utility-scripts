# -*- Mode: Shell-script -*-

# config-functions.sh: define configuration shell functions
# Copyright (C) 2022  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

LOCAL_PREFIX=/usr/local
OPENCSW_PREFIX=/opt/csw

clean_build() {
    if [ -r Makefile ]; then
	$make distclean
    fi
}

configure_compiler() {
    if [ -n "${1-}" ]; then
	cc="$(get_compiler $1)"
	cflags="$(get_compiler_flags $1)"
    fi

    if [ -n "${2-}" ]; then
	cppflags="$(get_include_flags "$2")"
    fi

    if [ -n "${3-}" ]; then
	ldflags="$(get_linker_flags "$3")"
    fi

    pkg_config_path="$(get_pkg_config_path)"
}

configure_platform() {
    make=make
    make_options=$(get_make_options)

    for id in $ID $ID_LIKE; do
	case "$id" in
	    (rhel|ol)
		case "$VERSION_ID" in
		   (8.*)
			configure_platform_linux_redhat_8
			break
			;;
		esac
		;;
	    (illumos)
		configure_platform_unix_illumos
		break
		;;
	    (netbsd)
		configure_platform_bsd_netbsd
		break
		;;
	    (solaris)
		configure_platform_unix_solaris
		break
		;;
	esac
    done

    if [ -n "${cc-}" ] && [ ! -x $cc ]; then
	abort '%s: %s: No such compiler\n' "$script" "$cc"
    fi
}

configure_platform_bsd_netbsd() {
    make=gmake
    include_prefix /usr/pkg
    configure_compiler "/usr/bin/gcc" "${incdirs-}" "${libdirs-}"
}

configure_platform_linux_redhat_8() {
    include_prefix $LOCAL_PREFIX
    configure_compiler "/usr/bin/gcc" "${incdirs-}" "${libdirs-}"
}

configure_platform_unix_illumos() {
    include_prefix $LOCAL_PREFIX
    configure_compiler "/usr/bin/gcc -m64" "${incdirs-}" "${libdirs-}"
}

configure_platform_unix_solaris() {
    include_prefix $OPENCSW_PREFIX amd64
    configure_compiler "/opt/developerstudio12.6/bin/cc -m64" \
		       "${incdirs-}" \
		       "${libdirs-}"
}

extract_files() {
    if [ ! -d "$src_dir" ]; then
	cd "$(dirname "$src_dir")"

	case "$pathname" in
	    (*.tar.bz2)
		bzip2 -dc "$pathname" | tar -xvf -
		;;
	    (*.tar.gz)
		gzip -dc "$pathname" | tar -xvf -
		;;
	    (*.tar.xz)
		xz -dc "$pathname" | tar -xvf -
		;;
	    (*.tgz)
		gzip -dc "$pathname" | tar -xvf -
		;;
	    (*.zip)
		unzip "$pathname"
		;;
	esac
    fi
}

get_compiler() {
    printf '%s\n' "$1"
}

get_compiler_flags() {
    shift
    printf '%s\n' "$*"
}

get_configure_command() {
    cflags="${CFLAGS+$CFLAGS }${cflags-}"
    cppflags="${CPPFLAGS+$CPPFLAGS }${cppflags-}"
    cxxflags="${CXXFLAGS+$CXXFLAGS }${cxxflags-}"
    ldflags="${LDFLAGS+$LDFLAGS }${ldflags-}"
    options=$(get_configure_options)
    printf '%s' "$1/${2-configure}"

    if [ -n "${options-}" ]; then
	printf ' %s' "$options"
    fi

    if [ -n "${cc-}" ]; then
	printf ' CC=\"%s\"' "$cc"
    fi

    if [ -n "${cflags-}" ]; then
	printf ' CFLAGS=\"%s\"' "$cflags"
    fi

    if [ -n "${cppflags-}" ]; then
	printf ' CPPFLAGS=\"%s\"' "$cppflags"
    fi

    if [ -n "${cxx-}" ]; then
	printf ' CXX=\"%s\"' "$cxx"
    fi

    if [ -n "${cxxflags-}" ]; then
	printf ' CXXFLAGS=\"%s\"' "$cxxflags"
    fi

    if [ -n "${ldflags-}" ]; then
	printf ' LDFLAGS=\"%s\"' "$ldflags"
    fi

    if [ -n "${pkg_config_path-}" ]; then
	printf ' PKG_CONFIG_PATH=\"%s\"' "$pkg_config_path"
    fi

    printf '\n'
}

get_include_flags() {
    assert [ $# -ge 1 ]
    printf -- "-I%s\n" "$@"
}

get_linker_flags() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    ldflags=

    for libdir; do
	case "$os_family" in
	    (gnu-*)
		ldflags="-Wl,--rpath=$libdir"
		;;
	    (unix)
		ldflags="-L$libdir -R$libdir"
		;;
	esac
    done

    if [ "${ldflags-}" ]; then
	printf '%s\n' "$ldflags"
    fi
}

get_make_options() {
    ncpu=$(lscpu 2>/dev/null | awk '$1 == "CPU(s):" {print $2}' || true)

    if [ -n "$ncpu" ]; then
	printf '%s\n' -j "$ncpu"
    fi
}

get_pkg_config_path() {
    for pkgdir in ${pkgdirs-}; do
	pkg_config_path=${pkg_config_path+$pkg_config_path:}$pkgdir
    done

    if [ "${pkg_config_path-}" ]; then
	printf '%s\n' "$pkg_config_path"
    fi
}

include_prefix() {
    assert [ $# -ge 1 -a $# -le 2 ]
    assert [ -n "$1" ]
    incdir="$1/include"
    libdir="$1/lib${2+/$2}"
    incdirs="${incdirs+$incdirs }$incdir"
    libdirs="${libdirs+$libdirs }$libdir"

    if [ -d "$libdir/pkgconfig" ]; then
	pkgdirs="${pkgdirs+$pkgdirs }$libdir/pkgconfig"
    fi
}

install_dependencies() {
    case "$ID" in
	(windows)
	    case "$kernel_name" in
		(CYGWIN_NT)
		    return 0
		    ;;
	    esac
	    ;;
    esac

    packages="$(get_dependencies | sort -u)"
    pattern="$(get-packages -s pattern development)"
    install-packages ${pattern:+-p "$pattern" }$packages
}
