# -*- Mode: Shell-script -*-

# restapi-parameters.sh: Python RESTful API parameters
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

APP_VARS="APP_DIR APP_GID APP_LOGFILE APP_PIDFILE APP_MODULE \
APP_PLUGIN APP_PORT APP_UID APP_VARDIR APP_VENVDIR VENV_DIRECTORY"

AWK_FORMAT='NR == 1 || $%d == binary {print $0}\n'
PLUGIN_FORMAT="python%s_plugin.so\n"

UWSGI_BRANCH=uwsgi-2.0
UWSGI_URL=https://github.com/unbit/uwsgi.git

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
}

awk_uwsgi() {
    assert [ $# -eq 1 ]
    awk "$(printf "$AWK_FORMAT" $PS_COLUMN)" binary="$1"
}

configure_all() {
    configure_baseline
    configure_defaults
}

configure_baseline() {
    eval $(get-os-release -x)
    eval $(run-python "$script_dir/get-configuration" app.ini)

    case "$kernel_name" in
	(CYGWIN_NT-*)
	    case "$VERSION_ID" in
		(10.0)
		    configure_windows
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(Linux|GNU)
	    configure_gnu

	    case "$ID" in
		(centos)
		    case "$VERSION_ID" in
			(8)
			    configure_linux_centos_8
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(debian|raspbian)
		    case "$VERSION_ID" in
			(10)
			    configure_linux_debian_10
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(fedora)
		    case "$VERSION_ID" in
			(32)
			    configure_linux_fedora_32
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(opensuse-leap)
		    case "$VERSION_ID" in
			(15.1)
			    configure_linux_opensuse_lp_15
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(opensuse-tumbleweed)
		    case "$VERSION_ID" in
			(2019*)
			    configure_linux_opensuse_tw
			    ;;
			(2020*)
			    configure_linux_opensuse_tw
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(rhel|ol)
		    case "$VERSION_ID" in
			(8.*)
			    configure_linux_redhat_8
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(ubuntu)
		    case "$VERSION_ID" in
			(18.04)
			    configure_linux_ubuntu_18_04
			    ;;
			(19.10)
			    configure_linux_ubuntu_19_10
			    ;;
			(20.04)
			    configure_linux_ubuntu_20_04
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    configure_unix_bsd

	    case "$VERSION_ID" in
		(10.14.*)
		    configure_unix_macos
		    ;;
		(10.15.*)
		    configure_unix_macos
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(FreeBSD)
	    configure_unix_bsd

	    case "$VERSION_ID" in
		(11.3-*)
		    configure_unix_freebsd_11
		    ;;
		(12.1-*)
		    configure_unix_freebsd_12
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(NetBSD)
	    configure_unix_bsd

	    case "$VERSION_ID" in
		(8.1)
		    configure_unix_netbsd
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(SunOS)
	    configure_unix

	    case $ID in
		(illumos)
		    case "$VERSION_ID" in
			(2019.10)
			    configure_unix_illumos
			    ;;
			(2020.04)
			    configure_unix_illumos
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(solaris)
		    case "$VERSION_ID" in
			(11.4)
			    configure_unix_solaris
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac

    # Set application group and user accounts

    if [ -z "${APP_GID-}" ]; then
	APP_GID=uwsgi
    fi

    if [ -z "${APP_UID-}" ]; then
	APP_UID=uwsgi
    fi

    # Set application directories from APP_NAME and APP_PREFIX
    APP_DIR=${APP_PREFIX-}/opt/$APP_NAME
    APP_ETCDIR=${APP_PREFIX-}/etc/opt/$APP_NAME

    if [ -z "${APP_VARDIR-}" ]; then
	APP_VARDIR=${APP_PREFIX-}/var/opt/$APP_NAME
    fi

    # Set additional app file and directory parameters

    APP_CONFIG=$APP_ETCDIR/app.ini

    if [ -z "${APP_LOGDIR-}" ]; then
	APP_LOGDIR=$APP_VARDIR
    fi

    if [ -z "${APP_RUNDIR-}" ]; then
	APP_RUNDIR=$APP_VARDIR
    fi

    # Set additional file parameters from app directories

    if [ -z "${APP_LOGFILE-}" ]; then
	APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    fi

    if [ -z "${APP_PIDFILE-}" ]; then
	APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    fi

    # Set uWSGI-related parameters

    if [ -z "${UWSGI_BUILDCONF-}" ]; then
	UWSGI_BUILDCONF=core
    fi

    if [ -z "${UWSGI_ORIGIN-}" ]; then
	UWSGI_ORIGIN=distro
    fi

    # Set uWSGI directory prefix
    if [ -z "${UWSGI_PREFIX-}" ]; then
	UWSGI_PREFIX=
    fi

    if [ -z "${UWSGI_ETCDIR-}" ]; then
	if [ "$(is_uwsgi_service)" = true ]; then
	    UWSGI_ETCDIR=${UWSGI_PREFIX:-}/etc/uwsgi
	fi
    fi

    if [ -z "${UWSGI_BINARY_DIR-}" ]; then
	UWSGI_BINARY_DIR=${UWSGI_PREFIX:-/usr}/bin
    fi

    if [ -z "${UWSGI_BINARY_NAME-}" ]; then
	UWSGI_BINARY_NAME=uwsgi
    fi
}

configure_defaults() {
    # Set Python-related parameters

    if [ -z "${SYSTEM_PYTHON-}" -o -z "${SYSTEM_PYTHON_VERSION-}" ]; then
	if [ -n "${SYSTEM_PYTHON-}" ]; then
	    SYSTEM_PYTHON_VERSION="$(get_python_version $SYSTEM_PYTHON)"
	else
	    python_triple=$(find_system_python)
	    version_pair="${python_triple#* }"
	    SYSTEM_PYTHON="${python_triple%% *}"
	    SYSTEM_PYTHON_VERSION="${version_pair#* }"
	fi

	if ! check_python $SYSTEM_PYTHON $SYSTEM_PYTHON_VERSION; then
	    abort "%s\n" "No suitable Python interpreter found"
	fi
    fi

    # Set uWSGI-related parameters

    if [ -z "${UWSGI_HAS_PLUGIN-}" ]; then
	if [ "$UWSGI_BUILDCONF" = pyonly ]; then
	    UWSGI_HAS_PLUGIN=false
	elif [ "$UWSGI_ORIGIN" = pkgsrc ]; then
	    UWSGI_HAS_PLUGIN=false
	else
	    UWSGI_HAS_PLUGIN=true
	fi
    fi

    if [ -z "${UWSGI_BINARY_DIR-}" ]; then
	UWSGI_BINARY_DIR=${UWSGI_PREFIX:-/usr}/bin
    fi

    if [ -z "${UWSGI_BINARY_NAME-}" ]; then
	UWSGI_BINARY_NAME=uwsgi
    fi

    if [ -z "${UWSGI_PLUGIN_DIR-}" ]; then
	UWSGI_PLUGIN_DIR=${UWSGI_PREFIX:-/usr}/lib/uwsgi/plugins
    fi

    if [ -z "${UWSGI_PLUGIN_NAME-}" ]; then
	UWSGI_PLUGIN_NAME=$(find_uwsgi_plugin)
    fi

    # Set app plugin from uWSGI plugin filename
    if [ -z "${APP_PLUGIN-}" -a -n "${UWSGI_PLUGIN_NAME-}" ]; then
	APP_PLUGIN=${UWSGI_PLUGIN_NAME%_plugin.so}
    fi

    # Set additional file parameters from app directories

    if [ -z "${APP_PIDFILE-}" ]; then
	APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    fi

    if [ -z "${APP_SOCKET-}" ]; then
	APP_SOCKET=
    fi

    if [ -z "${APP_VENVDIR-}" ]; then
	APP_VENVDIR=$APP_DIR/${VENV_DIRECTORY-venv}
    fi
}

configure_from_source() {
    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set other uWSGI parameters

    if [ -z "${UWSGI_BUILDCONF-}" ]; then
	UWSGI_BUILDCONF=pyonly
    fi

    UWSGI_ORIGIN=source
}

configure_gnu() {
    # Set ps command format and command column
    PS_COLUMN=10
    PS_FORMAT=pid,ppid,user,tt,lstart,command
}

configure_linux_centos_8() {
    configure_linux_redhat

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/local/bin

    # Set other uWSGI parameters
    UWSGI_HAS_PLUGIN=false
    UWSGI_ORIGIN=pypi
}

configure_linux_debian() {
    # Set application group and user accounts
    APP_GID=www-data
    APP_UID=www-data

    # Set additional file/directory parameters
    APP_LOGDIR=/var/log/uwsgi/app
    APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME

    # Set additional parameters from app directories
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/socket

    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"
}

configure_linux_debian_10() {
    configure_linux_debian

    # Set system Python interpreter
    SYSTEM_PYTHON=/usr/bin/python3.7
    SYSTEM_PYTHON_VERSION=3.7.3
}

configure_linux_fedora() {
    # Set uWSGI configuration directory
    UWSGI_ETCDIR=/etc

    # Set uWSGI app configuration directory
    UWSGI_APPDIRS=uwsgi.d

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/sbin
    UWSGI_PLUGIN_DIR=/usr/lib64/uwsgi
}

configure_linux_fedora_32() {
    configure_linux_fedora
}

configure_linux_opensuse() {
    # Set application group and user accounts
    APP_GID=nogroup
    APP_UID=nobody

    # Set uWSGI configuration directories
    UWSGI_APPDIRS=vassals

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/sbin
    UWSGI_PLUGIN_DIR=/usr/lib64/uwsgi
}

configure_linux_opensuse_lp_15() {
    configure_linux_opensuse

    # Set system Python interpreter
    SYSTEM_PYTHON=/usr/bin/python3.6
    SYSTEM_PYTHON_VERSION=3.6.5
}

configure_linux_opensuse_tw() {
    configure_linux_opensuse

    # Set system Python interpreter
    SYSTEM_PYTHON=/usr/bin/python3
}

configure_linux_redhat() {
    # Set application group and user accounts
    APP_GID=nobody
    APP_UID=nobody
}

configure_linux_redhat_8() {
    configure_linux_redhat

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/local/bin

    # Set uWSGI parameters
    UWSGI_HAS_PLUGIN=false
    UWSGI_ORIGIN=pypi
}

configure_linux_ubuntu_18_04() {
    configure_linux_debian

    # Set system Python interpreter
    SYSTEM_PYTHON=/usr/bin/python3.6
}

configure_linux_ubuntu_19_10() {
    configure_linux_debian

    # Set system Python interpreter
    SYSTEM_PYTHON=/usr/bin/python3.7
}

configure_linux_ubuntu_20_04() {
    configure_linux_debian

    # Set system Python interpreter
    SYSTEM_PYTHON=/usr/bin/python3.8
}

configure_unix() {
    # Set ps command format and column number
    PS_COLUMN=6
    PS_FORMAT=pid,ppid,user,tty,stime,args
}

configure_unix_bsd() {
    # Set ps command format and column number
    PS_COLUMN=10
    PS_FORMAT=pid,ppid,user,tt,lstart,command
}

configure_unix_freebsd() {
    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set other uWSGI parameters
    UWSGI_HAS_PLUGIN=false
}

configure_unix_freebsd_11() {
    configure_unix_freebsd
}

configure_unix_freebsd_12() {
    configure_unix_freebsd
}

configure_unix_illumos() {
    # Set application group and user accounts
    APP_GID=webservd
    APP_UID=webservd

    # Set system Python interpreter
    SYSTEM_PYTHON=/opt/local/bin/python3.7

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/opt/local

    # Set uWSGI binary file
    UWSGI_BINARY_NAME=uwsgi-3.7

    # Set other uWSGI parameters
    UWSGI_ORIGIN=pkgsrc
}

configure_unix_macos() {
    # Set application group and user accounts
    APP_GID=_www
    APP_UID=_www

    # Set application prefix
    APP_PREFIX=/usr/local

    # Set system Python interpreter
    SYSTEM_PYTHON=/usr/local/bin/python3

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/local/bin
    UWSGI_PLUGIN_DIR=$(get_brew_cellar uwsgi)/libexec/uwsgi

    # Set other uWSGI parameters
    UWSGI_ORIGIN=homebrew
}

configure_unix_netbsd() {
    # Set application group and user accounts
    APP_GID=www
    APP_UID=www

    # Set system Python interpreter
    SYSTEM_PYTHON=/usr/pkg/bin/python3.7

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/pkg

    # Set uWSGI binary file
    UWSGI_BINARY_NAME=uwsgi-3.7

    # Set other uWSGI parameters
    UWSGI_ORIGIN=pkgsrc
}

configure_unix_solaris() {
    # Set application group and user accounts
    APP_GID=webservd
    APP_UID=webservd

    # Set uWSGI parameters
    configure_from_source
}

configure_windows() {
    # Set ps command format and command column
    PS_COLUMN=6

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/bin

    # Set uWSGI parameters
    UWSGI_HAS_PLUGIN=false
    UWSGI_ORIGIN=pypi
}

find_available_plugins() {
    printf $PLUGIN_FORMAT $(find_system_pythons | awk '{print $2}' | tr -d .)
}

find_installed_plugins() {
    cd $UWSGI_PLUGIN_DIR 2>/dev/null && ls "$@" 2>/dev/null || true
}

find_plugins() (
    available_plugins="$(find_available_plugins)"
    installed_plugins="$(find_installed_plugins $available_plugins)"

    if [ -n "$installed_plugins" ]; then
	printf "%s\n" $installed_plugins
    else
	printf "%s\n" $available_plugins
    fi
)

find_uwsgi_plugin() {
    if [ $UWSGI_HAS_PLUGIN = true ]; then
	find_plugins | head -n 1
    fi
}

get_brew_cellar() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    brew info $1 | awk 'NR == 4 {print $1}'
}

