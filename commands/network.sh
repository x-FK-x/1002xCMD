#!/bin/bash
# Network Commands
# Supports: ping, netstat, tracert/traceroute, nslookup

cmd="$1"
shift
args=("$@")

case "$cmd" in
  ping)
    if [[ -z "${args[0]}" ]]; then
      echo "Usage: ping <host>"
      exit 1
    fi
    echo "Pinging ${args[0]} with 4 packets..."
    ping -c 4 "${args[0]}"
    ;;

  netstat)
    echo "Active Internet connections (servers and established)"
    netstat -tunlp 2>/dev/null || ss -tunlp
    ;;

  tracert|traceroute)
    if [[ -z "${args[0]}" ]]; then
      echo "Usage: tracert <host>"
      exit 1
    fi
    if command -v traceroute &>/dev/null; then
      traceroute "${args[0]}"
    elif command -v tracepath &>/dev/null; then
      tracepath "${args[0]}"
    else
      echo "Error: No traceroute or tracepath command found."
    fi
    ;;

  nslookup)
    if [[ -z "${args[0]}" ]]; then
      echo "Usage: nslookup <domain>"
      exit 1
    fi
    if command -v nslookup &>/dev/null; then
      nslookup "${args[0]}"
    elif command -v dig &>/dev/null; then
      dig "${args[0]}"
    else
      echo "Error: nslookup or dig not installed."
    fi
    ;;

  *)
    echo "Unknown network command: $cmd"
    echo "Available: ping, netstat, tracert, nslookup"
    ;;
esac
