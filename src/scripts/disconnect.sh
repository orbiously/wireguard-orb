#!/bin/bash
case "$EXECUTOR" in
  linux)
    disconnect_command=(sudo wg-quick down wg0)
    cleanup_command=(sudo rm -f /etc/wireguard/wg0.conf)
    ;;
  macos)
    disconnect_command=(sudo launchctl stop com.wireguard.wg0)
    cleanup_command=(sudo rm -f /etc/wireguard/wg0.conf)
    ;;
  windows)
    disconnect_command=(/c/progra~1/wireguard/wireguard.exe //uninstalltunnelservice wg0)
    cleanup_command=(rm -f "C:\tmp\wg0.conf")
    ;;
esac

if "${disconnect_command[@]}"; then
  printf "Disconnected from WireGuard server\n"
fi

if "${cleanup_command[@]}"; then
  printf "WireGuard client configuration file deleted\n"
fi