get_service_processes() {
    ps_uwsgi $(get_service_users) | awk_uwsgi $(get_uwsgi_binary_path)
}

get_service_users() {
    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(opensuse-*)
		    printf "%s\n" $APP_UID,root
		    ;;
		(*)
		    printf "%s\n" $APP_UID
		    ;;
	    esac
	    ;;
	(*)
	    printf "%s\n" $APP_UID
	    ;;
    esac
}

get_uwsgi_binary_path() {
    printf "%s/%s\n" "$UWSGI_BINARY_DIR" "$UWSGI_BINARY_NAME"
}

get_uwsgi_plugin_path() {
    if [ -n "${UWSGI_PLUGIN_DIR-}" -a -n "${UWSGI_PLUGIN_NAME-}" ]; then
	printf "%s/%s\n" "$UWSGI_PLUGIN_DIR" "$UWSGI_PLUGIN_NAME"
    fi
}

get_uwsgi_version() {
    uwsgi=$(get_uwsgi_binary_path)

    if [ -n "$uwsgi" ] && [ -x $uwsgi ]; then
	$uwsgi --version
    else
	printf "%s\n" "<none>"
    fi
}

is_uwsgi_packaged() {
    case "$UWSGI_ORIGIN" in
	(distro)
 	    is_packaged=true
	    ;;
	(homebrew)
	    is_packaged=true
	    ;;
	(opencsw)
	    is_packaged=true
	    ;;
	(pkgsrc)
	    is_packaged=true
	    ;;
	(pypi)
	    is_packaged=true
	    ;;
	(source)
	    is_packaged=false
	    ;;
	(*)
	    is_packaged=false
	    ;;
    esac

    printf "%s\n" "$is_packaged"
}

