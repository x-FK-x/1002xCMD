#!/bin/bash
# commands/network.sh
# Network helper: ping, netstat, tracert
# Usage (called from xdos main): network_cmds invoked via list.txt aliases (e.g. ping, netstat, tracert)
# First argument is the subcommand (ping/netstat/tracert), rest are forwarded.

LIST_FILE="$(dirname "$0")/../list.txt"
cmd="${1,,}"
shift || true
args=("$@")

is_root() {
  [[ "$(id -u)" -eq 0 ]]
}

run_as_root() {
  if is_root; then
    "$@"
  else
    sudo "$@"
  fi
}

install_package_if_missing() {
  local pkg="$1"
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "Package '$pkg' is not installed."
    read -rp "Install $pkg now? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      run_as_root apt-get update
      run_as_root apt-get install -y "$pkg"
      return $?
    else
      echo "Aborting: required package $pkg not installed."
      return 1
    fi
  fi
  return 0
}

show_help_for_cmd() {
  local c="$1"
  local line
  line=$(awk -F: -v c="$c" '
    {
      split($1,a,"/");
      for (i in a) {
        if (tolower(a[i])==tolower(c)) { print $0; exit }
      }
    }' "$LIST_FILE" 2>/dev/null)
  if [[ -z "$line" ]]; then
    echo "No help available for command '$c'"
    return 1
  fi
  IFS=':' read -r aliases script desc usage <<< "$line"
  echo "Error: Invalid usage."
  echo "$aliases - $desc"
  echo "Usage: $usage"
  return 0
}

case "$cmd" in
  ping)
    if [[ ${#args[@]} -eq 0 ]]; then
      show_help_for_cmd ping
      exit 1
    fi
    # If user supplied pure host, run default 4 pings; if passed options, forward
    # Decide: if first arg looks like a host (no leading -), run ping -c 4 host
    if [[ "${args[0]}" != "-"* && "${args[0]}" != "--"* && ${#args[@]} -eq 1 ]]; then
      ping -c 4 "${args[0]}"
      exit $?
    else
      # forward all args
      ping "${args[@]}"
      exit $?
    fi
    ;;
  netstat)
    # Prefer netstat; fallback to ss
    if command -v netstat &>/dev/null; then
      netstat -tulpn "${args[@]}"
      exit $?
    else
      # netstat not present -> offer to install net-tools
      if install_package_if_missing net-tools; then
        netstat -tulpn "${args[@]}"
        exit $?
      fi
      # fallback to ss if available
      if command -v ss &>/dev/null; then
        ss -tulpn "${args[@]}"
        exit $?
      else
        echo "Neither 'netstat' nor 'ss' available."
        exit 1
      fi
    fi
    ;;
  tracert|traceroute)
    # Use traceroute (package traceroute) or tracepath if not available
    if command -v traceroute &>/dev/null; then
      traceroute "${args[@]}"
      exit $?
    else
      if command -v tracepath &>/dev/null; then
        # tracepath output differs; call it
        tracepath "${args[@]}"
        exit $?
      fi
      # try to install traceroute
      if install_package_if_missing traceroute; then
        traceroute "${args[@]}"
        exit $?
      else
        echo "No traceroute/tracepath available."
        exit 1
      fi
    fi
    ;;
  *)
    echo "Unknown network command: $cmd" >&2
    exit 2
    ;;
esac
