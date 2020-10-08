# -*- Mode: Shell-script -*-

# restapi-functions.sh: Python RESTful API functions
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

APPLE_URL=http://www.apple.com/DTDs/PropertyList-1.0.dtd

WAIT_DEFAULT=5
WAIT_RESTART=10
WAIT_SIGNAL=10

abort_insufficient_permissions() {
    cat <<-EOF >&2
	$0: Write access required to update file or directory: $1.
	$0: Insufficient access to complete the requested operation.
	$0: Please try the operation again as a privileged user.
	EOF
    exit 1
}

check_permissions() (
    for node; do
	check_permissions_single "$node"
    done
)

check_permissions_single() {
    if [ -w "$1" ]; then
	return 0
    elif [ -e "$1" ]; then
	abort_insufficient_permissions "$1"
    else
	check_permissions_single "$(dirname "$1")"
    fi
}

control_app() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "${kernel_name=$(uname -s)}" in
	(Darwin)
	    control_app_via_launchd $1
	    ;;
	(*)
	    control_app_via_symlinks $1
	    ;;
    esac
}

control_app_via_launchctl() (
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]

    case $1 in
	(load)
	    $2 $3

	    if [ $dryrun = true ]; then
		check_permissions $3
	    else
		launchctl load $3
	    fi
	    ;;
	(unload)
	    if [ $dryrun = true ]; then
		check_permissions $3
	    elif [ -e $3 ]; then
		launchctl unload $3
	    fi

	    $2 $3
	    ;;
    esac
)

control_app_via_launchd() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    target=$(get_launch_agent_target)

    case $1 in
	(disable)
	    if [ "$(is_uwsgi_service)" = true -a -e $target ]; then
		control_app_via_launchctl unload remove_files $target
	    fi
	    ;;
	(enable)
	    if [ "$(is_uwsgi_service)" = true -a ! -e $target ]; then
		control_app_via_launchctl load generate_launch_agent $target
	    fi
	    ;;
	(stop)
	    if [ $dryrun = false ]; then
		signal_app $WAIT_SIGNAL INT TERM KILL || true
	    fi
	    ;;
    esac
}

control_app_via_symlinks() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case $1 in
	(disable)
	    remove_files $(get_symlinks)
	    ;;
	(enable)
	    create_symlinks $APP_CONFIG ${UWSGI_APPDIRS-}
	    ;;
	(stop)
	    if [ $dryrun = false ]; then
		signal_app $WAIT_SIGNAL INT TERM KILL || true
	    fi
	    ;;
    esac
}

control_service() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    case "${kernel_name=$(uname -s)}" in
	(Darwin)
	    :
	    ;;
	(*)
	    control_service_via_systemd $1 $2
	    ;;
    esac
}

control_service_via_systemd() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    if [ $dryrun = true ]; then
	return 0
    fi

    case $1 in
	(enable|disable|restart)
	    systemctl $1 $2
	    ;;
    esac
}

generate_launch_agent() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $dryrun = false ]; then
	create_tmpfile
	xmlfile=$tmpfile
	cat <<-EOF >$xmlfile
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "$APPLE_URL">
	<plist version="1.0">
	  <dict>
	    <key>Label</key>
	    <string>local.$APP_NAME</string>
	    <key>RunAtLoad</key>
	    <true/>
	    <key>KeepAlive</key>
	    <true/>
	    <key>ProgramArguments</key>
	    <array>
	        <string>$(get_uwsgi_binary_path)</string>
	        <string>--ini</string>
	        <string>$APP_CONFIG</string>
	    </array>
	    <key>WorkingDirectory</key>
	    <string>$APP_VARDIR</string>
	  </dict>
	</plist>
	EOF
    else
	xmlfile=
    fi

    install_file 644 "$xmlfile" $1
)

get_app_status() {
    if is_app_installed; then
	if is_app_running; then
	    printf "%s\n" running
	else
	    printf "%s\n" stopped
	fi
    else
	printf "%s\n" uninstalled
    fi
}

get_awk_command() (
    for awk in /usr/gnu/bin/awk /usr/bin/gawk /usr/bin/awk; do
	if [ -x $awk ]; then
	    printf "%s\n" "$awk"
	    return 0
	fi
    done

    return 1
)

get_launch_agent_label() {
    printf "%s\n" "local.$APP_NAME"
}

get_launch_agent_target() {
    printf "%s\n" "$HOME/Library/LaunchAgents/$(get_launch_agent_label).plist"
}

get_service_status() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ "$(is_uwsgi_service)" = false ]; then
	return 0
    elif ! is_system_running; then
	return 0
    elif is_service_loaded $1; then
	if is_service_running $1; then
	    printf "%s\n" running
	else
	    printf "%s\n" stopped
	fi
    else
	printf "%s\n" uninstalled
    fi
}