is_uwsgi_service() {
    case "$kernel_name" in
	(GNU|FreeBSD)
	    is_service=false
	    ;;
	(*)
	    case "$UWSGI_ORIGIN" in
		(distro)
		    is_service=true
		    ;;
		(homebrew)
		    is_service=true
		    ;;
		(opencsw)
		    is_service=false
		    ;;
		(pkgsrc)
		    is_service=false
		    ;;
		(pypi)
		    is_service=false
		    ;;
		(source)
		    is_service=false
		    ;;
		(*)
		    is_service=false
		    ;;
	    esac
	    ;;
    esac

    printf "%s\n" "$is_service"
}

print_app_log_file() {
    assert [ $# -le 1 ]

    if [ -r $APP_LOGFILE ]; then
	rows="${ROWS-10}"
	header="SERVICE LOG $APP_LOGFILE (last $rows lines)"
	tail -n "$rows" $APP_LOGFILE | print_table "${1-1}" "$header"
    elif [ -e $APP_LOGFILE ]; then
	printf "%s: No read permission\n" "$APP_LOGFILE" >&2
    fi
}

print_app_processes() {
    get_service_processes | print_table ${1-} ""
}

ps_uwsgi() {
    case "$kernel_name" in
	(CYGWIN_NT-*)
	    ps -ef
	    ;;
	(*)
	    ps -U "$1" -o $PS_FORMAT
	    ;;
    esac
}

signal_app() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    assert [ $1 -gt 0 ]
    wait=$1
    shift
    elapsed=0

    if [ -z "${pid-}" ]; then
	if [ -r $APP_PIDFILE ]; then
	    pid=$(cat $APP_PIDFILE 2>/dev/null)
	else
	    pid=
	fi
    fi

    if [ -z "$pid" ]; then
	return 1
    fi

    for signal in "$@"; do
	if signal_process "$signal" "$pid" "$wait"; then
	    return 0
	fi
    done

    return 1
}

