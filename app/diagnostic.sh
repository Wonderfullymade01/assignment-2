#!/usr/bin/env bash
# diagnostic.sh - Diagnostic CLI for Linux systems
# Usage: diagnostic <command> [arguments]
# Exit codes: 0 = success, 1 = operational/runtime failure, 2 = invalid command or input

set -u

PROG_NAME="diagnostic"

usage() {
    cat <<EOF
Usage: $PROG_NAME <command> [arguments]

Commands:
  system           Show Linux system information
  network <host>   Resolve and ping a host
  disk [path]      Show disk usage (default path: /)
  help             Show this help message

Exit codes:
  0  success
  1  operational/runtime failure
  2  invalid command or input
EOF
}

error() {
    echo "Error: $1" >&2
}

cmd_system() {
    if [[ $# -gt 0 ]]; then
        error "'system' takes no arguments"
        return 2
    fi

    if [[ ! -r /proc/uptime || ! -r /proc/meminfo ]]; then
        error "cannot read /proc system information"
        return 1
    fi

    local os="unknown"
    if [[ -r /etc/os-release ]]; then
        os=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    fi

    local up_seconds up_hours up_minutes
    up_seconds=$(cut -d. -f1 /proc/uptime)
    up_hours=$(( up_seconds / 3600 ))
    up_minutes=$(( (up_seconds % 3600) / 60 ))

    local cpu cores
    cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
    cores=$(nproc)

    local mem_total mem_avail mem_used
    mem_total=$(awk '/^MemTotal:/ {print int($2/1024)}' /proc/meminfo)
    mem_avail=$(awk '/^MemAvailable:/ {print int($2/1024)}' /proc/meminfo)
    mem_used=$(( mem_total - mem_avail ))

    echo "===== System Information ====="
    echo "Hostname:          $(hostname)"
    echo "Current user:      $(whoami)"
    echo "Date/time:         $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Operating system:  ${os:-unknown}"
    echo "Kernel version:    $(uname -r)"
    echo "Uptime:            ${up_hours}h ${up_minutes}m"
    echo "CPU:               ${cpu:-unknown} (${cores} cores)"
    echo "Memory:            ${mem_used} MB used / ${mem_total} MB total"
    echo "=============================="
}

cmd_network() {
    if [[ $# -lt 1 ]]; then
        error "missing host"
        echo "Usage: $PROG_NAME network <host>" >&2
        return 2
    fi
    if [[ $# -gt 1 ]]; then
        error "'network' takes exactly one host"
        return 2
    fi

    local host="$1"
    if [[ ${#host} -gt 253 || ! "$host" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
        error "invalid hostname or IP address '$host'"
        return 2
    fi

    echo "===== Network Check: $host ====="

    local ip
    ip=$(getent hosts "$host" | awk '{print $1; exit}')
    if [[ -z "$ip" ]]; then
        echo "Resolve:      FAILED (could not resolve '$host')"
        return 1
    fi
    echo "Resolved IP:  $ip"

    if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
        echo "Ping:         OK"
    else
        echo "Ping:         FAILED (no reply)"
        return 1
    fi
}

cmd_disk() {
    if [[ $# -gt 1 ]]; then
        error "'disk' takes at most one path"
        return 2
    fi

    local path="${1:-/}"
    if [[ ! -e "$path" ]]; then
        error "path '$path' does not exist"
        return 2
    fi

    echo "===== Disk Information: $path ====="
    if ! df -h "$path"; then
        error "could not read disk information for '$path'"
        return 1
    fi
}

main() {
    if [[ $# -lt 1 ]]; then
        error "no command given"
        usage >&2
        return 2
    fi

    local command="$1"
    shift

    case "$command" in
        system)          cmd_system "$@" ;;
        network)         cmd_network "$@" ;;
        disk)            cmd_disk "$@" ;;
        help|-h|--help)  usage ;;
        *)
            error "unknown command '$command'"
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
exit $?