get_symlinks() (
    if [ -z "${UWSGI_APPDIRS-}" ]; then
	return 0
    elif [ -z "${UWSGI_ETCDIR-}" ]; then
	return 0
    elif [ ! -d $UWSGI_ETCDIR ]; then
	return 0
    else
	for dir in $UWSGI_APPDIRS; do
	    printf "%s\n" $UWSGI_ETCDIR/$dir/$APP_NAME.ini
	done
    fi
)

install_file() {
    assert [ $# -eq 3 ]
    assert [ -n "$3" ]

    if [ $dryrun = true ]; then
	check_permissions_single $3
    else
	assert [ -n "$1" ]
	assert [ -n "$2" ]
	assert [ -r $2 ]

	if is_tmpfile $2; then
	    printf "Generating file %s\n" "$3"
	else
	    printf "Installing file %s as %s\n" "$2" "$3"
	fi

	install -d -m 755 "$(dirname "$3")"
	install -m $1 $2 $3
    fi
}

is_app_installed() {
    test -e $APP_CONFIG
}

is_app_running() {
    if [ -r $APP_PIDFILE ]; then
	pid=$(cat $APP_PIDFILE)

	if [ -n "$pid" ]; then
	    if ps -p $pid >/dev/null; then
		return 0
	    else
		pid=
	    fi
	fi
    else
	pid=
    fi

    return 1
}

is_service_active() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if ! is_system_running || ! is_service_loaded uwsgi; then
	return 1
    fi

    active=$(systemctl show --property=ActiveState $1)

    case "${active#ActiveState=}" in
	(active)
	    return 0
	    ;;
	(*)
	    return 1
	    ;;
    esac
}

is_service_loaded() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if ! is_system_running; then
	return 1
    fi

    loaded=$(systemctl show --property=LoadState $1)

    case "${loaded#LoadState=}" in
	(loaded)
	    return 0
	    ;;
	(*)
	    return 1
	    ;;
    esac
}

is_service_running() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if ! is_system_running || ! is_service_loaded $1; then
	return 1
    fi

    if ! is_service_active $1; then
	return 1
    fi

    state=$(systemctl show --property=SubState $1)

    case "${state#SubState=}" in
	(exited|running)
	    return 0
	    ;;
	(*)
	    return 1
	    ;;
    esac
}

is_system_running() {
    running=$(systemctl is-system-running)

    case "$running" in
	(degraded|running|starting)
	    return 0
	    ;;
	(*)
	    return 1
	    ;;
    esac
}

is_tmpfile() {
    printf "%s\n" ${tmpfiles-} | grep -q $1
}

print_elapsed_time() {
    if [ $elapsed -eq 0 ]; then
	return 0
    fi

    printf "Service %s %s in %d seconds\n" "$APP_NAME" "$1" "$elapsed"
}

print_table() {
    awk=$(get_awk_command)

    if [ -z "$awk" ]; then
	abort "No suitable awk command found\n"
    fi

    $awk -f "$(which print-table)" \
	 -v border="${1-1}" \
	 -v header="${2-}" \
	 -v width="${COLUMNS-80}"
}

remove_files() {
    if [ $# -eq 0 ]; then
	return 0
    fi

    if [ $dryrun = true ]; then
	check_permissions "$@"
    else
	printf "Removing %s\n" $(printf "%s\n" "$@" | sort -u)
	/bin/rm -rf "$@"
    fi
}

signal_process() {
    assert [ $# -ge 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 -a $3 -le 60 ]
    printf "Sending SIG%s to process (PID: %s)\n" $1 $2

    case $1 in
	(HUP)
	    signal_process_and_wait "$@"
	    ;;
	(*)
	    signal_process_and_poll "$@"
	    ;;
    esac
}

signal_process_and_poll() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 -a $3 -le 60 ]
    i=0

    while kill -s $1 $2 && [ $i -lt $3 ]; do
	if [ $i -eq 0 ]; then
	    printf "%s\n" "Waiting for process to exit"
	fi

	sleep 1
	i=$((i + 1))
    done

    elapsed=$((elapsed + i))
    test $i -lt $3
}

signal_process_and_wait() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 -a $3 -le 60 ]

    if kill -s $1 $2; then
	printf "Waiting for process to handle SIG%s\n" "$1"
	sleep $3
	elapsed=$((elapsed + $3))
	return 0
    fi

    return 1
}

wait_for_timeout() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $1 -gt 0 ]; then
	sleep $1
	printf "%s\n" "$1"
    else
	printf "%s\n" 0
    fi
}