signal_app_restart() {
    elapsed=0

    if is_app_running && signal_app $WAIT_SIGNAL HUP; then
	elapsed=$((elapsed + $(wait_for_timeout $((WAIT_RESTART - elapsed)))))
	restart_requested=true
    else
	restart_requested=false
    fi
}

validate_parameters_postinstallation() {
    if [ ! -d $APP_ETCDIR ]; then
	abort "%s: %s: No such configuration directory\n" "$0" "$APP_ETCDIR"
    elif [ ! -e $APP_CONFIG ]; then
	abort "%s: %s: No such configuration file\n" "$0" "$APP_CONFIG"
    elif [ ! -r $APP_CONFIG ]; then
	abort "%s: %s: No read permission\n" "$0" "$APP_CONFIG"
    elif [ ! -d $APP_DIR ]; then
	abort "%s: %s: No such program directory\n" "$0" "$APP_DIR"
    elif [ ! -d $APP_VARDIR ]; then
	abort "%s: %s: No such working directory\n" "$0" "$APP_VARDIR"
    elif [ ! -d $APP_LOGDIR ]; then
	abort "%s: %s: No such log directory\n" "$0" "$APP_LOGDIR"
    elif [ ! -d $APP_RUNDIR ]; then
	abort "%s: %s: No such run directory\n" "$0" "$APP_RUNDIR"
    elif [ -e $APP_LOGFILE -a ! -w $APP_LOGFILE ]; then
	abort_insufficient_permissions "$APP_LOGFILE"
    elif [ -e $APP_PIDFILE -a ! -w $APP_PIDFILE ]; then
	abort_insufficient_permissions "$APP_PIDFILE"
    fi
}

validate_parameters_preinstallation() {
    binary=$(get_uwsgi_binary_path)
    plugin=$(get_uwsgi_plugin_path)

    if [ ! -e $binary ]; then
	abort "%s: %s: No such binary file\n" "$0" "$binary"
    elif [ ! -x $binary ]; then
	abort "%s: %s: No execute permission\n" "$0" "$binary"
    elif ! $binary --version >/dev/null 2>&1; then
	abort "%s: %s: Unable to query version\n" "$0" "$binary"
    elif [ $UWSGI_HAS_PLUGIN = true ]; then
	if [ ! -e $plugin ]; then
	    abort "%s: %s: No such plugin file\n" "$0" "$plugin"
	elif [ ! -r $plugin ]; then
	    abort "%s: %s: No read permission\n" "$0" "$plugin"
	fi
    fi
}

wait_for_service() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    i=0

    if [ $1 -gt 0 ]; then
	while [ ! -e $APP_PIDFILE -a $i -lt $1 ]; do
	    sleep 1
	    i=$((i + 1))
	done
    fi

    if [ $i -ge $1 ]; then
	printf "Service failed to start within %s seconds\n" $1 >&2
    fi

    printf "%s\n" "$i"
}
